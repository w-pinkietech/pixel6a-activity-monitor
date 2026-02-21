---
name: issue-implementation
description: Implement one scoped issue based on an approved plan, then run local validation before PR flow.
---

# issue-implementation

## Overview

IssueとPlanに従って実装し、PR前の最低検証まで完了させる。

## Inputs

- 対象Issue
- 対応するPlan (`docs/experiments/plans/*.md`)

## Rules

- スコープ外の変更を混ぜない。
- 変更理由と検証結果を残す。
- docs変更があれば docs規約を守る。
- PR系操作（review/prepare/merge）は行わない。

## Validation

- `./scripts/ci/docs-check.sh`
- 可能なら関連テストを実行

## Output

- 実装差分
- 実行した検証コマンドと結果
- 残課題（あれば）
