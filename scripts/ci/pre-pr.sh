#!/usr/bin/env bash
set -euo pipefail

event="${1:-pull_request}"
job="${2:-docs}"
act_mode="${P6AM_PRE_PR_ACT_MODE:-auto}"
status_file=".local/pre-pr.status"
log_file=".local/pre-pr.log"

mkdir -p .local
: > "${log_file}"

if [ "$act_mode" != "auto" ] && [ "$act_mode" != "required" ] && [ "$act_mode" != "off" ]; then
  echo "invalid P6AM_PRE_PR_ACT_MODE: ${act_mode} (expected: auto|required|off)" >&2
  exit 1
fi

write_status() {
  local result="$1"
  local exit_code="$2"
  local act_result="$3"
  local act_reason="$4"
  local git_head_sha
  git_head_sha="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
  cat > "${status_file}" <<EOF
result=${result}
event=${event}
job=${job}
ran_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
exit_code=${exit_code}
act_result=${act_result}
act_reason=${act_reason}
act_mode=${act_mode}
git_head_sha=${git_head_sha}
EOF
}

skip_act() {
  local reason="$1"
  printf 'act skipped: %s\n' "$reason" | tee -a "${log_file}" >/dev/null
  write_status "PASS" "0" "SKIPPED" "$reason"
  echo "pre-pr: PASS (act skipped: ${reason})"
  exit 0
}

echo "Running docs check"
./scripts/ci/docs-check.sh

echo "Running termux collector test"
./scripts/ci/test-termux-collector.sh

echo "Running termux smoke test"
./scripts/ci/test-termux-smoke.sh

echo "Running ssh collector job test"
./scripts/ci/test-ssh-collector-job.sh

echo "Running sheets append test"
./scripts/ci/test-sheets-append.sh

echo "Running collect sheets job test"
./scripts/ci/test-collect-sheets-job.sh

echo "Running provision data target test"
./scripts/ci/test-provision-data-target.sh

echo "Running openclaw cron register test"
./scripts/ci/test-openclaw-cron-register.sh

echo "Running activity judge test"
./scripts/ci/test-activity-judge.sh

echo "Running ops runtime test"
./scripts/ci/test-ops-runtime.sh

if [ "$act_mode" = "off" ]; then
  skip_act "act_mode_off"
fi

if ! command -v act >/dev/null 2>&1; then
  if [ "$act_mode" = "required" ]; then
    write_status "FAIL" "1" "NOT_RUN" "act_not_installed"
    echo "act is not installed. Install act first." >&2
    exit 1
  fi
  skip_act "act_not_installed"
fi

if ! command -v docker >/dev/null 2>&1; then
  if [ "$act_mode" = "required" ]; then
    write_status "FAIL" "1" "NOT_RUN" "docker_not_installed"
    echo "docker is not installed. act requires docker." >&2
    exit 1
  fi
  skip_act "docker_not_installed"
fi

docker_check_output="$(
  docker version 2>&1 >/dev/null || true
)"
if [ -n "$docker_check_output" ]; then
  if [ "$act_mode" = "required" ]; then
    printf '%s\n' "$docker_check_output" > "${log_file}"
    write_status "FAIL" "1" "NOT_RUN" "docker_unreachable"
    echo "docker is unreachable. act requires docker daemon access." >&2
    exit 1
  fi
  printf '%s\n' "$docker_check_output" > "${log_file}"
  skip_act "docker_unreachable"
fi

echo "Running local CI via act (event=${event}, job=${job})"
if act "${event}" -j "${job}" 2>&1 | tee "${log_file}"; then
  write_status "PASS" "0" "PASS" "none"
  echo "pre-pr: PASS"
else
  exit_code=$?
  if [ "$act_mode" = "auto" ] && grep -Eiq 'permission denied while trying to connect to the docker API|cannot connect to the docker daemon|dial unix .*/docker\.sock.*permission denied|listen tcp :0: socket: operation not permitted' "${log_file}"; then
    skip_act "docker_permission_denied"
  fi
  write_status "FAIL" "${exit_code}" "FAIL" "act_failed"
  echo "pre-pr: FAIL (exit=${exit_code})"
  exit "$exit_code"
fi
