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

Page type: how-to

## Config Files

- `.codex/config.toml`
- `.codex/agents/explorer.toml`
- `.codex/agents/planner.toml`
- `.codex/agents/issue_planner.toml`
- `.codex/agents/implementer.toml`
- `.codex/agents/implementer_bg.toml`
- `.codex/agents/pr_reviewer.toml`
- `.codex/agents/pr_preparer.toml`
- `.codex/agents/pr_merger.toml`

## Agent Split Policy

エージェントは用途で分離する。

- 対話用: `implementer`
  - ユーザーと直接対話しながらスコープを詰める通常実装
- 背景実行用 (unified_exec): `implementer_bg`
  - `lane-worker` から非対話で流す実装

`lane-worker` は `codex exec --enable unified_exec` で実行し、
背景実行では `implementer_bg` を使う。

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
6. 実装〜PR作成は `scripts/lane-worker` から `implementer_bg` を使って background 実行する。
7. 仕様確認など対話が必要な場合のみ `implementer` を使う。
8. PR作業は `pr_reviewer` -> `pr_preparer` -> `pr_merger` の順で実行する。

## Recommended Topology (3 lanes)

安定運用のため、次を 1 セットとしてレーンを分離する。

- 1 lane = 1 Issue
- 1 lane = 1 branch
- 1 lane = 1 worktree
- 1 lane = 1 background worker process (`scripts/lane-worker run <lane>`)

並列上限は 3 lanes（Issue 3本）を維持する。

## 3-Lane Bootstrap

```bash
git fetch origin main

git worktree add .worktrees/lane1 -b feat/issue-25-calendar-read origin/main
git worktree add .worktrees/lane2 -b feat/issue-26-calendar-write-contract origin/main
git worktree add .worktrees/lane3 -b feat/issue-27-calendar-write-exec origin/main

scripts/lane-monitor init
# edit .local/lanes.tsv
scripts/lane-worker run-all
scripts/lane-monitor start --interval 60
```

tmux は必須ではない。監視だけが必要な場合は `scripts/lane-monitor` を使う。
各 lane では `implementer_bg` に 1 Issue だけを担当させる。

## 3-Lane Smoke Test

並列運用ルールや lane 実行スクリプトを変更した場合は、PR前に次を実行する。

```bash
./scripts/ci/test-3lane-smoke.sh
```

成功時は `.local/3lane-smoke-report-<UTC>.md` が生成される。  
結果要約（PASS/FAILとレポートパス）をPR本文またはコメントへ残す。

## Recommended Pattern

- Plan作成: `planner` (`docs/experiments/plans/*.md`)
- Issue分割: `issue_planner` + `issue-planning` (Plan -> Issue unit)
- 調査: `explorer` (read-only)
- 実装(標準): `implementer_bg` + `issue-implementation` (`scripts/lane-worker` で issue -> PR)
- 実装(例外): `implementer` + `issue-implementation` (ユーザーとの直接対話が必要な場合)
- レビュー: `pr_reviewer` (`scripts/pr-review <PR>`)
- 修正とGate: `pr_preparer` (`scripts/pr-prepare run <PR>`)
- 最終確認/マージ: `pr_merger` (`scripts/pr-merge verify|run <PR>`)

## Main Agent Responsibilities

main agent は次を担当する。

- lane 全体の優先度と依存順の管理
- subagent の報告Markdown収集
- plan/issue/pr の統合サマリ作成
- ユーザー向け最終報告で `Implemented Features` セクションを必ず記載

subagent は完了時に `.local/agent-reports/` へ報告Markdownを作成し、main agent にパスを返す。

報告雛形の生成:

```bash
scripts/agent-report implementer_bg issue-25 --task "Google Calendar read path"
```

## Notes

- `features.multi_agent = true` が必須。
- 役割設定には既知キーのみを使う（未知キーは起動時エラー）。

## GitHub CLI Guardrails

Issue/PR を Codex から操作する場合は、次を標準手順にする。

1. 事前に `gh auth status` を実行し、token が有効であることを確認する。
2. token 無効時は再認証する。

```bash
gh auth logout -h github.com -u cycling777
gh auth login -h github.com -p ssh -w
gh auth status
```

3. `gh issue create` / `gh issue comment` / `gh pr *` はネットワーク必須のため、実行コンテキスト由来で失敗した場合はネットワーク到達可能な環境で再実行する。
4. 失敗時は原因を切り分ける。
   - `The token ... is invalid` -> 認証切れ
   - `error connecting to github.com` -> 実行コンテキスト（sandbox）由来の接続失敗の可能性

## Preferred PR Operations

- PR の create/review/prepare/merge は `gh` 直打ちより wrapper を優先する。
- 使用順序:
  - `scripts/pr-open --base main --title \"...\" --body-file ...`
  - `scripts/pr-review <PR>`
  - `scripts/pr-prepare run <PR>`
  - `scripts/pr-merge verify <PR>`

`scripts/pr-open` は `pre-pr` 証跡（PASS）とHEAD一致を検証するため、Issue実装を含むPRでは必須とする。

## 3-Lane Background Monitor

進捗監視だけ別プロセスで常駐させる場合は `scripts/lane-monitor` を使う。

1. 設定ファイルを作成する（初回のみ）。

```bash
scripts/lane-monitor init
```

2. `.local/lanes.tsv` を編集し、各レーンの `issue/pr/owner` を設定する。

```text
# lane<TAB>issue<TAB>pr<TAB>owner<TAB>note
lane1	25	31	codex-a	calendar read path
lane2	26	32	codex-b	calendar write contract
lane3	27	33	codex-c	calendar write execution
```

3. バックグラウンドで監視を起動する。

```bash
scripts/lane-monitor start --interval 60
```

4. 監視状態と最新スナップショットを確認する。

```bash
scripts/lane-monitor status
```

出力には次が含まれる。

- `tmux`: tmux を併用した場合の lane 状態（未使用時は `NO_SESSION`）
- `last_report`: lane ごとの最新 subagent report ファイル名
- `age`: 最新 report からの経過時間

5. 停止する。

```bash
scripts/lane-monitor stop
```

補足:

- フォアグラウンド確認は `scripts/lane-monitor watch`。
- 1回だけ取得する場合は `scripts/lane-monitor once`。
- `gh` が未認証でも監視は動作する（Issue/PR 列は `AUTH_ERR` または `NO_GH` 表示）。

## Issue-to-PR Background Worker

Issue 起点で「実装 -> 検証 -> PR作成」までを lane ごとにバックグラウンド実行する場合は
`scripts/lane-worker` を使う。

前提:

- `.local/lanes.tsv` に `lane / issue / pr / owner / note` を設定済み
- `codex` が使える

1. 1 lane だけ実行する。

```bash
scripts/lane-worker run lane1
```

2. すべての lane を同時実行する。

```bash
scripts/lane-worker run-all
```

3. 実行状態を確認する。

```bash
scripts/lane-worker status
```

4. lane を停止する。

```bash
scripts/lane-worker stop lane1
```

補足:

- 実行ログは `.local/lane-worker/<lane>.log` に保存される。
- `run` 完了後に `sync-pr` が自動実行され、作成済みPR番号を `.local/lanes.tsv` の `pr` 列へ反映する。
- 手動同期する場合は `scripts/lane-worker sync-pr <lane>` を使う。

## Lane Closeout

PR マージ後は lane を閉じる。

```bash
git worktree remove .worktrees/lane1
git branch -D feat/issue-25-calendar-read
```
