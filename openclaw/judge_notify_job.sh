#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
job_name="${1:-judge-notify}"
max_retries="${P6AM_JOB_MAX_RETRIES:-3}"
retry_sleep_sec="${P6AM_JOB_RETRY_SLEEP_SEC:-2}"
log_dir="${P6AM_LOG_DIR:-tmp/logs}"
lock_dir="${P6AM_LOCK_DIR:-tmp/locks}"

tailnet_check_cmd="${P6AM_TAILNET_CHECK_CMD:-${repo_root}/openclaw/tailnet_precheck.sh}"
judge_cmd="${P6AM_JUDGE_CMD:-${repo_root}/openclaw/activity_judge.sh}"
notify_cmd="${P6AM_NOTIFY_CMD:-}"

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
  rmdir "$lock_path" >/dev/null 2>&1 || true
}
trap cleanup_lock EXIT

if ! mkdir "$lock_path" >/dev/null 2>&1; then
  write_log "warn" "lock_busy" "failed" "lock_busy" 0 "false" "lock" "lock directory already exists"
  echo "lock exists: ${lock_path}" >&2
  exit 1
fi

if ! run_with_capture "tailnet_precheck" "$tailnet_check_cmd"; then
  write_log "warn" "tailnet_precheck" "failed" "tailnet_unreachable" 0 "false" "${last_failed_step:-tailnet_precheck}" "${last_error_detail}"
  echo "tailnet precheck failed" >&2
  exit 1
fi

attempt=1
last_run_error_code="none"
last_failed_step="none"
last_error_detail=""
while [ "$attempt" -le "$max_retries" ]; do
  if ! run_with_capture "judge" "$judge_cmd"; then
    last_run_error_code="judge_failed"
  elif [ -n "$notify_cmd" ] && ! run_with_capture "notify" "$notify_cmd"; then
    last_run_error_code="notify_failed"
  else
    if [ -z "$notify_cmd" ]; then
      write_log "info" "judge_notify" "success" "notify_managed_by_openclaw" $((attempt - 1)) "true" "none" "notification delivery is managed by OpenClaw side"
    else
      write_log "info" "judge_notify" "success" "none" $((attempt - 1)) "true" "none" ""
    fi
    echo "judge-notify job success: attempt=${attempt}"
    exit 0
  fi

  if [ "$attempt" -lt "$max_retries" ]; then
    write_log "warn" "judge_notify" "retrying" "$last_run_error_code" "$attempt" "true" "${last_failed_step}" "${last_error_detail}"
    sleep "$retry_sleep_sec"
  fi
  attempt=$((attempt + 1))
done

write_log "error" "judge_notify" "failed" "max_retries_exceeded" "$max_retries" "true" "${last_failed_step}" "${last_error_detail}"
echo "judge-notify job failed after retries=${max_retries}" >&2
exit 1
