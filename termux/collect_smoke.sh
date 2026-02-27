#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
collector="${repo_root}/termux/collect_location.sh"

sample_count="${P6AM_SMOKE_SAMPLE_COUNT:-3}"
interval_sec="${P6AM_SMOKE_INTERVAL_SEC:-10}"
data_path="${P6AM_DATA_PATH:-${repo_root}/data/location.jsonl}"
device_id="${P6AM_DEVICE_ID:-pixel6a}"
provider="${P6AM_LOCATION_PROVIDER:-gps}"
request="${P6AM_LOCATION_REQUEST:-once}"

is_positive_int() {
  printf '%s' "$1" | grep -Eq '^[1-9][0-9]*$'
}

is_non_negative_int() {
  printf '%s' "$1" | grep -Eq '^(0|[1-9][0-9]*)$'
}

line_count() {
  local file_path="$1"
  if [ -f "$file_path" ]; then
    wc -l < "$file_path" | tr -d ' '
    return
  fi
  echo "0"
}

extract_timestamps() {
  local file_path="$1"
  local last_count="$2"
  tail -n "$last_count" "$file_path" \
    | sed -n 's/.*"timestamp_utc":"\([^"]*\)".*/\1/p'
}

if ! is_positive_int "$sample_count"; then
  echo "P6AM_SMOKE_SAMPLE_COUNT must be a positive integer: ${sample_count}" >&2
  exit 1
fi
if ! is_non_negative_int "$interval_sec"; then
  echo "P6AM_SMOKE_INTERVAL_SEC must be a non-negative integer: ${interval_sec}" >&2
  exit 1
fi
if ! command -v termux-location >/dev/null 2>&1; then
  echo "termux-location command not found. Install Termux:API app and termux-api package." >&2
  exit 1
fi

before_count="$(line_count "$data_path")"

echo "starting smoke collection samples=${sample_count} interval_sec=${interval_sec}"
index=1
while [ "$index" -le "$sample_count" ]; do
  P6AM_DATA_PATH="$data_path" \
  P6AM_DEVICE_ID="$device_id" \
  P6AM_LOCATION_PROVIDER="$provider" \
  P6AM_LOCATION_REQUEST="$request" \
  "$collector" >/dev/null
  echo "sample ${index}/${sample_count}: ok"

  if [ "$index" -lt "$sample_count" ] && [ "$interval_sec" -gt 0 ]; then
    sleep "$interval_sec"
  fi
  index=$((index + 1))
done

after_count="$(line_count "$data_path")"
added_count=$((after_count - before_count))
if [ "$added_count" -lt "$sample_count" ]; then
  echo "unexpected result: expected at least ${sample_count} new records, got ${added_count}" >&2
  exit 1
fi

timestamp_rows="$(extract_timestamps "$data_path" "$sample_count")"
first_ts="$(printf '%s\n' "$timestamp_rows" | head -n 1)"
last_ts="$(printf '%s\n' "$timestamp_rows" | tail -n 1)"

chmod 600 "$data_path" 2>/dev/null || true
echo "smoke collection done records=${added_count} first_ts=${first_ts} last_ts=${last_ts} path=${data_path}"
