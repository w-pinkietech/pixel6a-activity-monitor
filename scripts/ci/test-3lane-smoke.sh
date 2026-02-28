#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/ci/test-3lane-smoke.sh [--base <git-ref>] [--keep]

What it does:
  1. Creates 3 temporary worktrees from the target base ref (default: current HEAD)
  2. Runs per-lane smoke commands in parallel
     - ./scripts/ci/docs-check.sh
     - ./scripts/agent-report implementer <lane-scope>
  3. Writes a summary report to .local/3lane-smoke-report-<UTC>.md
  4. Cleans up temporary worktrees/branches (unless --keep)
USAGE
}

keep="false"
base_ref=""
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi
while [ "$#" -gt 0 ]; do
  case "$1" in
    --keep)
      keep="true"
      shift
      ;;
    --base)
      base_ref="${2:-}"
      shift 2
      ;;
    *)
      echo "unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "missing required command: $cmd" >&2
    exit 1
  }
}

repo_root() {
  local script_dir
  local common_git_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if common_git_dir=$(git -C "$script_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    (cd "$(dirname "$common_git_dir")" && pwd)
    return
  fi

  (cd "$script_dir/../.." && pwd)
}

require_cmd git

if [ -z "$base_ref" ]; then
  base_ref="$(git rev-parse HEAD)"
fi

root="$(repo_root)"
cd "$root"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
base_dir="tmp/3lane-smoke-${timestamp}"
report_path=".local/3lane-smoke-report-${timestamp}.md"

mkdir -p .local tmp

branches=()
dirs=()
pids=()
lane_report_paths=()

cleanup() {
  if [ "$keep" = "true" ]; then
    echo "keep=true: temp worktrees are preserved under ${base_dir}"
    return
  fi

  local i
  for i in "${!dirs[@]}"; do
    git worktree remove "${dirs[$i]}" --force >/dev/null 2>&1 || true
  done

  for i in "${!branches[@]}"; do
    git branch -D "${branches[$i]}" >/dev/null 2>&1 || true
  done

  rmdir "$base_dir" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "3lane smoke test: preparing temporary worktrees (base=${base_ref})"
if [[ "$base_ref" == origin/* ]]; then
  git fetch origin "${base_ref#origin/}" >/dev/null
fi

for lane in 1 2 3; do
  branch="tmp/3lane-smoke-${timestamp}-${lane}"
  dir="${base_dir}/lane${lane}"
  branches+=("$branch")
  dirs+=("$dir")
  git worktree add "$dir" -b "$branch" "$base_ref" >/dev/null
done

echo "3lane smoke test: running lane jobs in parallel"
for lane in 1 2 3; do
  dir="${base_dir}/lane${lane}"
  mkdir -p "${dir}/.local"
  (
    cd "$dir"
    ./scripts/ci/docs-check.sh > .local/3lane-smoke.log 2>&1
    if [ -x ./scripts/agent-report ]; then
      ./scripts/agent-report implementer "lane${lane}-smoke" --task "3lane smoke test lane${lane}" > .local/3lane-report-path.txt
    else
      printf 'scripts/agent-report unavailable on base ref (%s)\n' "$base_ref" > .local/3lane-report-path.txt
    fi
  ) &
  pids+=("$!")
done

status="PASS"
for i in "${!pids[@]}"; do
  if ! wait "${pids[$i]}"; then
    status="FAIL"
  fi
done

{
  echo "# 3-Lane Smoke Test Report"
  echo
  echo "- Timestamp (UTC): ${timestamp}"
  echo "- Result: ${status}"
  echo "- Base ref: ${base_ref}"
  echo
  for lane in 1 2 3; do
    dir="${base_dir}/lane${lane}"
    branch="tmp/3lane-smoke-${timestamp}-${lane}"
    report_ref="-"
    if [ -f "${dir}/.local/3lane-report-path.txt" ]; then
      report_ref="$(cat "${dir}/.local/3lane-report-path.txt")"
    fi
    echo "## Lane ${lane}"
    echo "- Worktree: ${dir}"
    echo "- Branch: ${branch}"
    echo "- docs-check: $(grep -q 'docs-check: OK' "${dir}/.local/3lane-smoke.log" && echo PASS || echo FAIL)"
    echo "- Agent report: ${report_ref}"
    echo
  done
} > "$report_path"

if [ "$status" != "PASS" ]; then
  echo "3lane smoke test: FAIL"
  echo "report: $report_path"
  exit 1
fi

echo "3lane smoke test: PASS"
echo "report: $report_path"
