---
summary: "Codex CLI multi-agent をこのリポジトリで使うための設定と手順"
read_when:
  - 複数エージェントでPR運用を固定したいとき
  - review/prepare/merge をスクリプト経由で統一したいとき
  - 実装前に調査専用エージェントを使いたいとき
  - plan/issue/implement の前段フローを分離したいとき
title: "Codex Multi-Agent"
---

# Codex Multi-Agent

このリポジトリでは `.codex/config.toml` で multi-agent を有効化している。

## Config Files

- `.codex/config.toml`
- `.codex/agents/explorer.toml`
- `.codex/agents/planner.toml`
- `.codex/agents/issue_planner.toml`
- `.codex/agents/implementer.toml`
- `.codex/agents/pr_reviewer.toml`
- `.codex/agents/pr_preparer.toml`
- `.codex/agents/pr_merger.toml`

## Verify

```bash
cd /home/wataken/pixel6a-activity-monitor
codex features list | rg '^multi_agent'
```

期待値:

- `multi_agent` が `true`

## How to Use

1. 通常どおり `codex` でセッションを開始する。
2. タスクを分解して、必要な役割にサブエージェントを割り当てる。
3. 設計が必要な場合は `planner` でPlanを作る。
4. Planから実行単位を切るときは `issue_planner` を使う（対応skillは `issue-planning`）。
5. 調査が必要な場合は `explorer` を使う。
6. 実装は `implementer` で進める。
7. PR作業は `pr_reviewer` -> `pr_preparer` -> `pr_merger` の順で実行する。

## Recommended Pattern

- Plan作成: `planner` (`docs/experiments/plans/*.md`)
- Issue分割: `issue_planner` + `issue-planning` (Plan -> Issue unit)
- 調査: `explorer` (read-only)
- 実装: `implementer` + `issue-implementation` (one issue scope)
- レビュー: `pr_reviewer` (`scripts/pr-review <PR>`)
- 修正とGate: `pr_preparer` (`scripts/pr-prepare run <PR>`)
- 最終確認/マージ: `pr_merger` (`scripts/pr-merge verify|run <PR>`)

## Notes

- `features.multi_agent = true` が必須。
- 役割設定には既知キーのみを使う（未知キーは起動時エラー）。
