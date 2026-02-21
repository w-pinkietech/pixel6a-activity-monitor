#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
collector="${repo_root}/termux/collect_location.sh"

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
  "accuracy": 12.5
}
JSON
EOF
chmod +x "${mock_bin}/termux-location"

output_path="${tmp_dir}/location.jsonl"
PATH="${mock_bin}:${PATH}" \
P6AM_DATA_PATH="${output_path}" \
P6AM_DEVICE_ID="pixel6a-test" \
"${collector}" >/dev/null

if [ ! -f "${output_path}" ]; then
  echo "collector did not create output file" >&2
  exit 1
fi

line_count="$(wc -l < "${output_path}")"
if [ "${line_count}" -ne 1 ]; then
  echo "expected 1 JSONL line, got ${line_count}" >&2
  exit 1
fi

line="$(cat "${output_path}")"
for key in timestamp_utc lat lng accuracy_m source device_id; do
  if ! printf '%s' "${line}" | grep -q "\"${key}\""; then
    echo "missing key in output: ${key}" >&2
    exit 1
  fi
done

if ! printf '%s' "${line}" | grep -q '"device_id":"pixel6a-test"'; then
  echo "unexpected device_id in output" >&2
  exit 1
fi

echo "termux collector test: PASS"
