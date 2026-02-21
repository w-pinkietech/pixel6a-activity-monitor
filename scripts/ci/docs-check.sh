#!/usr/bin/env bash
set -euo pipefail

files=$(find docs -type f -name '*.md' | sort)
if [ -z "${files}" ]; then
  exit 0
fi

for f in ${files}; do
  if ! head -n 1 "$f" | grep -q '^---$'; then
    echo "missing frontmatter start: $f"
    exit 1
  fi
  if ! grep -q '^title:' "$f"; then
    echo "missing title: $f"
    exit 1
  fi
  if ! grep -q '^summary:' "$f"; then
    echo "missing summary: $f"
    exit 1
  fi
  if ! grep -q '^read_when:' "$f"; then
    echo "missing read_when: $f"
    exit 1
  fi
done

bad=$(grep -RInE '\]\((\./|\.\./|[^/)]+\.md\))' docs || true)
if [ -n "$bad" ]; then
  echo "Found non-root-relative or .md links:"
  echo "$bad"
  exit 1
fi

echo "docs-check: OK"
