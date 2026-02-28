#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  openclaw/register_cron_jobs.sh [options]

Options:
  --gateway-url <url>       OpenClaw gateway URL (default: ws://127.0.0.1:18791)
  --gateway-token <token>   OpenClaw gateway token (optional)
  --collect-cron <expr>     Cron expression for collect-sheets job (default: * * * * *)
  --judge-cron <expr>       Cron expression for judge-notify job (default: 0 * * * *)
  --timezone <iana>         Cron timezone (default: P6AM_TZ or Asia/Tokyo)
  --collect-name <name>     Job name for collect flow (default: collect-sheets)
  --judge-name <name>       Job name for judge flow (default: judge-notify)
  --disable                 Create/update jobs as disabled
  --dry-run                 Print planned operations only
  -h, --help                Show this help
USAGE
}

bool_true() {
  case "$1" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

shell_quote() {
  local value="$1"
  printf '%q' "$value"
}

append_env_assignment() {
  local current="$1"
  local key="$2"
  local value
  value="${!key:-}"
  if [ -z "$value" ]; then
    printf '%s' "$current"
    return
  fi
  printf '%s %s=%s' "$current" "$key" "$(shell_quote "$value")"
}

build_shell_command() {
  local script_path="$1"
  shift || true
  local cmd
  cmd="cd $(shell_quote "$repo_root")"
  if [ -n "$shell_prefix" ]; then
    cmd="${cmd} && ${shell_prefix}"
  fi
  while [ "$#" -gt 0 ]; do
    cmd="$(append_env_assignment "$cmd" "$1")"
    shift
  done
  cmd="${cmd} && $(shell_quote "$script_path")"
  printf '%s' "$cmd"
}

build_agent_message() {
  local shell_command="$1"
  cat <<EOF
Run this exact shell command once and return only one short status line:

${shell_command}
EOF
}

cron_base_args() {
  local args=()
  if [ -n "$gateway_url" ]; then
    args+=(--url "$gateway_url")
  fi
  if [ -n "$gateway_token" ]; then
    args+=(--token "$gateway_token")
  fi
  printf '%s\0' "${args[@]}"
}

run_openclaw() {
  local args=("$@")
  local shared_args=()
  while IFS= read -r -d '' item; do
    shared_args+=("$item")
  done < <(cron_base_args)
  "$openclaw_bin" "${args[@]}" "${shared_args[@]}"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "required command not found: ${cmd}" >&2
    exit 1
  fi
}

fetch_jobs_json() {
  run_openclaw cron list --all --json
}

job_id_by_name() {
  local jobs_json="$1"
  local name="$2"
  printf '%s\n' "$jobs_json" | jq -r --arg name "$name" '
    def jobs:
      if type == "array" then .
      elif (.jobs? | type) == "array" then .jobs
      elif (.items? | type) == "array" then .items
      elif (.result? | type) == "array" then .result
      elif (.result.jobs? | type) == "array" then .result.jobs
      else []
      end;
    jobs
    | map(select((.name // .job_name // "") == $name))
    | .[0].id // empty
  '
}

upsert_job() {
  local jobs_json="$1"
  local job_name="$2"
  local job_description="$3"
  local cron_expr="$4"
  local message="$5"
  local job_id
  local mode
  local args

  job_id="$(job_id_by_name "$jobs_json" "$job_name")"
  args=(
    --name "$job_name"
    --description "$job_description"
    --cron "$cron_expr"
    --tz "$cron_timezone"
    --session isolated
    --message "$message"
  )

  if [ -n "$job_id" ]; then
    mode="edit"
    if [ "$jobs_enabled" = "true" ]; then
      args+=(--enable)
    else
      args+=(--disable)
    fi
    if [ "$dry_run" = "true" ]; then
      printf '[dry-run] %s cron edit %s' "$openclaw_bin" "$job_id"
      printf ' %q' "${args[@]}"
      printf '\n'
      return
    fi
    run_openclaw cron edit "$job_id" "${args[@]}" >/dev/null
  else
    mode="add"
    if [ "$jobs_enabled" != "true" ]; then
      args+=(--disabled)
    fi
    if [ "$dry_run" = "true" ]; then
      printf '[dry-run] %s cron add' "$openclaw_bin"
      printf ' %q' "${args[@]}"
      printf '\n'
      return
    fi
    run_openclaw cron add "${args[@]}" >/dev/null
  fi

  echo "cron ${mode}: ${job_name}"
}

openclaw_bin="${P6AM_OPENCLAW_BIN:-openclaw}"
gateway_url="${P6AM_OPENCLAW_GATEWAY_URL:-${OPENCLAW_GATEWAY_URL:-ws://127.0.0.1:18791}}"
gateway_token="${P6AM_OPENCLAW_GATEWAY_TOKEN:-${OPENCLAW_GATEWAY_TOKEN:-}}"
collect_cron_expr="${P6AM_OPENCLAW_COLLECT_CRON:-* * * * *}"
judge_cron_expr="${P6AM_OPENCLAW_JUDGE_CRON:-0 * * * *}"
cron_timezone="${P6AM_OPENCLAW_CRON_TZ:-${P6AM_TZ:-Asia/Tokyo}}"
collect_job_name="${P6AM_OPENCLAW_COLLECT_JOB_NAME:-collect-sheets}"
judge_job_name="${P6AM_OPENCLAW_JUDGE_JOB_NAME:-judge-notify}"
jobs_enabled_raw="${P6AM_OPENCLAW_CRON_ENABLED:-true}"
shell_prefix="${P6AM_OPENCLAW_CRON_SHELL_PREFIX:-}"
dry_run="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --gateway-url)
      gateway_url="${2:-}"
      shift 2
      ;;
    --gateway-token)
      gateway_token="${2:-}"
      shift 2
      ;;
    --collect-cron)
      collect_cron_expr="${2:-}"
      shift 2
      ;;
    --judge-cron)
      judge_cron_expr="${2:-}"
      shift 2
      ;;
    --timezone)
      cron_timezone="${2:-}"
      shift 2
      ;;
    --collect-name)
      collect_job_name="${2:-}"
      shift 2
      ;;
    --judge-name)
      judge_job_name="${2:-}"
      shift 2
      ;;
    --disable)
      jobs_enabled_raw="false"
      shift
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if bool_true "$jobs_enabled_raw"; then
  jobs_enabled="true"
else
  jobs_enabled="false"
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

require_cmd "$openclaw_bin"
require_cmd jq

collect_shell_command="$(
  build_shell_command "./openclaw/collect_sheets_job.sh" \
    P6AM_TERMUX_SSH_HOST \
    P6AM_TERMUX_SSH_USER \
    P6AM_TERMUX_SSH_PORT \
    P6AM_TERMUX_TAILNET_TARGET \
    P6AM_GOG_BIN \
    P6AM_GOG_ACCOUNT \
    P6AM_SHEETS_ID \
    P6AM_SHEETS_RANGE \
    P6AM_LOCATION_REQUEST \
    P6AM_TZ
)"
collect_message="$(build_agent_message "$collect_shell_command")"

judge_shell_command="$(
  build_shell_command "./openclaw/judge_notify_job.sh" \
    P6AM_TAILNET_TARGET \
    P6AM_NOTIFY_CMD \
    P6AM_TZ
)"
judge_message="$(build_agent_message "$judge_shell_command")"

jobs_json="$(fetch_jobs_json)"

upsert_job \
  "$jobs_json" \
  "$collect_job_name" \
  "Collect Pixel6a location via SSH and append to Google Sheets every minute" \
  "$collect_cron_expr" \
  "$collect_message"

if [ "$dry_run" != "true" ]; then
  jobs_json="$(fetch_jobs_json)"
fi

upsert_job \
  "$jobs_json" \
  "$judge_job_name" \
  "Run hourly activity judge and OpenClaw notify integration flow" \
  "$judge_cron_expr" \
  "$judge_message"

if [ "$dry_run" = "true" ]; then
  echo "dry-run finished"
  exit 0
fi

echo "cron registration done: collect=${collect_job_name} judge=${judge_job_name} enabled=${jobs_enabled}"
