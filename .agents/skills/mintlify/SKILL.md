---
name: mintlify
description: Build and maintain Mintlify docs with consistent navigation, frontmatter, and links.
---

# mintlify

## Overview

Mintlifyドキュメント整備専用スキル。ページ作成、ナビ更新、リンク整合性、frontmatter整備を行う。

## Scope

- `docs/**/*.md`
- `docs/docs.json`
- docs内の内部リンク修正

## Rules

- 新規ページは `title`, `summary`, `read_when` を必須にする。
- 内部リンクはルート相対で `.md` なし。
- 新規ページ追加時は `docs/docs.json` にナビを追加する。
- 重複ページを増やさず、既存ページ更新を優先する。

## Validation

```bash
./scripts/ci/docs-check.sh
./scripts/ci/pre-pr.sh pull_request docs
```

## Output

- 変更ファイル一覧
- 追加/更新したナビ項目
- リンク修正点

