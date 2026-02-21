---
summary: "planner から merger までの subagent 開発運用"
read_when:
  - 複数subagentで開発を進めるとき
  - どのagentをどの順で使うか迷ったとき
title: "Agent Workflow"
---

# Agent Workflow

このページは開発運用で使う subagent の役割と順序を定義する。

## Scope

- 対象: 開発フローの subagent 運用
- 非対象: アプリ機能としての multi-agent 実装

## Standard Flow

1. `explorer`: 調査と影響範囲の把握
2. `planner`: `docs/experiments/plans/` に実装計画を作成
3. `issue_planner`: plan を実装単位のIssueへ分割
4. `implementer`: 1 Issue を実装しローカル検証
5. `pr_reviewer`: PRの問題点を抽出し `.local/review.*` を更新
6. `pr_preparer`: 指摘対応と `pre-pr` ゲート実行
7. `pr_merger`: 最終検証とマージ判定

## Command Mapping

```bash
scripts/pr-review <PR>
scripts/pr-prepare run <PR>
scripts/pr-merge verify <PR>
```

## Escalation Rules

- 仕様衝突: `planner` に戻して plan を更新する
- 実装衝突: Issue を再分割して parallel 数を下げる
- CI失敗: `pr_preparer` が修正し、同じPRで再検証する

## Parallel Guardrails

- 同時実装は最大3 Issue
- 同一ファイルの同時編集は禁止
- `docs/docs.json` と `scripts/ci/*` は専任担当で更新

## Related

- [Parallel Implementation](/help/parallel-implementation)
- [Issue, Plan, PR Flow](/help/issue-plan-pr)
