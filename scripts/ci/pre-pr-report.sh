#!/usr/bin/env bash
set -euo pipefail

status_file=".local/pre-pr.status"
log_file=".local/pre-pr.log"
report_file=".local/pre-pr-report.md"
tail_lines="${TAIL_LINES:-60}"

if [ ! -f "$status_file" ]; then
  echo "missing $status_file. run ./scripts/ci/pre-pr.sh first."
  exit 1
fi

result="$(sed -n 's/^result=//p' "$status_file" | tail -n 1)"
event="$(sed -n 's/^event=//p' "$status_file" | tail -n 1)"
job="$(sed -n 's/^job=//p' "$status_file" | tail -n 1)"
ran_at="$(sed -n 's/^ran_at=//p' "$status_file" | tail -n 1)"
exit_code="$(sed -n 's/^exit_code=//p' "$status_file" | tail -n 1)"

if [ -f "$log_file" ]; then
  log_tail="$(tail -n "$tail_lines" "$log_file")"
else
  log_tail="(no log file)"
fi

cat > "$report_file" <<EOF
## Local CI (act)

- Command: \`./scripts/ci/pre-pr.sh ${event:-pull_request} ${job:-docs}\`
- Result: ${result:-UNKNOWN}
- Exit Code: ${exit_code:-0}
- Ran At: ${ran_at:-unknown}

<details>
<summary>act output tail (${tail_lines} lines)</summary>

\`\`\`text
$log_tail
\`\`\`

</details>
EOF

echo "wrote $report_file"
