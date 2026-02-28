#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
script_path="${repo_root}/openclaw/activity_judge.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

data_path="${tmp_dir}/location.jsonl"
output_path="${tmp_dir}/judge.json"
mock_bin="${tmp_dir}/bin"
mkdir -p "${mock_bin}"

cat > "${data_path}" <<'EOF'
{"timestamp_utc":"2026-02-21T00:00:00Z","lat":35.00000,"lng":139.00000,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
{"timestamp_utc":"2026-02-21T00:10:00Z","lat":35.00000,"lng":139.00500,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
{"timestamp_utc":"2026-02-21T00:20:00Z","lat":35.00000,"lng":139.01000,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
EOF

cat > "${mock_bin}/gog" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${MOCK_GOG_MODE:-success}" = "fail" ]; then
  echo "mock calendar API error" >&2
  exit 1
fi
cat <<'JSON'
{
  "items": [
    {"start":{"dateTime":"2026-02-21T00:30:00+09:00"},"end":{"dateTime":"2026-02-21T01:00:00+09:00"},"summary":"Daily standup"},
    {"start":{"dateTime":"2026-02-21T09:00:00+09:00"},"end":{"dateTime":"2026-02-21T10:00:00+09:00"},"summary":"Team sync"},
    {"start":{"date":"2026-02-21"},"end":{"date":"2026-02-22"},"summary":"All day"},
    {"start":{"dateTime":"2026-02-21T11:00:00+09:00"},"end":{"dateTime":"2026-02-21T11:30:00+09:00"},"summary":"Focus"},
    {"start":{"dateTime":"2026-02-21T12:00:00+09:00"},"end":{"dateTime":"2026-02-21T12:30:00+09:00"},"summary":"Lunch"},
    {"start":{"dateTime":"2026-02-21T13:00:00+09:00"},"end":{"dateTime":"2026-02-21T13:30:00+09:00"},"summary":"Review"},
    {"start":{"dateTime":"2026-02-21T14:00:00+09:00"},"end":{"dateTime":"2026-02-21T14:30:00+09:00"},"summary":"1:1"},
    {"start":{"dateTime":"2026-02-21T15:00:00+09:00"},"end":{"dateTime":"2026-02-21T15:30:00+09:00"},"summary":"Design"},
    {"start":{"dateTime":"2026-02-21T16:00:00+09:00"},"end":{"dateTime":"2026-02-21T16:30:00+09:00"},"summary":"Check-in"},
    {"start":{"dateTime":"2026-02-21T17:00:00+09:00"},"end":{"dateTime":"2026-02-21T17:30:00+09:00"},"summary":"Wrap up"},
    {"start":{"dateTime":"2026-02-21T18:00:00+09:00"},"end":{"dateTime":"2026-02-21T18:30:00+09:00"},"summary":"Extra"}
  ]
}
JSON
EOF
chmod +x "${mock_bin}/gog"

P6AM_DATA_PATH="${data_path}" \
P6AM_JUDGE_OUTPUT_PATH="${output_path}" \
P6AM_JUDGE_NOW_UTC="2026-02-21T01:00:00Z" \
P6AM_JUDGE_WINDOW_MINUTES="60" \
P6AM_LEVEL_MEDIUM_MIN_M="300" \
P6AM_LEVEL_HIGH_MIN_M="800" \
PATH="${mock_bin}:${PATH}" \
P6AM_GOG_BIN="gog" \
P6AM_CALENDAR_ID="demo-calendar" \
P6AM_CALENDAR_TZ="Asia/Tokyo" \
P6AM_CALENDAR_MAX_EVENTS="10" \
"${script_path}" >/dev/null

if ! grep -q '"movement_level":"high"' "${output_path}"; then
  echo "expected high movement level" >&2
  exit 1
fi
if ! grep -q '"event_count":3' "${output_path}"; then
  echo "expected event_count=3" >&2
  exit 1
fi
if [ "$(jq -r '.event_context | fromjson | .timezone' "${output_path}")" != "Asia/Tokyo" ]; then
  echo "expected event_context.timezone=Asia/Tokyo" >&2
  exit 1
fi
if [ "$(jq -r '.event_context | fromjson | .event_count' "${output_path}")" != "10" ]; then
  echo "expected calendar event_context.event_count=10" >&2
  exit 1
fi
if [ "$(jq -r '.event_context | fromjson | .top_events | length' "${output_path}")" != "10" ]; then
  echo "expected event_context.top_events length=10" >&2
  exit 1
fi
if [ "$(jq -r '.event_context | fromjson | .top_events[0] | has("start_at") and has("end_at") and has("summary")' "${output_path}")" != "true" ]; then
  echo "expected fixed top_events schema" >&2
  exit 1
fi

first_output="$(cat "${output_path}")"
P6AM_DATA_PATH="${data_path}" \
P6AM_JUDGE_OUTPUT_PATH="${output_path}" \
P6AM_JUDGE_NOW_UTC="2026-02-21T01:00:00Z" \
P6AM_JUDGE_WINDOW_MINUTES="60" \
P6AM_LEVEL_MEDIUM_MIN_M="300" \
P6AM_LEVEL_HIGH_MIN_M="800" \
PATH="${mock_bin}:${PATH}" \
P6AM_GOG_BIN="gog" \
P6AM_CALENDAR_ID="demo-calendar" \
P6AM_CALENDAR_TZ="Asia/Tokyo" \
P6AM_CALENDAR_MAX_EVENTS="10" \
"${script_path}" >/dev/null
second_output="$(cat "${output_path}")"
if [ "${first_output}" != "${second_output}" ]; then
  echo "judge output is not stable across reruns" >&2
  exit 1
fi

P6AM_DATA_PATH="${data_path}" \
P6AM_JUDGE_OUTPUT_PATH="${output_path}" \
P6AM_JUDGE_NOW_UTC="2026-02-21T01:00:00Z" \
P6AM_JUDGE_WINDOW_MINUTES="60" \
P6AM_LEVEL_MEDIUM_MIN_M="2000" \
P6AM_LEVEL_HIGH_MIN_M="5000" \
PATH="${mock_bin}:${PATH}" \
P6AM_GOG_BIN="gog" \
P6AM_CALENDAR_ID="demo-calendar" \
P6AM_CALENDAR_TZ="Asia/Tokyo" \
P6AM_CALENDAR_MAX_EVENTS="10" \
"${script_path}" >/dev/null
if ! grep -q '"movement_level":"low"' "${output_path}"; then
  echo "expected low movement level with high thresholds" >&2
  exit 1
fi

MOCK_GOG_MODE="fail" \
P6AM_DATA_PATH="${data_path}" \
P6AM_JUDGE_OUTPUT_PATH="${output_path}" \
P6AM_JUDGE_NOW_UTC="2026-02-21T01:00:00Z" \
P6AM_JUDGE_WINDOW_MINUTES="60" \
P6AM_LEVEL_MEDIUM_MIN_M="300" \
P6AM_LEVEL_HIGH_MIN_M="800" \
PATH="${mock_bin}:${PATH}" \
P6AM_GOG_BIN="gog" \
P6AM_CALENDAR_ID="invalid-calendar" \
P6AM_CALENDAR_TZ="Asia/Tokyo" \
P6AM_CALENDAR_MAX_EVENTS="10" \
"${script_path}" >/dev/null
if [ "$(jq -r '.movement_level' "${output_path}")" != "high" ]; then
  echo "judge should continue on calendar fetch failure" >&2
  exit 1
fi
if [ "$(jq -r '.event_context | fromjson | .event_count' "${output_path}")" != "0" ]; then
  echo "calendar failure should fallback to empty event_context" >&2
  exit 1
fi

echo "activity judge test: PASS"
