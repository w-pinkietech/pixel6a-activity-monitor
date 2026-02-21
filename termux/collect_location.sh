#!/usr/bin/env bash
set -euo pipefail

data_path="${P6AM_DATA_PATH:-data/location.jsonl}"
device_id="${P6AM_DEVICE_ID:-pixel6a}"
provider="${P6AM_LOCATION_PROVIDER:-gps}"
source_name="termux"

extract_number() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*-?[0-9]+(\\.[0-9]+)?" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*//' || true
}

raw_payload="${P6AM_FORCE_LOCATION_JSON:-}"
if [ -z "$raw_payload" ]; then
  if ! command -v termux-location >/dev/null 2>&1; then
    echo "termux-location command not found" >&2
    exit 1
  fi
  raw_payload="$(termux-location -p "${provider}")"
fi

compact_payload="$(printf '%s' "${raw_payload}" | tr -d '\n' | tr -d '\r')"
lat="$(extract_number "${compact_payload}" "latitude")"
lng="$(extract_number "${compact_payload}" "longitude")"
accuracy="$(extract_number "${compact_payload}" "accuracy")"

if [ -z "${lat}" ] || [ -z "${lng}" ]; then
  echo "location payload missing latitude/longitude" >&2
  exit 1
fi

accuracy_json="null"
if [ -n "${accuracy}" ]; then
  accuracy_json="${accuracy}"
fi

timestamp_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "${data_path}")"
umask 077
printf '{"timestamp_utc":"%s","lat":%s,"lng":%s,"accuracy_m":%s,"source":"%s","device_id":"%s"}\n' \
  "${timestamp_utc}" "${lat}" "${lng}" "${accuracy_json}" "${source_name}" "${device_id}" \
  >> "${data_path}"

echo "location record appended at ${timestamp_utc}"
