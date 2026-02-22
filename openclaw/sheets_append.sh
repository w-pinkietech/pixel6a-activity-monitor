#!/usr/bin/env bash
set -euo pipefail

data_path="${P6AM_DATA_PATH:-data/location.jsonl}"
sheets_id="${P6AM_SHEETS_ID:-}"
sheets_tab="${P6AM_SHEETS_TAB:-}"
sheets_range="${P6AM_SHEETS_RANGE:-}"
gog_bin="${P6AM_GOG_BIN:-gog}"
insert_mode="${P6AM_SHEETS_INSERT_MODE:-INSERT_ROWS}"
dedupe_db="${P6AM_SHEETS_DEDUPE_DB:-data/sheets-dedupe.keys}"
retry_queue="${P6AM_SHEETS_RETRY_QUEUE:-tmp/sheets-retry.jsonl}"

if [ -z "${sheets_id}" ]; then
  echo "P6AM_SHEETS_ID is required" >&2
  exit 1
fi

if [ -z "${sheets_range}" ] && [ -n "${sheets_tab}" ]; then
  sheets_range="${sheets_tab}!A:F"
fi
if [ -z "${sheets_range}" ]; then
  echo "P6AM_SHEETS_RANGE or P6AM_SHEETS_TAB is required" >&2
  exit 1
fi

if ! command -v "$gog_bin" >/dev/null 2>&1; then
  echo "gog binary not found: ${gog_bin}" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

extract_string_field() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true
}

hash_value() {
  local value="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$value" | sha256sum | awk '{print $1}'
    return
  fi
  printf '%s' "$value" | shasum -a 256 | awk '{print $1}'
}

record_key() {
  local line="$1"
  local timestamp
  local device_id
  timestamp="$(extract_string_field "$line" "timestamp_utc")"
  device_id="$(extract_string_field "$line" "device_id")"
  if [ -n "${timestamp}" ] && [ -n "${device_id}" ]; then
    hash_value "${timestamp}|${device_id}"
    return
  fi
  hash_value "$line"
}

key_exists() {
  local key="$1"
  [ -f "$dedupe_db" ] && grep -Fxq "$key" "$dedupe_db"
}

send_record() {
  local line="$1"
  local values_json
  values_json="$(
    printf '%s' "$line" | jq -c '[
      [
        (.timestamp_utc // ""),
        (if .lat == null then "" else (.lat | tostring) end),
        (if .lng == null then "" else (.lng | tostring) end),
        (if .accuracy_m == null then "" else (.accuracy_m | tostring) end),
        (.source // ""),
        (.device_id // "")
      ]
    ]'
  )"
  "$gog_bin" sheets append "$sheets_id" "$sheets_range" \
    --values-json "$values_json" \
    --insert "$insert_mode" \
    --no-input >/dev/null
}

queue_failure_once() {
  local key="$1"
  local line="$2"
  local retry_tmp="$3"
  local failed_keys="$4"
  if grep -Fxq "$key" "$failed_keys"; then
    return
  fi
  printf '%s\n' "$key" >> "$failed_keys"
  printf '%s\n' "$line" >> "$retry_tmp"
}

mkdir -p "$(dirname "$dedupe_db")" "$(dirname "$retry_queue")"
touch "$dedupe_db"

retry_tmp="$(mktemp)"
failed_keys="$(mktemp)"
cleanup() {
  rm -f "$retry_tmp" "$failed_keys"
}
trap cleanup EXIT

total=0
sent=0
skipped=0
failed=0

process_file() {
  local file_path="$1"
  [ -f "$file_path" ] || return 0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    total=$((total + 1))
    key="$(record_key "$line")"
    if key_exists "$key"; then
      skipped=$((skipped + 1))
      continue
    fi
    if send_record "$line"; then
      printf '%s\n' "$key" >> "$dedupe_db"
      sent=$((sent + 1))
      continue
    fi
    queue_failure_once "$key" "$line" "$retry_tmp" "$failed_keys"
    failed=$((failed + 1))
  done < "$file_path"
}

if [ ! -f "$data_path" ] && [ ! -f "$retry_queue" ]; then
  echo "no input data: data and retry queue are missing"
  exit 0
fi

process_file "$retry_queue"
process_file "$data_path"

if [ -s "$retry_tmp" ]; then
  mv "$retry_tmp" "$retry_queue"
else
  rm -f "$retry_queue"
fi

echo "sheets append done total=${total} sent=${sent} skipped=${skipped} failed=${failed}"
if [ "$failed" -gt 0 ]; then
  exit 1
fi
