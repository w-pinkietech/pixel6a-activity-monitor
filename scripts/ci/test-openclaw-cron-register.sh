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

cat > "${state_dir}/jobs.json" <<'EOF'
{"jobs":[]}
EOF

cat > "${mock_bin}/openclaw" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_dir="${MOCK_OPENCLAW_STATE_DIR:?}"
calls_file="${MOCK_OPENCLAW_CALLS_FILE:?}"
jobs_file="${state_dir}/jobs.json"
counter_file="${state_dir}/counter"

echo "$*" >> "$calls_file"

if [ ! -f "$counter_file" ]; then
  echo 0 > "$counter_file"
fi

next_id() {
  local n
  n="$(cat "$counter_file")"
  n=$((n + 1))
  echo "$n" > "$counter_file"
  printf 'job-%03d' "$n"
}

json_bool() {
  if [ "$1" = "true" ]; then
    printf 'true'
  else
    printf 'false'
  fi
}

require_cron() {
  if [ "${1:-}" != "cron" ]; then
    echo "unexpected command prefix: $*" >&2
    exit 1
  fi
}

parse_common_flags() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --url|--token)
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done
  printf '%s\0' "$@"
}

require_cron "${1:-}"
shift
sub="${1:-}"
shift || true

case "$sub" in
  list)
    args=()
    while IFS= read -r -d '' item; do
      args+=("$item")
    done < <(parse_common_flags "$@")
    cat "$jobs_file"
    ;;
  add)
    name=""
    description=""
    cron_expr=""
    tz=""
    message=""
    enabled="true"

    args=()
    while IFS= read -r -d '' item; do
      args+=("$item")
    done < <(parse_common_flags "$@")
    set -- "${args[@]}"

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --name) name="${2:-}"; shift 2 ;;
        --description) description="${2:-}"; shift 2 ;;
        --cron) cron_expr="${2:-}"; shift 2 ;;
        --tz) tz="${2:-}"; shift 2 ;;
        --message) message="${2:-}"; shift 2 ;;
        --disabled) enabled="false"; shift ;;
        --session) shift 2 ;;
        *) shift ;;
      esac
    done

    id="$(next_id)"
    job_json="$(jq -n \
      --arg id "$id" \
      --arg name "$name" \
      --arg description "$description" \
      --arg cron_expr "$cron_expr" \
      --arg tz "$tz" \
      --arg message "$message" \
      --argjson enabled "$(json_bool "$enabled")" \
      '{id:$id,name:$name,description:$description,enabled:$enabled,schedule:{kind:"cron",expr:$cron_expr,tz:$tz},payload:{kind:"agentTurn",message:$message}}'
    )"
    jq --argjson job "$job_json" '.jobs += [$job]' "$jobs_file" > "${jobs_file}.tmp"
    mv "${jobs_file}.tmp" "$jobs_file"
    printf '{"id":"%s","name":"%s"}\n' "$id" "$name"
    ;;
  edit)
    id="${1:-}"
    shift || true
    name=""
    description=""
    cron_expr=""
    tz=""
    message=""
    set_enable=""
    set_disable=""

    args=()
    while IFS= read -r -d '' item; do
      args+=("$item")
    done < <(parse_common_flags "$@")
    set -- "${args[@]}"

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --name) name="${2:-}"; shift 2 ;;
        --description) description="${2:-}"; shift 2 ;;
        --cron) cron_expr="${2:-}"; shift 2 ;;
        --tz) tz="${2:-}"; shift 2 ;;
        --message) message="${2:-}"; shift 2 ;;
        --enable) set_enable="true"; shift ;;
        --disable) set_disable="true"; shift ;;
        --session) shift 2 ;;
        *) shift ;;
      esac
    done

    enable_state="keep"
    if [ -n "$set_enable" ]; then
      enable_state="true"
    fi
    if [ -n "$set_disable" ]; then
      enable_state="false"
    fi

    jq \
      --arg id "$id" \
      --arg name "$name" \
      --arg description "$description" \
      --arg cron_expr "$cron_expr" \
      --arg tz "$tz" \
      --arg message "$message" \
      --arg enable_state "$enable_state" \
      '
      .jobs |= map(
        if .id == $id then
          .name = (if ($name | length) > 0 then $name else .name end)
          | .description = (if ($description | length) > 0 then $description else .description end)
          | .schedule.expr = (if ($cron_expr | length) > 0 then $cron_expr else .schedule.expr end)
          | .schedule.tz = (if ($tz | length) > 0 then $tz else .schedule.tz end)
          | .payload.message = (if ($message | length) > 0 then $message else .payload.message end)
          | .enabled = (if $enable_state == "true" then true elif $enable_state == "false" then false else .enabled end)
        else
          .
        end
      )
      ' "$jobs_file" > "${jobs_file}.tmp"
    mv "${jobs_file}.tmp" "$jobs_file"
    printf '{"id":"%s"}\n' "$id"
    ;;
  *)
    echo "unsupported mock subcommand: ${sub}" >&2
    exit 1
    ;;
esac
EOF
chmod +x "${mock_bin}/openclaw"

export PATH="${mock_bin}:${PATH}"
export MOCK_OPENCLAW_STATE_DIR="$state_dir"
export MOCK_OPENCLAW_CALLS_FILE="${tmp_dir}/openclaw-calls.log"
touch "$MOCK_OPENCLAW_CALLS_FILE"

export P6AM_OPENCLAW_BIN="openclaw"
export P6AM_OPENCLAW_GATEWAY_URL="ws://127.0.0.1:18791"
export P6AM_OPENCLAW_GATEWAY_TOKEN="dummy-token"
export P6AM_OPENCLAW_COLLECT_JOB_NAME="collect-sheets"
export P6AM_OPENCLAW_JUDGE_JOB_NAME="judge-notify"
export P6AM_OPENCLAW_COLLECT_CRON="* * * * *"
export P6AM_OPENCLAW_JUDGE_CRON="0 * * * *"
export P6AM_OPENCLAW_CRON_TZ="Asia/Tokyo"

export P6AM_TERMUX_SSH_HOST="termux"
export P6AM_TERMUX_SSH_USER="u0_a569"
export P6AM_TERMUX_TAILNET_TARGET="google-pixel-6a"
export P6AM_SHEETS_ID="sheet-test-001"
export P6AM_SHEETS_RANGE="raw!A:M"
export P6AM_LOCATION_REQUEST="last"
export P6AM_TAILNET_TARGET="google-pixel-6a"
export P6AM_TZ="Asia/Tokyo"

run_register() {
  (cd "$repo_root" && ./openclaw/register_cron_jobs.sh)
}

count_calls() {
  local pattern="$1"
  grep -E -c "$pattern" "$MOCK_OPENCLAW_CALLS_FILE"
}

run_register

if [ "$(count_calls '^cron add ')" -ne 2 ]; then
  echo "first run should add 2 jobs" >&2
  exit 1
fi
if [ "$(count_calls '^cron edit ')" -ne 0 ]; then
  echo "first run should not edit jobs" >&2
  exit 1
fi
if [ "$(count_calls '^cron list ')" -lt 2 ]; then
  echo "first run should call list for idempotency checks" >&2
  exit 1
fi

if ! grep -q -- '--url ws://127.0.0.1:18791' "$MOCK_OPENCLAW_CALLS_FILE"; then
  echo "expected --url option to be passed" >&2
  exit 1
fi
if ! grep -q -- '--token dummy-token' "$MOCK_OPENCLAW_CALLS_FILE"; then
  echo "expected --token option to be passed" >&2
  exit 1
fi

if [ "$(jq '.jobs | length' "${state_dir}/jobs.json")" -ne 2 ]; then
  echo "expected exactly 2 jobs after first run" >&2
  exit 1
fi

collect_message="$(
  jq -r '.jobs[] | select(.name=="collect-sheets") | .payload.message' "${state_dir}/jobs.json"
)"
judge_message="$(
  jq -r '.jobs[] | select(.name=="judge-notify") | .payload.message' "${state_dir}/jobs.json"
)"
if [[ "$collect_message" != *"./openclaw/collect_sheets_job.sh"* ]]; then
  echo "collect message does not include collect script" >&2
  exit 1
fi
if [[ "$judge_message" != *"./openclaw/judge_notify_job.sh"* ]]; then
  echo "judge message does not include judge script" >&2
  exit 1
fi

export P6AM_OPENCLAW_JUDGE_CRON="*/30 * * * *"
run_register

if [ "$(count_calls '^cron add ')" -ne 2 ]; then
  echo "second run should not add more jobs" >&2
  exit 1
fi
if [ "$(count_calls '^cron edit ')" -ne 2 ]; then
  echo "second run should edit 2 existing jobs" >&2
  exit 1
fi

judge_expr="$(
  jq -r '.jobs[] | select(.name=="judge-notify") | .schedule.expr' "${state_dir}/jobs.json"
)"
if [ "$judge_expr" != "*/30 * * * *" ]; then
  echo "judge cron expression not updated by second run: ${judge_expr}" >&2
  exit 1
fi

echo "openclaw cron register test: PASS"
