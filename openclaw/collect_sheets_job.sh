#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
job_name="${1:-collect-sheets}"
max_retries="${P6AM_JOB_MAX_RETRIES:-3}"
retry_sleep_sec="${P6AM_JOB_RETRY_SLEEP_SEC:-2}"
log_dir="${P6AM_LOG_DIR:-tmp/logs}"
lock_dir="${P6AM_LOCK_DIR:-tmp/locks}"

collect_cmd="${P6AM_COLLECT_CMD:-${repo_root}/openclaw/ssh_collect_job.sh}"
sheets_append_cmd="${P6AM_SHEETS_APPEND_CMD:-${repo_root}/openclaw/sheets_append.sh}"

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

run_with_capture() {
  local step="$1"
  local cmd="$2"
  local output_file
  local exit_code
  output_file="$(mktemp)"
  if "$cmd" >"$output_file" 2>&1; then
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

if ! command -v "$collect_cmd" >/dev/null 2>&1; then
  write_log "error" "config_check" "failed" "collect_command_not_found" 0 "false" "config" "${collect_cmd} command not found"
  echo "collect command not found: ${collect_cmd}" >&2
  exit 1
fi

if ! command -v "$sheets_append_cmd" >/dev/null 2>&1; then
  write_log "error" "config_check" "failed" "sheets_append_command_not_found" 0 "false" "config" "${sheets_append_cmd} command not found"
  echo "sheets append command not found: ${sheets_append_cmd}" >&2
  exit 1
fi

attempt=1
last_run_error_code="none"
last_failed_step="none"
last_error_detail=""
tailnet_ok="false"
while [ "$attempt" -le "$max_retries" ]; do
  if ! run_with_capture "collect" "$collect_cmd"; then
    last_run_error_code="collect_failed"
    tailnet_ok="false"
  else
    tailnet_ok="true"
    if ! run_with_capture "sheets_append" "$sheets_append_cmd"; then
      last_run_error_code="sheets_append_failed"
    else
      write_log "info" "collect_sheets" "success" "none" $((attempt - 1)) "$tailnet_ok" "none" "collector and sheets append completed"
      echo "collect-sheets job success: attempt=${attempt}"
      exit 0
    fi
  fi

  if [ "$attempt" -lt "$max_retries" ]; then
    write_log "warn" "collect_sheets" "retrying" "$last_run_error_code" "$attempt" "$tailnet_ok" "${last_failed_step}" "${last_error_detail}"
    sleep "$retry_sleep_sec"
  fi
  attempt=$((attempt + 1))
done

write_log "error" "collect_sheets" "failed" "max_retries_exceeded" "$max_retries" "$tailnet_ok" "${last_failed_step}" "${last_error_detail}"
echo "collect-sheets job failed after retries=${max_retries}" >&2
exit 1
