#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
script_path="${repo_root}/openclaw/sheets_append.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

data_path="${tmp_dir}/location.jsonl"
dedupe_path="${tmp_dir}/sheets-dedupe.keys"
retry_path="${tmp_dir}/sheets-retry.jsonl"
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
printf '{"ok":true}\n'
EOF
chmod +x "${mock_bin}/curl"

cat > "${data_path}" <<'EOF'
{"timestamp_utc":"2026-02-21T00:00:00Z","lat":35.0,"lng":139.0,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
{"timestamp_utc":"2026-02-21T00:01:00Z","lat":35.1,"lng":139.1,"accuracy_m":11.0,"source":"termux","device_id":"pixel6a"}
EOF

export PATH="${mock_bin}:${PATH}"
export P6AM_SHEETS_APPEND_URL="http://example.invalid/append"
export P6AM_SHEETS_ID="sheet-id"
export P6AM_SHEETS_TAB="raw"
export P6AM_DATA_PATH="${data_path}"
export P6AM_SHEETS_DEDUPE_DB="${dedupe_path}"
export P6AM_SHEETS_RETRY_QUEUE="${retry_path}"
export MOCK_CURL_COUNT_FILE="${tmp_dir}/curl-count.txt"
export MOCK_CURL_BODIES_FILE="${tmp_dir}/curl-bodies.log"

"${script_path}" >/dev/null

if [ ! -f "${dedupe_path}" ]; then
  echo "dedupe file not created" >&2
  exit 1
fi
if [ "$(wc -l < "${dedupe_path}")" -ne 2 ]; then
  echo "expected 2 dedupe keys after first run" >&2
  exit 1
fi
if [ "$(cat "${MOCK_CURL_COUNT_FILE}")" -ne 2 ]; then
  echo "expected 2 curl calls after first run" >&2
  exit 1
fi
if [ -f "${retry_path}" ]; then
  echo "retry queue should be empty after successful run" >&2
  exit 1
fi

"${script_path}" >/dev/null
if [ "$(cat "${MOCK_CURL_COUNT_FILE}")" -ne 2 ]; then
  echo "dedupe did not skip duplicate records" >&2
  exit 1
fi

cat >> "${data_path}" <<'EOF'
{"timestamp_utc":"2026-02-21T00:02:00Z","lat":35.2,"lng":139.2,"accuracy_m":12.0,"source":"termux","device_id":"pixel6a"}
EOF

export MOCK_CURL_FAIL_PATTERN='2026-02-21T00:02:00Z'
if "${script_path}" >/dev/null; then
  echo "expected script to fail when append fails" >&2
  exit 1
fi
unset MOCK_CURL_FAIL_PATTERN

if [ ! -f "${retry_path}" ]; then
  echo "retry queue should exist after failed append" >&2
  exit 1
fi
if [ "$(wc -l < "${retry_path}")" -ne 1 ]; then
  echo "expected one failed record in retry queue" >&2
  exit 1
fi
if [ "$(wc -l < "${dedupe_path}")" -ne 2 ]; then
  echo "failed record must not be marked as sent" >&2
  exit 1
fi

"${script_path}" >/dev/null
if [ "$(wc -l < "${dedupe_path}")" -ne 3 ]; then
  echo "retry success should add third dedupe key" >&2
  exit 1
fi
if [ -f "${retry_path}" ]; then
  echo "retry queue should be removed after successful resend" >&2
  exit 1
fi
if [ "$(cat "${MOCK_CURL_COUNT_FILE}")" -ne 4 ]; then
  echo "unexpected number of curl calls" >&2
  exit 1
fi

echo "sheets append test: PASS"
