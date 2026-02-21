#!/usr/bin/env bash
set -euo pipefail

judge_output_path="${P6AM_JUDGE_OUTPUT_PATH:-tmp/activity-latest.json}"
slack_webhook_url="${P6AM_SLACK_WEBHOOK_URL:-}"
notify_state_db="${P6AM_NOTIFY_STATE_DB:-data/slack-notified.keys}"
retry_queue="${P6AM_NOTIFY_RETRY_QUEUE:-tmp/slack-retry.jsonl}"
request_timeout_sec="${P6AM_HTTP_TIMEOUT_SEC:-15}"

if [ -z "$slack_webhook_url" ]; then
  echo "P6AM_SLACK_WEBHOOK_URL is required" >&2
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

extract_number_field() {
  local payload="$1"
  local key="$2"
  printf '%s' "$payload" \
    | grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*-?[0-9]+(\\.[0-9]+)?" \
    | head -n 1 \
    | sed -E 's/.*:[[:space:]]*//' || true
}

escape_json_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

key_exists() {
  local key="$1"
  [ -f "$notify_state_db" ] && grep -Fxq "$key" "$notify_state_db"
}

send_slack_text() {
  local text="$1"
  local payload
  payload="$(printf '{"text":"%s"}' "$(escape_json_string "$text")")"
  curl -fsS --max-time "$request_timeout_sec" \
    -H "Content-Type: application/json" \
    -X POST "$slack_webhook_url" \
    -d "$payload" >/dev/null
}

queue_failure_once() {
  local key="$1"
  local text="$2"
  local retry_tmp="$3"
  local failed_keys="$4"
  if grep -Fxq "$key" "$failed_keys"; then
    return
  fi
  printf '%s\n' "$key" >> "$failed_keys"
  printf '{"dedupe_key":"%s","text":"%s"}\n' "$key" "$(escape_json_string "$text")" >> "$retry_tmp"
}

process_message() {
  local key="$1"
  local text="$2"
  local retry_tmp="$3"
  local failed_keys="$4"
  if key_exists "$key"; then
    skipped=$((skipped + 1))
    return
  fi
  if send_slack_text "$text"; then
    printf '%s\n' "$key" >> "$notify_state_db"
    sent=$((sent + 1))
    return
  fi
  queue_failure_once "$key" "$text" "$retry_tmp" "$failed_keys"
  failed=$((failed + 1))
}

mkdir -p "$(dirname "$notify_state_db")" "$(dirname "$retry_queue")"
touch "$notify_state_db"

retry_tmp="$(mktemp)"
failed_keys="$(mktemp)"
cleanup() {
  rm -f "$retry_tmp" "$failed_keys"
}
trap cleanup EXIT

sent=0
skipped=0
failed=0

if [ -f "$retry_queue" ]; then
  while IFS= read -r queued_line; do
    [ -n "$queued_line" ] || continue
    key="$(extract_string_field "$queued_line" "dedupe_key")"
    text="$(extract_string_field "$queued_line" "text")"
    [ -n "$key" ] || continue
    [ -n "$text" ] || continue
    process_message "$key" "$text" "$retry_tmp" "$failed_keys"
  done < "$retry_queue"
fi

if [ ! -f "$judge_output_path" ]; then
  echo "judge output not found: ${judge_output_path}" >&2
  exit 1
fi

judge_line="$(cat "$judge_output_path")"
period_start="$(extract_string_field "$judge_line" "period_start")"
period_end="$(extract_string_field "$judge_line" "period_end")"
movement_level="$(extract_string_field "$judge_line" "movement_level")"
distance_m="$(extract_number_field "$judge_line" "distance_m")"
event_count="$(extract_number_field "$judge_line" "event_count")"

if [ -z "$period_start" ] || [ -z "$period_end" ] || [ -z "$movement_level" ]; then
  echo "invalid judge output format" >&2
  exit 1
fi
[ -n "$distance_m" ] || distance_m="0"
[ -n "$event_count" ] || event_count="0"

dedupe_key="${period_start}|${period_end}"
message_text="Activity ${movement_level} | period ${period_start} - ${period_end} | distance_m ${distance_m} | events ${event_count}"
process_message "$dedupe_key" "$message_text" "$retry_tmp" "$failed_keys"

if [ -s "$retry_tmp" ]; then
  mv "$retry_tmp" "$retry_queue"
else
  rm -f "$retry_queue"
fi

echo "slack notify done sent=${sent} skipped=${skipped} failed=${failed}"
if [ "$failed" -gt 0 ]; then
  exit 1
fi
