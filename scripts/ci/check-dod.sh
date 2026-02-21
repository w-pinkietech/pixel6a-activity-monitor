#!/usr/bin/env bash
set -euo pipefail

target="${1:-.local/prep.md}"

if [ ! -f "$target" ]; then
  echo "missing $target"
  exit 1
fi

required_patterns=(
  "^## Validation$"
  "^## Remaining items$"
  "^- \\[x\\] ./scripts/ci/pre-pr.sh$"
  "^- \\[x\\] ./scripts/ci/pre-pr-report.sh$"
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Eq "$pattern" "$target"; then
    echo "missing required section or marker in $target: $pattern"
    exit 1
  fi
done

echo "check-dod: OK"
