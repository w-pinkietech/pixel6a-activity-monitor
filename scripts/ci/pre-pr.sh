#!/usr/bin/env bash
set -euo pipefail

if ! command -v act >/dev/null 2>&1; then
  echo "act is not installed. Install act first."
  exit 1
fi

event="${1:-pull_request}"
job="${2:-docs}"
status_file=".local/pre-pr.status"
log_file=".local/pre-pr.log"

mkdir -p .local

echo "Running docs check"
./scripts/ci/docs-check.sh

echo "Running local CI via act (event=${event}, job=${job})"
if act "${event}" -j "${job}" 2>&1 | tee "${log_file}"; then
  cat > "${status_file}" <<EOF
result=PASS
event=${event}
job=${job}
ran_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
exit_code=0
EOF
  echo "pre-pr: PASS"
else
  exit_code=$?
  cat > "${status_file}" <<EOF
result=FAIL
event=${event}
job=${job}
ran_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
exit_code=${exit_code}
EOF
  echo "pre-pr: FAIL (exit=${exit_code})"
  exit "${exit_code}"
fi
