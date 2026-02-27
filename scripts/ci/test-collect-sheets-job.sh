#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
job_script="${repo_root}/openclaw/collect_sheets_job.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

mock_bin="${tmp_dir}/bin"
mkdir -p "${mock_bin}"

cat > "${mock_bin}/collect-ok" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count_file="${MOCK_COLLECT_COUNT_FILE:?}"
count=0
if [ -f "${count_file}" ]; then
  count="$(cat "${count_file}")"
fi
count=$((count + 1))
printf '%s' "${count}" > "${count_file}"
if [ "${MOCK_COLLECT_ALWAYS_FAIL:-0}" = "1" ]; then
  echo "mock collect failed always" >&2
  exit 1
fi
echo "mock collect ok"
EOF
chmod +x "${mock_bin}/collect-ok"

cat > "${mock_bin}/append-ok" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count_file="${MOCK_APPEND_COUNT_FILE:?}"
count=0
if [ -f "${count_file}" ]; then
  count="$(cat "${count_file}")"
fi
count=$((count + 1))
printf '%s' "${count}" > "${count_file}"
if [ "${MOCK_APPEND_ALWAYS_FAIL:-0}" = "1" ]; then
  echo "mock append failed always" >&2
  exit 1
fi
if [ "${MOCK_APPEND_FAIL_ONCE:-0}" = "1" ] && [ "${count}" -eq 1 ]; then
  echo "mock append failed once" >&2
  exit 1
fi
echo "mock append ok"
EOF
chmod +x "${mock_bin}/append-ok"

log_dir="${tmp_dir}/logs"
lock_dir="${tmp_dir}/locks"
collect_count_file="${tmp_dir}/collect-count.txt"
append_count_file="${tmp_dir}/append-count.txt"

export P6AM_LOG_DIR="${log_dir}"
export P6AM_LOCK_DIR="${lock_dir}"
export P6AM_COLLECT_CMD="${mock_bin}/collect-ok"
export P6AM_SHEETS_APPEND_CMD="${mock_bin}/append-ok"
export P6AM_JOB_MAX_RETRIES="2"
export P6AM_JOB_RETRY_SLEEP_SEC="0"
export MOCK_COLLECT_COUNT_FILE="${collect_count_file}"
export MOCK_APPEND_COUNT_FILE="${append_count_file}"

"${job_script}" >/dev/null
today_log="${log_dir}/collect-sheets-$(date -u +%Y%m%d).log"
if [ ! -f "${today_log}" ]; then
  echo "job log file was not created" >&2
  exit 1
fi
if ! grep -q '"result":"success"' "${today_log}"; then
  echo "success log not found" >&2
  exit 1
fi
if ! grep -q '"tailnet_ok":true' "${today_log}"; then
  echo "tailnet status log field is missing for success case" >&2
  exit 1
fi
if [ "$(cat "${collect_count_file}")" -ne 1 ]; then
  echo "collect step should run once on first success" >&2
  exit 1
fi
if [ "$(cat "${append_count_file}")" -ne 1 ]; then
  echo "append step should run once on first success" >&2
  exit 1
fi

rm -f "${collect_count_file}" "${append_count_file}"
export MOCK_APPEND_FAIL_ONCE="1"
"${job_script}" >/dev/null
unset MOCK_APPEND_FAIL_ONCE
if [ "$(cat "${collect_count_file}")" -ne 2 ]; then
  echo "collect step should rerun for retry cycle" >&2
  exit 1
fi
if [ "$(cat "${append_count_file}")" -ne 2 ]; then
  echo "append step should rerun for retry cycle" >&2
  exit 1
fi
if ! grep -q '"result":"retrying"' "${today_log}"; then
  echo "retry log not found" >&2
  exit 1
fi
if ! grep -q '"error_code":"sheets_append_failed"' "${today_log}"; then
  echo "retry should capture sheets append failure" >&2
  exit 1
fi
if ! grep -q '"failed_step":"sheets_append"' "${today_log}"; then
  echo "retry should capture failed step" >&2
  exit 1
fi
if ! grep -q 'mock append failed once' "${today_log}"; then
  echo "retry detail should include append failure reason" >&2
  exit 1
fi

rm -f "${collect_count_file}" "${append_count_file}"
export MOCK_COLLECT_ALWAYS_FAIL="1"
if "${job_script}" >/dev/null 2>&1; then
  echo "job should fail when collect step keeps failing" >&2
  exit 1
fi
unset MOCK_COLLECT_ALWAYS_FAIL
if [ "$(cat "${collect_count_file}")" -ne 2 ]; then
  echo "collect retries should follow max retry count" >&2
  exit 1
fi
if [ -f "${append_count_file}" ]; then
  echo "append should not run when collect fails" >&2
  exit 1
fi
if ! grep -q '"error_code":"max_retries_exceeded"' "${today_log}"; then
  echo "max retries error log not found" >&2
  exit 1
fi
if ! grep -q '"failed_step":"collect"' "${today_log}"; then
  echo "final error should indicate collect failure step" >&2
  exit 1
fi

mkdir -p "${lock_dir}/collect-sheets.lock"
if "${job_script}" >/dev/null 2>&1; then
  echo "job should fail when lock already exists" >&2
  exit 1
fi
if [ ! -d "${lock_dir}/collect-sheets.lock" ]; then
  echo "lock directory should not be removed by non-owner process" >&2
  exit 1
fi
rmdir "${lock_dir}/collect-sheets.lock"
if ! grep -q '"event":"lock_busy"' "${today_log}"; then
  echo "lock busy log not found" >&2
  exit 1
fi

echo "collect sheets job test: PASS"
