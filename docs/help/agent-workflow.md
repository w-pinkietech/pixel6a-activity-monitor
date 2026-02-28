---
summary: "planner から merger までの subagent 開発運用"
read_when:
  - 複数subagentで開発を進めるとき
  - どのagentをどの順で使うか迷ったとき
title: "Agent Workflow"
---

# Agent Workflow

このページは開発運用で使う subagent の役割と順序を定義する。

Page type: how-to

## Scope

- 対象: 開発フローの subagent 運用
- 非対象: アプリ機能としての multi-agent 実装

## Standard Flow

1. `explorer`: 調査と影響範囲の把握
2. `planner`: `docs/experiments/plans/` に実装計画を作成
3. `issue_planner`: plan を実装単位のIssueへ分割
4. `implementer_bg`: `scripts/lane-worker` で 1 Issue を背景実装し PR 作成まで完了
5. `pr_reviewer`: PRの問題点を抽出し `.local/review.*` を更新
6. `pr_preparer`: 指摘対応と `pre-pr` ゲート実行
7. `pr_merger`: 最終検証とマージ判定

対話が必要な場合のみ `implementer` を使う（仕様確認・スコープ調整・方針相談など）。

## Command Mapping

```bash
scripts/lane-worker run <lane>
scripts/pr-review <PR>
scripts/pr-prepare run <PR>
scripts/pr-merge verify <PR>
```

## Reporting Contract

main agent は計画・実装・検証の要点を統合して最終報告を行う。  
そのために subagent は完了時に報告Markdownを必ず作成する。

main agent の最終報告フォーマット:

- `Implemented Features` を必須セクションにする。
- 「今回実装した機能」をユーザー視点で列挙する。
- 実装がない場合は `none` を明記する。

- 保存先: `.local/agent-reports/`
- 命名: `<UTC timestamp>-<agent>-<scope>.md`
- 必須セクション:
  - `Task / Scope`
  - `Implemented Features`
  - `What changed`
  - `Validation`
  - `Risks / Follow-ups`
  - `Handoff to main agent`

推奨: 作業開始時にテンプレートを生成する。

```bash
scripts/agent-report implementer_bg issue-25 --task "Google Calendar read path"
```

main agent は各 subagent の報告を集約して、Issue/PR の最終コメントやhandoffに反映する。

## PR Creation Gate

Issue実装を含むPRは、実行テスト完了前に作成しない。

- 必須:
  - `./scripts/ci/pre-pr.sh`
  - `./scripts/ci/pre-pr-report.sh`
  - `scripts/pr-open` による証跡チェック
- 並列運用変更時の追加必須:
  - `./scripts/ci/test-3lane-smoke.sh`

## Escalation Rules

- 仕様衝突: `planner` に戻して plan を更新する
- 実装衝突: Issue を再分割して parallel 数を下げる
- CI失敗: `pr_preparer` が修正し、同じPRで再検証する

## Parallel Guardrails

- 同時実装は最大3 Issue
- 同一ファイルの同時編集は禁止
- `docs/docs.json` と `scripts/ci/*` は専任担当で更新

## Related

- [Workflow Design](/help/workflow-design)
- [Parallel Implementation](/help/parallel-implementation)
- [Issue, Plan, PR Flow](/help/issue-plan-pr)
