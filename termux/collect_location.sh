#!/usr/bin/env bash
set -euo pipefail

data_path="${P6AM_DATA_PATH:-data/location.jsonl}"
device_id="${P6AM_DEVICE_ID:-pixel6a}"
provider="${P6AM_LOCATION_PROVIDER:-gps}"
request="${P6AM_LOCATION_REQUEST:-once}"
source_name="termux"

extract_number() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*-?[0-9]+(\\.[0-9]+)?" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*//' || true
}

extract_string() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true
}

to_json_number_or_null() {
  local value="$1"
  if [ -n "$value" ]; then
    printf '%s' "$value"
    return
  fi
  printf 'null'
}

raw_payload="${P6AM_FORCE_LOCATION_JSON:-}"
if [ -z "$raw_payload" ]; then
  if ! command -v termux-location >/dev/null 2>&1; then
    echo "termux-location command not found" >&2
    exit 1
  fi
  raw_payload="$(termux-location -p "${provider}" -r "${request}")"
fi

compact_payload="$(printf '%s' "${raw_payload}" | tr -d '\n' | tr -d '\r')"
lat="$(extract_number "${compact_payload}" "latitude")"
lng="$(extract_number "${compact_payload}" "longitude")"
accuracy="$(extract_number "${compact_payload}" "accuracy")"
altitude="$(extract_number "${compact_payload}" "altitude")"
vertical_accuracy="$(extract_number "${compact_payload}" "vertical_accuracy")"
bearing="$(extract_number "${compact_payload}" "bearing")"
speed="$(extract_number "${compact_payload}" "speed")"
elapsed_ms="$(extract_number "${compact_payload}" "elapsedMs")"
provider_reported="$(extract_string "${compact_payload}" "provider")"

if [ -z "${lat}" ] || [ -z "${lng}" ]; then
  echo "location payload missing latitude/longitude" >&2
  exit 1
fi

accuracy_json="$(to_json_number_or_null "${accuracy}")"
altitude_json="$(to_json_number_or_null "${altitude}")"
vertical_accuracy_json="$(to_json_number_or_null "${vertical_accuracy}")"
bearing_json="$(to_json_number_or_null "${bearing}")"
speed_json="$(to_json_number_or_null "${speed}")"
elapsed_ms_json="$(to_json_number_or_null "${elapsed_ms}")"
provider_json="${provider_reported:-${provider}}"

timestamp_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "${data_path}")"
umask 077
printf '{"timestamp_utc":"%s","lat":%s,"lng":%s,"altitude_m":%s,"accuracy_m":%s,"vertical_accuracy_m":%s,"bearing_deg":%s,"speed_mps":%s,"elapsed_ms":%s,"provider":"%s","source":"%s","device_id":"%s"}\n' \
  "${timestamp_utc}" "${lat}" "${lng}" "${altitude_json}" "${accuracy_json}" "${vertical_accuracy_json}" "${bearing_json}" "${speed_json}" "${elapsed_ms_json}" "${provider_json}" "${source_name}" "${device_id}" \
  >> "${data_path}"

echo "location record appended at ${timestamp_utc}"
