# PR Workflow for Maintainers

このファイルは maintainer 向け PR 運用の single source of truth。

## Working Rule

skills は手順を実行し、maintainer は判断を担う。  
コマンドが通ったことと、実装品質の妥当性は別で評価する。

必須順序:

1. `review-pr`（レビュー専用）
2. `prepare-pr`（修正 + gate）
3. `merge-pr`（最終検証 + マージ）

## Script-First Contract

原則は wrapper を使う。

- `scripts/pr-review <PR>`
- `scripts/pr-prepare init <PR>`
- `scripts/pr-prepare validate-commit <PR>`
- `scripts/pr-prepare gates <PR>`
- `scripts/pr-prepare push <PR> [--execute]`
- `scripts/pr-prepare run <PR>`
- `scripts/pr-merge verify <PR>`
- `scripts/pr-merge run <PR> [--execute]`

`scripts/pr review-init <PR>` は `.worktrees/pr-<PR>` を自動作成し、PRごとに分離した作業領域でレビューする。

## Required Artifacts

- `.local/pr-meta.env`
- `.local/pr-meta.json`
- `.local/review.md`
- `.local/review.json`
- `.local/prep.md`
- `.local/prep.env`
- `.local/pre-pr-report.md`

## Structured Review Handoff

`review-pr` は `.local/review.json` を必須で出力する。  
最低スキーマ:

```json
{
  "recommendation": "READY FOR /prepare-pr",
  "findings": [
    {
      "id": "F1",
      "severity": "IMPORTANT",
      "title": "Example finding",
      "area": "path/or/component",
      "fix": "Actionable fix"
    }
  ],
  "tests": {
    "ran": [],
    "gaps": [],
    "result": "pass"
  }
}
```

`prepare-pr` は `BLOCKER` と `IMPORTANT` を全解消する。

## Gate Policy

最低 gate:

- `./scripts/ci/pre-pr.sh`
- `./scripts/ci/pre-pr-report.sh`
- `./scripts/ci/check-dod.sh .local/prep.md`

失敗時は同一PRで修正して再実行する。

`merge-verify` では GitHub の required checks を厳密に評価する。

- required checks が 0 件なら失敗
- required checks に `pass` 以外が1件でもあれば失敗

## Unified Workflow

### 1) review-pr

目的:

- 事実ベースで差分を評価し、重大度付き findings を出す。

出力:

- `.local/review.md`
- `.local/review.json`

停止条件:

- 問題の再現/検証経路が確保できない。
- 仕様衝突が解消できない。

### 2) prepare-pr

目的:

- findings を解消し、merge可能状態へ整える。

出力:

- `.local/prep.md`
- `.local/prep.env`
- `PR is ready for /merge-pr`

停止条件:

- 修正がPRスコープを大きく超える。
- gate失敗の原因を再現・解消できない。

### 3) merge-pr

目的:

- 最終検証の上でマージ可否を確定する。

Go/No-Go:

- `BLOCKER/IMPORTANT` が未解決なら No-Go
- gate が赤なら No-Go
- リスク/ロールバックが不明確なら No-Go

## Multi-Agent Safety

- `git stash` / `git worktree` / branch 切替は明示依頼時のみ。
- 他agentの未把握差分は壊さない。
- 作業報告は自分の変更範囲に限定する。
