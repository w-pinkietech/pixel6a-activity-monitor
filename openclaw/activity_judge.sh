#!/usr/bin/env bash
set -euo pipefail

data_path="${P6AM_DATA_PATH:-data/location.jsonl}"
output_path="${P6AM_JUDGE_OUTPUT_PATH:-tmp/activity-latest.json}"
window_minutes="${P6AM_JUDGE_WINDOW_MINUTES:-60}"
now_utc="${P6AM_JUDGE_NOW_UTC:-}"
medium_min_m="${P6AM_LEVEL_MEDIUM_MIN_M:-300}"
high_min_m="${P6AM_LEVEL_HIGH_MIN_M:-1000}"

if [ -z "$now_utc" ]; then
  now_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

to_epoch() {
  date -u -d "$1" +%s
}

extract_string_field() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true
}

extract_number_field() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*-?[0-9]+(\\.[0-9]+)?" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*//' || true
}

now_epoch="$(to_epoch "$now_utc")"
window_start_epoch="$((now_epoch - window_minutes * 60))"
window_start_utc="$(date -u -d "@${window_start_epoch}" +%Y-%m-%dT%H:%M:%SZ)"

tmp_points="$(mktemp)"
cleanup() {
  rm -f "$tmp_points"
}
trap cleanup EXIT

if [ -f "$data_path" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    ts="$(extract_string_field "$line" "timestamp_utc")"
    lat="$(extract_number_field "$line" "lat")"
    lng="$(extract_number_field "$line" "lng")"
    if [ -z "$ts" ] || [ -z "$lat" ] || [ -z "$lng" ]; then
      continue
    fi
    ts_epoch="$(to_epoch "$ts" 2>/dev/null || true)"
    if [ -z "$ts_epoch" ]; then
      continue
    fi
    if [ "$ts_epoch" -lt "$window_start_epoch" ] || [ "$ts_epoch" -gt "$now_epoch" ]; then
      continue
    fi
    printf '%s|%s|%s\n' "$ts_epoch" "$lat" "$lng" >> "$tmp_points"
  done < "$data_path"
fi

distance_m="0"
event_count="0"
if [ -s "$tmp_points" ]; then
  sorted_points="$(mktemp)"
  sort -n "$tmp_points" > "$sorted_points"
  event_count="$(wc -l < "$sorted_points" | tr -d ' ')"
  distance_m="$(
    awk -F'|' '
      function rad(v) { return v * 3.141592653589793 / 180 }
      function haversine(lat1, lon1, lat2, lon2,   dlat, dlon, a, c, r) {
        dlat = rad(lat2 - lat1)
        dlon = rad(lon2 - lon1)
        a = sin(dlat / 2) * sin(dlat / 2) + cos(rad(lat1)) * cos(rad(lat2)) * sin(dlon / 2) * sin(dlon / 2)
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        r = 6371000
        return r * c
      }
      NR == 1 {
        prev_lat = $2 + 0
        prev_lng = $3 + 0
        next
      }
      {
        current_lat = $2 + 0
        current_lng = $3 + 0
        sum += haversine(prev_lat, prev_lng, current_lat, current_lng)
        prev_lat = current_lat
        prev_lng = current_lng
      }
      END { printf "%.3f", sum + 0 }
    ' "$sorted_points"
  )"
  rm -f "$sorted_points"
fi

movement_level="low"
if awk -v d="$distance_m" -v high="$high_min_m" 'BEGIN { exit !(d >= high) }'; then
  movement_level="high"
elif awk -v d="$distance_m" -v medium="$medium_min_m" 'BEGIN { exit !(d >= medium) }'; then
  movement_level="medium"
fi

mkdir -p "$(dirname "$output_path")"
printf '{"period_start":"%s","period_end":"%s","distance_m":%s,"movement_level":"%s","event_count":%s}\n' \
  "$window_start_utc" "$now_utc" "$distance_m" "$movement_level" "$event_count" \
  > "$output_path"

echo "activity judge done level=${movement_level} events=${event_count}"
