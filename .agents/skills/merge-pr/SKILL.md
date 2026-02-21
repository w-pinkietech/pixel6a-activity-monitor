---
name: merge-pr
description: Final merge gate after prepare-pr with explicit go/no-go checks.
---

# Merge PR

## Overview

`prepare-pr` 完了後の最終 gate とマージ実行。

## Inputs

- PR番号またはURL（必須）
- `.local/review.md`
- `.local/review.json`
- `.local/prep.md`
- `.local/prep.env`

## Execution Contract

1. 検証:

```sh
scripts/pr-merge verify <PR>
```

2. 問題なければ実行:

```sh
scripts/pr-merge run <PR> --execute
```

3. dry-run確認だけする場合:

```sh
scripts/pr-merge run <PR>
```

## Go / No-Go

- `BLOCKER/IMPORTANT` 残存: No-Go
- gate 失敗: No-Go
- required checks が0件、または非passが1件でもある: No-Go
- それ以外: Go

## Guardrails

- `gh pr merge` 直実行は避け、wrapperを使う。
- マージ後は必要なら結果をPRコメントに残す。
