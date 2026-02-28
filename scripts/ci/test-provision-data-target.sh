#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

tmp_dir="$(mktemp -d)"
mock_bin="${tmp_dir}/bin"
state_dir="${tmp_dir}/state"
mkdir -p "$mock_bin" "$state_dir"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

cat > "${mock_bin}/gog" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_dir="${MOCK_GOG_STATE_DIR:?}"
calls_file="${MOCK_GOG_CALLS_FILE:?}"

echo "$*" >> "$calls_file"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -j|--json|--no-input|-y|--force|-v|--verbose|-n|--dry-run|-p|--plain|--results-only)
      shift
      ;;
    -a|--account|--client|--select|--color|--enable-commands)
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

cmd="${1:-}"
sub="${2:-}"
shift 2 || true

folder_id_path="${state_dir}/folder.id"
sheet_id_path="${state_dir}/sheet.id"
folder_id="folder-001"
sheet_id="sheet-001"

case "${cmd} ${sub}" in
  "drive search")
    query=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --raw-query)
          query="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    if [[ "$query" == *"application/vnd.google-apps.folder"* ]]; then
      if [ -f "$folder_id_path" ]; then
        printf '[{"id":"%s"}]\n' "$folder_id"
      else
        printf '[]\n'
      fi
      exit 0
    fi
    if [[ "$query" == *"application/vnd.google-apps.spreadsheet"* ]]; then
      if [ -f "$sheet_id_path" ]; then
        printf '[{"id":"%s"}]\n' "$sheet_id"
      else
        printf '[]\n'
      fi
      exit 0
    fi
    printf '[]\n'
    ;;
  "drive mkdir")
    printf '%s\n' "$folder_id" > "$folder_id_path"
    printf '{"id":"%s"}\n' "$folder_id"
    ;;
  "sheets create")
    printf '%s\n' "$sheet_id" > "$sheet_id_path"
    printf '{"spreadsheetId":"%s"}\n' "$sheet_id"
    ;;
  "drive move")
    printf '{"ok":true}\n'
    ;;
  "sheets update")
    printf '{"updatedCells":13}\n'
    ;;
  *)
    echo "unexpected gog command: ${cmd} ${sub}" >&2
    exit 1
    ;;
esac
EOF
chmod +x "${mock_bin}/gog"

export PATH="${mock_bin}:${PATH}"
export MOCK_GOG_STATE_DIR="$state_dir"
export MOCK_GOG_CALLS_FILE="${tmp_dir}/gog-calls.log"
touch "$MOCK_GOG_CALLS_FILE"

export P6AM_GOG_BIN="gog"
export P6AM_GOG_ACCOUNT="test@example.com"
export P6AM_DRIVE_PARENT_ID="root-parent-001"
export P6AM_DRIVE_FOLDER_NAME="p6am-folder"
export P6AM_SHEETS_TITLE="p6am-sheet"
export P6AM_PROVISION_OUTPUT_PATH="${tmp_dir}/provision.env"

run_once() {
  (cd "$repo_root" && ./openclaw/provision_data_target.sh)
}

count_call() {
  local pattern="$1"
  grep -E -c "$pattern" "$MOCK_GOG_CALLS_FILE"
}

run_once

if [ ! -f "${tmp_dir}/provision.env" ]; then
  echo "provision output file not created" >&2
  exit 1
fi

if ! grep -q '^P6AM_DRIVE_FOLDER_ID=' "${tmp_dir}/provision.env"; then
  echo "P6AM_DRIVE_FOLDER_ID missing in output" >&2
  exit 1
fi
if ! grep -q '^P6AM_SHEETS_ID=' "${tmp_dir}/provision.env"; then
  echo "P6AM_SHEETS_ID missing in output" >&2
  exit 1
fi

mkdir_first="$(count_call ' drive mkdir ')"
create_first="$(count_call ' sheets create ')"
move_first="$(count_call ' drive move ')"
update_first="$(count_call ' sheets update ')"

if [ "$mkdir_first" -ne 1 ] || [ "$create_first" -ne 1 ] || [ "$move_first" -ne 1 ] || [ "$update_first" -ne 2 ]; then
  echo "unexpected first-run call counts mkdir=${mkdir_first} create=${create_first} move=${move_first} update=${update_first}" >&2
  exit 1
fi

run_once

mkdir_second="$(count_call ' drive mkdir ')"
create_second="$(count_call ' sheets create ')"
move_second="$(count_call ' drive move ')"
update_second="$(count_call ' sheets update ')"

if [ "$mkdir_second" -ne 1 ] || [ "$create_second" -ne 1 ] || [ "$move_second" -ne 1 ]; then
  echo "idempotency failed: create/move repeated mkdir=${mkdir_second} create=${create_second} move=${move_second}" >&2
  exit 1
fi
if [ "$update_second" -ne 4 ]; then
  echo "expected headers to be refreshed on second run (expected 4 updates total, got ${update_second})" >&2
  exit 1
fi

echo "provision data target test: PASS"
