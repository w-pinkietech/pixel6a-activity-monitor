#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
job_name="${1:-ssh-collector}"
max_retries="${P6AM_JOB_MAX_RETRIES:-3}"
retry_sleep_sec="${P6AM_JOB_RETRY_SLEEP_SEC:-2}"
log_dir="${P6AM_LOG_DIR:-tmp/logs}"
lock_dir="${P6AM_LOCK_DIR:-tmp/locks}"

tailnet_check_cmd="${P6AM_TAILNET_CHECK_CMD:-${repo_root}/openclaw/tailnet_precheck.sh}"
ssh_bin="${P6AM_SSH_BIN:-ssh}"
timeout_bin="${P6AM_TIMEOUT_BIN:-timeout}"

termux_host="${P6AM_TERMUX_SSH_HOST:-}"
termux_user="${P6AM_TERMUX_SSH_USER:-}"
termux_port="${P6AM_TERMUX_SSH_PORT:-8022}"
ssh_connect_timeout_sec="${P6AM_SSH_CONNECT_TIMEOUT_SEC:-10}"
collect_timeout_sec="${P6AM_COLLECT_TIMEOUT_SEC:-45}"
location_request="${P6AM_LOCATION_REQUEST:-last}"
remote_collector_cmd="${P6AM_TERMUX_COLLECTOR_CMD:-cd ~/pixel6a-activity-monitor && ./termux/collect_location.sh}"
tailnet_target="${P6AM_TERMUX_TAILNET_TARGET:-${P6AM_TAILNET_TARGET:-}}"
sync_local_data="${P6AM_SYNC_LOCAL_DATA:-1}"
local_data_path="${P6AM_LOCAL_DATA_PATH:-${repo_root}/data/location.jsonl}"
termux_data_path="${P6AM_TERMUX_DATA_PATH:-~/pixel6a-activity-monitor/data/location.jsonl}"
sync_timeout_sec="${P6AM_SYNC_TIMEOUT_SEC:-15}"

mkdir -p "$log_dir" "$lock_dir"
log_file="${log_dir}/${job_name}-$(date -u +%Y%m%d).log"
lock_path="${lock_dir}/${job_name}.lock"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_log() {
  local level="$1"
  local event="$2"
  local result="$3"
  local error_code="$4"
  local retry_count="$5"
  local tailnet_ok="$6"
  local failed_step="$7"
  local detail="$8"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","level":"%s","job":"%s","event":"%s","result":"%s","error_code":"%s","retry_count":%s,"tailnet_ok":%s,"failed_step":"%s","detail":"%s"}\n' \
    "$ts" "$level" "$job_name" "$(json_escape "$event")" "$result" "$error_code" "$retry_count" "$tailnet_ok" "$(json_escape "$failed_step")" "$(json_escape "$detail")" \
    >> "$log_file"
}

normalize_detail() {
  local detail="$1"
  detail="$(printf '%s' "$detail" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
  printf '%s' "$detail" | cut -c1-300
}

extract_string_field() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true
}

run_with_capture() {
  local step="$1"
  shift
  local output_file
  local exit_code
  output_file="$(mktemp)"
  if "$@" >"$output_file" 2>&1; then
    last_failed_step=""
    last_error_detail=""
    rm -f "$output_file"
    return 0
  else
    exit_code=$?
  fi
  last_failed_step="$step"
  last_error_detail="$(normalize_detail "$(tail -n 20 "$output_file" 2>/dev/null || true)")"
  rm -f "$output_file"
  return "$exit_code"
}

sync_latest_record() {
  local output_file
  local exit_code
  local remote_record
  local timestamp
  local device_id

  output_file="$(mktemp)"
  if ! "$timeout_bin" "${sync_timeout_sec}s" \
    "$ssh_bin" \
    -p "$termux_port" \
    -o BatchMode=yes \
    -o "ConnectTimeout=${ssh_connect_timeout_sec}" \
    "$ssh_target" \
    "tail -n 1 ${termux_data_path}" >"$output_file" 2>&1; then
    exit_code=$?
    last_failed_step="sync_local_data"
    if [ "$exit_code" -eq 124 ]; then
      last_error_detail="sync timed out after ${sync_timeout_sec}s"
    else
      last_error_detail="$(normalize_detail "$(tail -n 20 "$output_file" 2>/dev/null || true)")"
    fi
    rm -f "$output_file"
    return "$exit_code"
  fi

  remote_record="$(tail -n 1 "$output_file" | tr -d '\r')"
  rm -f "$output_file"
  if [ -z "$remote_record" ]; then
    last_failed_step="sync_local_data"
    last_error_detail="remote data file is empty: ${termux_data_path}"
    return 1
  fi

  timestamp="$(extract_string_field "$remote_record" "timestamp_utc")"
  device_id="$(extract_string_field "$remote_record" "device_id")"
  if [ -z "$timestamp" ] || [ -z "$device_id" ]; then
    last_failed_step="sync_local_data"
    last_error_detail="invalid synced record: missing timestamp_utc or device_id"
    return 1
  fi

  mkdir -p "$(dirname "$local_data_path")"
  touch "$local_data_path"
  if ! grep -Fxq "$remote_record" "$local_data_path"; then
    printf '%s\n' "$remote_record" >> "$local_data_path"
  fi

  last_failed_step=""
  last_error_detail=""
  return 0
}

cleanup_lock() {
  if [ "${owns_lock}" = "true" ]; then
    rmdir "$lock_path" >/dev/null 2>&1 || true
  fi
}
trap cleanup_lock EXIT
owns_lock="false"

if ! mkdir "$lock_path" >/dev/null 2>&1; then
  write_log "warn" "lock_busy" "failed" "lock_busy" 0 "false" "lock" "lock directory already exists"
  echo "lock exists: ${lock_path}" >&2
  exit 1
fi
owns_lock="true"

if [ -z "$termux_host" ]; then
  write_log "error" "config_check" "failed" "missing_termux_host" 0 "false" "config" "set P6AM_TERMUX_SSH_HOST"
  echo "P6AM_TERMUX_SSH_HOST is required" >&2
  exit 1
fi

if ! command -v "$ssh_bin" >/dev/null 2>&1; then
  write_log "error" "config_check" "failed" "ssh_command_not_found" 0 "false" "config" "${ssh_bin} command not found"
  echo "ssh command not found: ${ssh_bin}" >&2
  exit 1
fi

if ! command -v "$timeout_bin" >/dev/null 2>&1; then
  write_log "error" "config_check" "failed" "timeout_command_not_found" 0 "false" "config" "${timeout_bin} command not found"
  echo "timeout command not found: ${timeout_bin}" >&2
  exit 1
fi

case "$sync_local_data" in
  1|true|yes|on)
    sync_local_data="1"
    ;;
  0|false|no|off)
    sync_local_data="0"
    ;;
  *)
    write_log "error" "config_check" "failed" "invalid_sync_local_data" 0 "false" "config" "P6AM_SYNC_LOCAL_DATA must be 0/1/true/false"
    echo "invalid P6AM_SYNC_LOCAL_DATA: ${sync_local_data}" >&2
    exit 1
    ;;
esac

if [ -z "$tailnet_target" ]; then
  tailnet_target="$termux_host"
fi
export P6AM_TAILNET_TARGET="$tailnet_target"

if ! run_with_capture "tailnet_precheck" "$tailnet_check_cmd"; then
  write_log "warn" "tailnet_precheck" "failed" "tailnet_unreachable" 0 "false" "${last_failed_step:-tailnet_precheck}" "${last_error_detail}"
  echo "tailnet precheck failed" >&2
  exit 1
fi

ssh_target="$termux_host"
if [ -n "$termux_user" ]; then
  ssh_target="${termux_user}@${termux_host}"
fi
remote_cmd="export P6AM_LOCATION_REQUEST=${location_request}; ${remote_collector_cmd}"

attempt=1
last_run_error_code="none"
last_failed_step="none"
last_error_detail=""
while [ "$attempt" -le "$max_retries" ]; do
  if run_with_capture "collect" "$timeout_bin" "${collect_timeout_sec}s" \
    "$ssh_bin" \
    -p "$termux_port" \
    -o BatchMode=yes \
    -o "ConnectTimeout=${ssh_connect_timeout_sec}" \
    "$ssh_target" \
    "$remote_cmd"; then
    if [ "$sync_local_data" = "1" ] && ! sync_latest_record; then
      if [ "${last_failed_step}" = "sync_local_data" ] && [ -n "${last_error_detail}" ]; then
        :
      else
        last_failed_step="sync_local_data"
        last_error_detail="local sync failed"
      fi
      last_run_error_code="local_sync_failed"
    else
      write_log "info" "ssh_collect" "success" "none" $((attempt - 1)) "true" "none" "host=${termux_host} request=${location_request} synced_local_data=${sync_local_data}"
      echo "ssh-collector job success: attempt=${attempt}"
      exit 0
    fi
  else
    collect_exit_code=$?
    if [ "$collect_exit_code" -eq 124 ]; then
      last_run_error_code="collect_timeout"
      if [ -z "${last_error_detail}" ]; then
        last_error_detail="collector timed out after ${collect_timeout_sec}s"
      fi
    else
      last_run_error_code="ssh_collect_failed"
      if [ -z "${last_error_detail}" ]; then
        last_error_detail="ssh collector command failed with exit=${collect_exit_code}"
      fi
    fi
  fi

  if [ "$attempt" -lt "$max_retries" ]; then
    write_log "warn" "ssh_collect" "retrying" "$last_run_error_code" "$attempt" "true" "${last_failed_step}" "${last_error_detail}"
    sleep "$retry_sleep_sec"
  fi
  attempt=$((attempt + 1))
done

write_log "error" "ssh_collect" "failed" "max_retries_exceeded" "$max_retries" "true" "${last_failed_step}" "${last_error_detail}"
echo "ssh-collector job failed after retries=${max_retries}" >&2
exit 1
