#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
script_path="${repo_root}/openclaw/slack_notify.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

judge_path="${tmp_dir}/judge.json"
state_path="${tmp_dir}/slack-notified.keys"
retry_path="${tmp_dir}/slack-retry.jsonl"
mock_bin="${tmp_dir}/bin"
mkdir -p "${mock_bin}"

cat > "${mock_bin}/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

body=""
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--data|--data-raw|--data-binary)
      body="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

count=0
if [ -f "${MOCK_CURL_COUNT_FILE}" ]; then
  count="$(cat "${MOCK_CURL_COUNT_FILE}")"
fi
count=$((count + 1))
printf '%s' "${count}" > "${MOCK_CURL_COUNT_FILE}"
printf '%s\n' "${body}" >> "${MOCK_CURL_BODIES_FILE}"

if [ -n "${MOCK_CURL_FAIL_PATTERN:-}" ] && printf '%s' "${body}" | grep -q "${MOCK_CURL_FAIL_PATTERN}"; then
  exit 22
fi
printf 'ok\n'
EOF
chmod +x "${mock_bin}/curl"

cat > "${judge_path}" <<'EOF'
{"period_start":"2026-02-21T00:00:00Z","period_end":"2026-02-21T01:00:00Z","distance_m":1200.0,"movement_level":"high","event_count":3}
EOF

export PATH="${mock_bin}:${PATH}"
export P6AM_SLACK_WEBHOOK_URL="http://example.invalid/slack"
export P6AM_JUDGE_OUTPUT_PATH="${judge_path}"
export P6AM_NOTIFY_STATE_DB="${state_path}"
export P6AM_NOTIFY_RETRY_QUEUE="${retry_path}"
export MOCK_CURL_COUNT_FILE="${tmp_dir}/curl-count.txt"
export MOCK_CURL_BODIES_FILE="${tmp_dir}/curl-bodies.log"

"${script_path}" >/dev/null
if [ "$(cat "${MOCK_CURL_COUNT_FILE}")" -ne 1 ]; then
  echo "expected one slack call on first run" >&2
  exit 1
fi
if [ "$(wc -l < "${state_path}")" -ne 1 ]; then
  echo "expected one dedupe key after first run" >&2
  exit 1
fi
if [ -f "${retry_path}" ]; then
  echo "retry queue should be empty after successful send" >&2
  exit 1
fi
if ! grep -q 'Activity high' "${MOCK_CURL_BODIES_FILE}"; then
  echo "notification body missing movement level" >&2
  exit 1
fi
if ! grep -q 'distance_m 1200.0' "${MOCK_CURL_BODIES_FILE}"; then
  echo "notification body missing distance" >&2
  exit 1
fi

"${script_path}" >/dev/null
if [ "$(cat "${MOCK_CURL_COUNT_FILE}")" -ne 1 ]; then
  echo "dedupe did not prevent duplicate notification" >&2
  exit 1
fi

cat > "${judge_path}" <<'EOF'
{"period_start":"2026-02-21T01:00:00Z","period_end":"2026-02-21T02:00:00Z","distance_m":200.0,"movement_level":"low","event_count":2}
EOF

export MOCK_CURL_FAIL_PATTERN='2026-02-21T02:00:00Z'
if "${script_path}" >/dev/null; then
  echo "expected notify script to fail on webhook error" >&2
  exit 1
fi
unset MOCK_CURL_FAIL_PATTERN

if [ ! -f "${retry_path}" ]; then
  echo "retry queue should exist after failed notification" >&2
  exit 1
fi
if [ "$(wc -l < "${retry_path}")" -ne 1 ]; then
  echo "expected one failed notification in retry queue" >&2
  exit 1
fi
if [ "$(wc -l < "${state_path}")" -ne 1 ]; then
  echo "failed notification must not be marked as sent" >&2
  exit 1
fi

"${script_path}" >/dev/null
if [ -f "${retry_path}" ]; then
  echo "retry queue should be removed after resend success" >&2
  exit 1
fi
if [ "$(wc -l < "${state_path}")" -ne 2 ]; then
  echo "expected two dedupe keys after resend success" >&2
  exit 1
fi
if [ "$(cat "${MOCK_CURL_COUNT_FILE}")" -ne 3 ]; then
  echo "unexpected number of webhook calls" >&2
  exit 1
fi

echo "slack notify test: PASS"
