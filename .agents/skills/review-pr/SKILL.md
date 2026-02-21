---
name: review-pr
description: Script-first review-only PR analysis with structured findings handoff.
---

# Review PR

## Overview

PR を read-only で評価し、`prepare-pr` 向けハンドオフ成果物を作る。

## Inputs

- PR番号またはURL（必須）

## Safety

- push/mergeしない。
- 残すべき差分を勝手に編集しない。

## Execution Contract

1. 初期化:

```sh
scripts/pr-review <PR>
```

`scripts/pr-review` は `.worktrees/pr-<PR>` を作成して分離レビュー環境を用意する。

2. レビュー成果物を作成:

- `.local/review.md`
- `.local/review.json`

3. 必要なら成果物検証:

```sh
scripts/pr review-validate-artifacts <PR>
```

## Required JSON Shape

```json
{
  "recommendation": "READY FOR /prepare-pr",
  "findings": [],
  "tests": {
    "ran": [],
    "gaps": [],
    "result": "pass"
  }
}
```

## Guardrails

- findings は `BLOCKER / IMPORTANT / NIT` のみ。
- `BLOCKER` と `IMPORTANT` は修正可能な指示を書く。
