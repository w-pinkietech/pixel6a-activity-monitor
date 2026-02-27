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

cat > "${mock_bin}/gog" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" != "sheets" ] || [ "${2:-}" != "append" ]; then
  echo "unexpected gog command: $*" >&2
  exit 2
fi
sheet_id="${3:-}"
sheet_range="${4:-}"
shift 4

values_json=""
insert_mode=""
while [ $# -gt 0 ]; do
  case "$1" in
    --values-json)
      values_json="${2:-}"
      shift 2
      ;;
    --insert)
      insert_mode="${2:-}"
      shift 2
      ;;
    --no-input)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

count=0
if [ -f "${MOCK_GOG_COUNT_FILE}" ]; then
  count="$(cat "${MOCK_GOG_COUNT_FILE}")"
fi
count=$((count + 1))
printf '%s' "${count}" > "${MOCK_GOG_COUNT_FILE}"
printf '%s\t%s\t%s\t%s\n' "${sheet_id}" "${sheet_range}" "${insert_mode}" "${values_json}" >> "${MOCK_GOG_CALLS_FILE}"

if [ -n "${MOCK_GOG_FAIL_PATTERN:-}" ] && printf '%s' "${values_json}" | grep -q "${MOCK_GOG_FAIL_PATTERN}"; then
  exit 1
fi
printf '{"updates":{"updatedRows":1}}\n'
EOF
chmod +x "${mock_bin}/gog"

cat > "${data_path}" <<'EOF'
{"timestamp_utc":"2026-02-21T00:00:00Z","lat":35.0,"lng":139.0,"altitude_m":45.2,"accuracy_m":10.0,"vertical_accuracy_m":12.3,"bearing_deg":180.5,"speed_mps":0.8,"elapsed_ms":2450,"provider":"gps","source":"termux","device_id":"pixel6a"}
{"timestamp_utc":"2026-02-21T00:01:00Z","lat":35.1,"lng":139.1,"altitude_m":46.0,"accuracy_m":11.0,"vertical_accuracy_m":13.0,"bearing_deg":181.0,"speed_mps":0.9,"elapsed_ms":2460,"provider":"gps","source":"termux","device_id":"pixel6a"}
EOF

export PATH="${mock_bin}:${PATH}"
export P6AM_GOG_BIN="gog"
export P6AM_SHEETS_ID="sheet-id"
export P6AM_SHEETS_TAB="raw"
export P6AM_SHEETS_RANGE="raw!A:M"
export P6AM_TZ="Asia/Tokyo"
export P6AM_SHEETS_INSERT_MODE="INSERT_ROWS"
export P6AM_DATA_PATH="${data_path}"
export P6AM_SHEETS_DEDUPE_DB="${dedupe_path}"
export P6AM_SHEETS_RETRY_QUEUE="${retry_path}"
export MOCK_GOG_COUNT_FILE="${tmp_dir}/gog-count.txt"
export MOCK_GOG_CALLS_FILE="${tmp_dir}/gog-calls.log"

"${script_path}" >/dev/null

if [ ! -f "${dedupe_path}" ]; then
  echo "dedupe file not created" >&2
  exit 1
fi
if [ "$(wc -l < "${dedupe_path}")" -ne 2 ]; then
  echo "expected 2 dedupe keys after first run" >&2
  exit 1
fi
if [ "$(cat "${MOCK_GOG_COUNT_FILE}")" -ne 2 ]; then
  echo "expected 2 gog calls after first run" >&2
  exit 1
fi
first_call="$(head -n 1 "${MOCK_GOG_CALLS_FILE}")"
first_range="$(printf '%s' "${first_call}" | cut -f2)"
if [ "${first_range}" != "raw!A:M" ]; then
  echo "expected range raw!A:M" >&2
  exit 1
fi
first_values_json="$(printf '%s' "${first_call}" | cut -f4-)"
if [ "$(printf '%s' "${first_values_json}" | jq '.[0] | length')" -ne 13 ]; then
  echo "expected 13 columns in values_json" >&2
  exit 1
fi
if ! printf '%s' "${first_values_json}" | jq -e '.[0][1] | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\+09:00$")' >/dev/null; then
  echo "expected JST timestamp column in values_json" >&2
  exit 1
fi
if ! printf '%s' "${first_values_json}" | jq -e '.[0][10] == "gps" and .[0][11] == "termux" and .[0][12] == "pixel6a"' >/dev/null; then
  echo "expected provider/source/device_id columns in values_json" >&2
  exit 1
fi
if [ -f "${retry_path}" ]; then
  echo "retry queue should be empty after successful run" >&2
  exit 1
fi

"${script_path}" >/dev/null
if [ "$(cat "${MOCK_GOG_COUNT_FILE}")" -ne 2 ]; then
  echo "dedupe did not skip duplicate records" >&2
  exit 1
fi

cat >> "${data_path}" <<'EOF'
{"timestamp_utc":"2026-02-21T00:02:00Z","lat":35.2,"lng":139.2,"altitude_m":47.0,"accuracy_m":12.0,"vertical_accuracy_m":13.5,"bearing_deg":181.2,"speed_mps":1.0,"elapsed_ms":2470,"provider":"gps","source":"termux","device_id":"pixel6a"}
EOF

export MOCK_GOG_FAIL_PATTERN='2026-02-21T00:02:00Z'
if "${script_path}" >/dev/null; then
  echo "expected script to fail when append fails" >&2
  exit 1
fi
unset MOCK_GOG_FAIL_PATTERN

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
if [ "$(cat "${MOCK_GOG_COUNT_FILE}")" -ne 4 ]; then
  echo "unexpected number of gog calls" >&2
  exit 1
fi

echo "sheets append test: PASS"
