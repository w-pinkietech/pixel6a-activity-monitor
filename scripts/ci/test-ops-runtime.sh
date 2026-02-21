#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
job_script="${repo_root}/openclaw/judge_notify_job.sh"
rotate_script="${repo_root}/openclaw/log_rotate.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

mock_bin="${tmp_dir}/bin"
mkdir -p "${mock_bin}"

cat > "${mock_bin}/tailscale" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
subcmd="${1:-}"
case "$subcmd" in
  status)
    [ "${MOCK_TAILSCALE_STATUS_FAIL:-0}" = "1" ] && exit 1
    echo "ok"
    ;;
  ping)
    [ "${MOCK_TAILSCALE_PING_FAIL:-0}" = "1" ] && exit 1
    echo "pong"
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "${mock_bin}/tailscale"

cat > "${mock_bin}/mock-judge" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo '{"period_start":"2026-02-21T00:00:00Z","period_end":"2026-02-21T01:00:00Z","distance_m":1000,"movement_level":"high","event_count":3}' > "${MOCK_JUDGE_OUTPUT_PATH}"
EOF
chmod +x "${mock_bin}/mock-judge"

cat > "${mock_bin}/mock-notify" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count=0
if [ -f "${MOCK_NOTIFY_COUNT_FILE}" ]; then
  count="$(cat "${MOCK_NOTIFY_COUNT_FILE}")"
fi
count=$((count + 1))
printf '%s' "${count}" > "${MOCK_NOTIFY_COUNT_FILE}"
if [ "${MOCK_NOTIFY_FAIL_ONCE:-0}" = "1" ] && [ "${count}" -eq 1 ]; then
  exit 1
fi
exit 0
EOF
chmod +x "${mock_bin}/mock-notify"

log_dir="${tmp_dir}/logs"
lock_dir="${tmp_dir}/locks"
judge_out="${tmp_dir}/judge.json"
notify_count="${tmp_dir}/notify-count.txt"

export PATH="${mock_bin}:${PATH}"
export P6AM_TAILNET_TARGET="pixel6a"
export P6AM_LOG_DIR="${log_dir}"
export P6AM_LOCK_DIR="${lock_dir}"
export P6AM_TAILNET_CHECK_CMD="${repo_root}/openclaw/tailnet_precheck.sh"
export P6AM_JUDGE_CMD="${mock_bin}/mock-judge"
export P6AM_NOTIFY_CMD="${mock_bin}/mock-notify"
export P6AM_JOB_MAX_RETRIES="2"
export P6AM_JOB_RETRY_SLEEP_SEC="0"
export MOCK_JUDGE_OUTPUT_PATH="${judge_out}"
export MOCK_NOTIFY_COUNT_FILE="${notify_count}"

"${job_script}" >/dev/null
today_log="${log_dir}/judge-notify-$(date -u +%Y%m%d).log"
if [ ! -f "${today_log}" ]; then
  echo "job log file was not created" >&2
  exit 1
fi
if ! grep -q '"result":"success"' "${today_log}"; then
  echo "success log not found" >&2
  exit 1
fi
if ! grep -q '"tailnet_ok":true' "${today_log}"; then
  echo "tailnet status log field is missing" >&2
  exit 1
fi

rm -f "${notify_count}"
export MOCK_NOTIFY_FAIL_ONCE="1"
"${job_script}" >/dev/null
unset MOCK_NOTIFY_FAIL_ONCE
if ! grep -q '"result":"retrying"' "${today_log}"; then
  echo "retry log not found" >&2
  exit 1
fi

export MOCK_TAILSCALE_PING_FAIL="1"
if "${job_script}" >/dev/null 2>&1; then
  echo "job should fail when tailnet check fails" >&2
  exit 1
fi
unset MOCK_TAILSCALE_PING_FAIL
if ! grep -q '"event":"tailnet_precheck"' "${today_log}"; then
  echo "tailnet failure log not found" >&2
  exit 1
fi

old_log="${log_dir}/old.log"
recent_log="${log_dir}/recent.log"
touch -d '10 days ago' "${old_log}"
touch "${recent_log}"
P6AM_LOG_RETENTION_DAYS="7" "${rotate_script}" >/dev/null
if [ -f "${old_log}" ]; then
  echo "old log should have been deleted" >&2
  exit 1
fi
if [ ! -f "${recent_log}" ]; then
  echo "recent log should be kept" >&2
  exit 1
fi

echo "ops runtime test: PASS"
