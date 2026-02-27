#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
job_script="${repo_root}/openclaw/ssh_collect_job.sh"

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

cat > "${mock_bin}/timeout" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
shift
if [ "${MOCK_TIMEOUT_FORCE:-0}" = "1" ]; then
  exit 124
fi
"$@"
EOF
chmod +x "${mock_bin}/timeout"

cat > "${mock_bin}/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log_file="${MOCK_SSH_LOG_FILE:?}"
count_file="${MOCK_SSH_COUNT_FILE:?}"
count=0
if [ -f "${count_file}" ]; then
  count="$(cat "${count_file}")"
fi
count=$((count + 1))
printf '%s' "${count}" > "${count_file}"
printf '%s\n' "$*" >> "${log_file}"

if [ "${MOCK_SSH_ALWAYS_FAIL:-0}" = "1" ]; then
  echo "mock ssh failed always" >&2
  exit 255
fi
if [ "${MOCK_SSH_FAIL_ONCE:-0}" = "1" ] && [ "${count}" -eq 1 ]; then
  echo "mock ssh failed once" >&2
  exit 255
fi

echo "remote collector ok"
EOF
chmod +x "${mock_bin}/ssh"

log_dir="${tmp_dir}/logs"
lock_dir="${tmp_dir}/locks"
ssh_args_log="${tmp_dir}/ssh-args.log"
ssh_count_file="${tmp_dir}/ssh-count.txt"

export PATH="${mock_bin}:${PATH}"
export P6AM_LOG_DIR="${log_dir}"
export P6AM_LOCK_DIR="${lock_dir}"
export P6AM_TAILNET_CHECK_CMD="${repo_root}/openclaw/tailnet_precheck.sh"
export P6AM_TERMUX_SSH_HOST="pixel6a"
export P6AM_TERMUX_SSH_USER="u0_a569"
export P6AM_TERMUX_SSH_PORT="8022"
export P6AM_TERMUX_COLLECTOR_CMD="~/pixel6a-activity-monitor/termux/collect_location.sh"
export P6AM_LOCATION_REQUEST="last"
export P6AM_SSH_BIN="ssh"
export P6AM_TIMEOUT_BIN="timeout"
export P6AM_JOB_MAX_RETRIES="2"
export P6AM_JOB_RETRY_SLEEP_SEC="0"
export MOCK_SSH_LOG_FILE="${ssh_args_log}"
export MOCK_SSH_COUNT_FILE="${ssh_count_file}"

"${job_script}" >/dev/null
today_log="${log_dir}/ssh-collector-$(date -u +%Y%m%d).log"
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
if ! grep -q 'P6AM_LOCATION_REQUEST=last' "${ssh_args_log}"; then
  echo "ssh command should include P6AM_LOCATION_REQUEST=last" >&2
  exit 1
fi

rm -f "${ssh_count_file}"
export MOCK_SSH_FAIL_ONCE="1"
"${job_script}" >/dev/null
unset MOCK_SSH_FAIL_ONCE
if ! grep -q '"result":"retrying"' "${today_log}"; then
  echo "retry log not found" >&2
  exit 1
fi
if ! grep -q '"failed_step":"collect"' "${today_log}"; then
  echo "retry log should indicate collect step failure" >&2
  exit 1
fi
if ! grep -q 'mock ssh failed once' "${today_log}"; then
  echo "retry log should include ssh failure detail" >&2
  exit 1
fi

export MOCK_TIMEOUT_FORCE="1"
if "${job_script}" >/dev/null 2>&1; then
  echo "job should fail when timeout is exceeded" >&2
  exit 1
fi
unset MOCK_TIMEOUT_FORCE
if ! grep -q '"error_code":"max_retries_exceeded"' "${today_log}"; then
  echo "max retries error log not found for timeout case" >&2
  exit 1
fi
if ! grep -q 'collector timed out after' "${today_log}"; then
  echo "timeout failure detail should include timeout message" >&2
  exit 1
fi

mkdir -p "${lock_dir}/ssh-collector.lock"
if "${job_script}" >/dev/null 2>&1; then
  echo "job should fail when lock already exists" >&2
  exit 1
fi
if [ ! -d "${lock_dir}/ssh-collector.lock" ]; then
  echo "lock directory should not be removed by non-owner process" >&2
  exit 1
fi
rmdir "${lock_dir}/ssh-collector.lock"
if ! grep -q '"event":"lock_busy"' "${today_log}"; then
  echo "lock busy log not found" >&2
  exit 1
fi

export MOCK_TAILSCALE_PING_FAIL="1"
if "${job_script}" >/dev/null 2>&1; then
  echo "job should fail when tailnet check fails" >&2
  exit 1
fi
unset MOCK_TAILSCALE_PING_FAIL
if ! grep -q '"event":"tailnet_precheck"' "${today_log}"; then
  echo "tailnet precheck failure log not found" >&2
  exit 1
fi
if ! grep -q 'tailscale ping failed' "${today_log}"; then
  echo "tailnet failure detail should include ping error" >&2
  exit 1
fi

echo "ssh collector job test: PASS"
