#!/usr/bin/env bash
set -euo pipefail

gog_bin="${P6AM_GOG_BIN:-gog}"
gog_account="${P6AM_GOG_ACCOUNT:-}"
drive_parent_id="${P6AM_DRIVE_PARENT_ID:-}"
drive_folder_name="${P6AM_DRIVE_FOLDER_NAME:-pixel6a-activity-monitor}"
sheets_title="${P6AM_SHEETS_TITLE:-pixel6a-activity-monitor-raw}"
raw_range="${P6AM_SHEETS_RANGE:-raw!A:M}"
conversation_range="${P6AM_CONVERSATION_RANGE:-conversation_log!A:H}"
output_path="${P6AM_PROVISION_OUTPUT_PATH:-tmp/provision-data-target.env}"

if ! command -v "$gog_bin" >/dev/null 2>&1; then
  echo "gog binary not found: ${gog_bin}" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

escape_query_literal() {
  local value="$1"
  printf '%s' "$value" | sed "s/'/\\\\'/g"
}

gog_json() {
  local args=("-j" "--no-input")
  if [ -n "$gog_account" ]; then
    args+=("-a" "$gog_account")
  fi
  "$gog_bin" "${args[@]}" "$@"
}

extract_first_id() {
  local payload="$1"
  printf '%s\n' "$payload" | jq -r '
    if type == "array" then
      .[0].id // empty
    elif has("files") then
      .files[0].id // empty
    elif has("result") and (.result | type == "array") then
      .result[0].id // empty
    elif has("result") and (.result | type == "object") and (.result.files? | type == "array") then
      .result.files[0].id // empty
    elif has("id") then
      .id
    else
      empty
    end
  '
}

extract_create_id() {
  local payload="$1"
  printf '%s\n' "$payload" | jq -r '
    .spreadsheetId //
    .id //
    .result.spreadsheetId //
    .result.id //
    .file.id //
    empty
  '
}

find_folder_id() {
  local escaped
  local query
  local result
  escaped="$(escape_query_literal "$drive_folder_name")"
  query="name = '${escaped}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
  if [ -n "$drive_parent_id" ]; then
    query="${query} and '${drive_parent_id}' in parents"
  fi
  result="$(gog_json drive search --raw-query "$query" --max 1)"
  extract_first_id "$result"
}

create_folder() {
  local result
  local folder_id
  local args=("drive" "mkdir" "$drive_folder_name")
  if [ -n "$drive_parent_id" ]; then
    args+=("--parent" "$drive_parent_id")
  fi
  result="$(gog_json "${args[@]}")"
  folder_id="$(extract_create_id "$result")"
  if [ -z "$folder_id" ]; then
    echo "failed to parse folder id from drive mkdir response" >&2
    echo "$result" >&2
    exit 1
  fi
  printf '%s' "$folder_id"
}

find_sheet_id() {
  local escaped_title
  local escaped_folder_id
  local query
  local result
  escaped_title="$(escape_query_literal "$sheets_title")"
  escaped_folder_id="$(escape_query_literal "$1")"
  query="name = '${escaped_title}' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false and '${escaped_folder_id}' in parents"
  result="$(gog_json drive search --raw-query "$query" --max 1)"
  extract_first_id "$result"
}

create_sheet() {
  local result
  local sheet_id
  result="$(gog_json sheets create "$sheets_title" --sheets "raw,conversation_log")"
  sheet_id="$(extract_create_id "$result")"
  if [ -z "$sheet_id" ]; then
    echo "failed to parse spreadsheet id from sheets create response" >&2
    echo "$result" >&2
    exit 1
  fi
  printf '%s' "$sheet_id"
}

initialize_headers() {
  local sheet_id="$1"
  local raw_headers
  local conversation_headers
  raw_headers='[["timestamp_utc","timestamp_jst","lat","lng","altitude_m","accuracy_m","vertical_accuracy_m","bearing_deg","speed_mps","elapsed_ms","provider","source","device_id"]]'
  conversation_headers='[["ts_utc","channel","actor","message_type","summary","action_requested","action_result","dedupe_key"]]'

  gog_json sheets update "$sheet_id" "raw!A1:M1" \
    --values-json "$raw_headers" \
    --input RAW >/dev/null

  gog_json sheets update "$sheet_id" "conversation_log!A1:H1" \
    --values-json "$conversation_headers" \
    --input RAW >/dev/null
}

folder_id="$(find_folder_id)"
if [ -z "$folder_id" ]; then
  folder_id="$(create_folder)"
fi

sheet_id="$(find_sheet_id "$folder_id")"
created_sheet="false"
if [ -z "$sheet_id" ]; then
  sheet_id="$(create_sheet)"
  created_sheet="true"
fi

if [ "$created_sheet" = "true" ]; then
  gog_json drive move "$sheet_id" --parent "$folder_id" >/dev/null
fi

initialize_headers "$sheet_id"

mkdir -p "$(dirname "$output_path")"
{
  printf 'P6AM_DRIVE_FOLDER_ID=%q\n' "$folder_id"
  printf 'P6AM_DRIVE_FOLDER_NAME=%q\n' "$drive_folder_name"
  printf 'P6AM_SHEETS_ID=%q\n' "$sheet_id"
  printf 'P6AM_SHEETS_TITLE=%q\n' "$sheets_title"
  printf 'P6AM_SHEETS_RANGE=%q\n' "$raw_range"
  printf 'P6AM_CONVERSATION_RANGE=%q\n' "$conversation_range"
} > "$output_path"

echo "provision done folder_id=${folder_id} sheets_id=${sheet_id}"
echo "output=${output_path}"
