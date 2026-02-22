#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
smoke_script="${repo_root}/termux/collect_smoke.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

mock_bin="${tmp_dir}/bin"
mkdir -p "${mock_bin}"

cat > "${mock_bin}/termux-location" <<'EOF'
#!/usr/bin/env bash
cat <<'JSON'
{
  "latitude": 35.681236,
  "longitude": 139.767125,
  "altitude": 44.2,
  "accuracy": 12.5,
  "vertical_accuracy": 18.4,
  "bearing": 123.5,
  "speed": 0.8,
  "elapsedMs": 2450,
  "provider": "gps"
}
JSON
EOF
chmod +x "${mock_bin}/termux-location"

output_path="${tmp_dir}/location.jsonl"
run_log="${tmp_dir}/run.log"

PATH="${mock_bin}:${PATH}" \
P6AM_DATA_PATH="${output_path}" \
P6AM_DEVICE_ID="pixel6a-test" \
P6AM_SMOKE_SAMPLE_COUNT=3 \
P6AM_SMOKE_INTERVAL_SEC=0 \
"${smoke_script}" >"${run_log}"

if [ ! -f "${output_path}" ]; then
  echo "smoke script did not create output file" >&2
  exit 1
fi

line_count="$(wc -l < "${output_path}" | tr -d ' ')"
if [ "${line_count}" -ne 3 ]; then
  echo "expected 3 JSONL lines, got ${line_count}" >&2
  exit 1
fi

if ! grep -q 'smoke collection done records=3' "${run_log}"; then
  echo "unexpected smoke script output" >&2
  exit 1
fi

line="$(tail -n 1 "${output_path}")"
for key in timestamp_utc lat lng altitude_m accuracy_m vertical_accuracy_m bearing_deg speed_mps elapsed_ms provider source device_id; do
  if ! printf '%s' "${line}" | grep -q "\"${key}\""; then
    echo "missing key in output: ${key}" >&2
    exit 1
  fi
done

echo "termux smoke test: PASS"
