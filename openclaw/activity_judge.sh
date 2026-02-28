#!/usr/bin/env bash
set -euo pipefail

data_path="${P6AM_DATA_PATH:-data/location.jsonl}"
output_path="${P6AM_JUDGE_OUTPUT_PATH:-tmp/activity-latest.json}"
window_minutes="${P6AM_JUDGE_WINDOW_MINUTES:-60}"
now_utc="${P6AM_JUDGE_NOW_UTC:-}"
medium_min_m="${P6AM_LEVEL_MEDIUM_MIN_M:-300}"
high_min_m="${P6AM_LEVEL_HIGH_MIN_M:-1000}"
calendar_id="${P6AM_CALENDAR_ID:-}"
calendar_tz="${P6AM_CALENDAR_TZ:-Asia/Tokyo}"
calendar_max_events="${P6AM_CALENDAR_MAX_EVENTS:-10}"
gog_bin="${P6AM_GOG_BIN:-gog}"

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

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

default_event_context() {
  local timezone="$1"
  printf '{"event_count":0,"top_events":[],"timezone":"%s"}' "$(json_escape "$timezone")"
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

event_context="$(default_event_context "$calendar_tz")"
if [ -z "$calendar_id" ]; then
  echo "calendar context fallback: reason=calendar_id_not_set timezone=${calendar_tz}"
else
  if ! command -v "$gog_bin" >/dev/null 2>&1; then
    echo "calendar context fallback: reason=gog_not_found bin=${gog_bin} timezone=${calendar_tz}" >&2
  elif ! command -v jq >/dev/null 2>&1; then
    echo "calendar context fallback: reason=jq_missing timezone=${calendar_tz}" >&2
  elif ! [[ "$calendar_max_events" =~ ^[0-9]+$ ]] || [ "$calendar_max_events" -le 0 ]; then
    echo "calendar context fallback: reason=invalid_calendar_max_events value=${calendar_max_events}" >&2
  else
    if [ "$calendar_max_events" -gt 10 ]; then
      echo "calendar context note: max events clamped from ${calendar_max_events} to 10"
      calendar_max_events="10"
    fi
    today_local="$(TZ="$calendar_tz" date -d "$now_utc" +%Y-%m-%d 2>/dev/null || true)"
    if [ -z "$today_local" ]; then
      echo "calendar context fallback: reason=invalid_calendar_timezone timezone=${calendar_tz}" >&2
    else
      calendar_window_start_epoch="$(
        TZ="$calendar_tz" date -d "${today_local} 00:00:00" +%s 2>/dev/null || true
      )"
      calendar_window_end_epoch="$(
        TZ="$calendar_tz" date -d "${today_local} 23:59:59" +%s 2>/dev/null || true
      )"
      if [ -z "$calendar_window_start_epoch" ] || [ -z "$calendar_window_end_epoch" ]; then
        echo "calendar context fallback: reason=calendar_window_build_failed timezone=${calendar_tz}" >&2
      else
        calendar_window_start_utc="$(
          date -u -d "@${calendar_window_start_epoch}" +%Y-%m-%dT%H:%M:%SZ
        )"
        calendar_window_end_utc="$(
          date -u -d "@${calendar_window_end_epoch}" +%Y-%m-%dT%H:%M:%SZ
        )"
        calendar_err="$(mktemp)"
        if calendar_raw="$(
          "$gog_bin" calendar events list "$calendar_id" \
            --time-min "$calendar_window_start_utc" \
            --time-max "$calendar_window_end_utc" \
            --limit "$calendar_max_events" \
            --json \
            2>"$calendar_err"
        )"; then
          top_events="$(
            printf '%s' "$calendar_raw" | jq -c --argjson max "$calendar_max_events" '
              def normalize_time($value):
                if ($value | type) == "object" then
                  ($value.dateTime // $value.date // "")
                else
                  ""
                end;
              (if type == "array" then . else (.items // .events // []) end)
              | map({
                  start_at: normalize_time(.start),
                  end_at: normalize_time(.end),
                  summary: (.summary // "")
                })
              | map(select(.start_at != "" and .end_at != ""))
              | .[:$max]
            ' 2>/dev/null || true
          )"
          if [ -n "$top_events" ]; then
            event_context="$(
              jq -cn --argjson top_events "$top_events" --arg timezone "$calendar_tz" \
                '{event_count: ($top_events | length), top_events: $top_events, timezone: $timezone}'
            )"
            calendar_event_count="$(printf '%s' "$event_context" | jq -r '.event_count')"
            echo "calendar context loaded: count=${calendar_event_count} timezone=${calendar_tz} window=${calendar_window_start_utc}..${calendar_window_end_utc}"
          else
            echo "calendar context fallback: reason=invalid_calendar_payload timezone=${calendar_tz}" >&2
          fi
        else
          calendar_error_detail="$(cat "$calendar_err")"
          echo "calendar context fallback: reason=calendar_fetch_failed calendar_id=${calendar_id} timezone=${calendar_tz} detail=${calendar_error_detail}" >&2
        fi
        rm -f "$calendar_err"
      fi
    fi
  fi
fi

mkdir -p "$(dirname "$output_path")"
printf '{"period_start":"%s","period_end":"%s","distance_m":%s,"movement_level":"%s","event_count":%s,"event_context":"%s"}\n' \
  "$window_start_utc" "$now_utc" "$distance_m" "$movement_level" "$event_count" "$(json_escape "$event_context")" \
  > "$output_path"

echo "activity judge done level=${movement_level} events=${event_count}"
