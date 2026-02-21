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

cat > "${data_path}" <<'EOF'
{"timestamp_utc":"2026-02-21T00:00:00Z","lat":35.00000,"lng":139.00000,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
{"timestamp_utc":"2026-02-21T00:10:00Z","lat":35.00000,"lng":139.00500,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
{"timestamp_utc":"2026-02-21T00:20:00Z","lat":35.00000,"lng":139.01000,"accuracy_m":10.0,"source":"termux","device_id":"pixel6a"}
EOF

P6AM_DATA_PATH="${data_path}" \
P6AM_JUDGE_OUTPUT_PATH="${output_path}" \
P6AM_JUDGE_NOW_UTC="2026-02-21T01:00:00Z" \
P6AM_JUDGE_WINDOW_MINUTES="60" \
P6AM_LEVEL_MEDIUM_MIN_M="300" \
P6AM_LEVEL_HIGH_MIN_M="800" \
"${script_path}" >/dev/null

if ! grep -q '"movement_level":"high"' "${output_path}"; then
  echo "expected high movement level" >&2
  exit 1
fi
if ! grep -q '"event_count":3' "${output_path}"; then
  echo "expected event_count=3" >&2
  exit 1
fi

first_output="$(cat "${output_path}")"
P6AM_DATA_PATH="${data_path}" \
P6AM_JUDGE_OUTPUT_PATH="${output_path}" \
P6AM_JUDGE_NOW_UTC="2026-02-21T01:00:00Z" \
P6AM_JUDGE_WINDOW_MINUTES="60" \
P6AM_LEVEL_MEDIUM_MIN_M="300" \
P6AM_LEVEL_HIGH_MIN_M="800" \
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
"${script_path}" >/dev/null
if ! grep -q '"movement_level":"low"' "${output_path}"; then
  echo "expected low movement level with high thresholds" >&2
  exit 1
fi

echo "activity judge test: PASS"
