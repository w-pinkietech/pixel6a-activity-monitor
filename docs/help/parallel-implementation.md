---
summary: "アプリ開発時の並列実装ルール（Issue分割・同時実装・統合順）"
read_when:
  - 複数agentで同時に実装を進めたいとき
  - 競合を減らしてPRを安全に統合したいとき
title: "Parallel Implementation"
---

# Parallel Implementation

このページは「開発運用」の並列実装ルールだけを定義する。  
プロダクト機能としての multi-agent 仕様は対象外。

Page type: reference

## Scope

- 対象: Issue分割、同時実装、PR統合
- 非対象: アプリ機能としてのsubagent/sessions_spawn設計

## Workflow

1. Plannerが `docs/experiments/plans/*.md` を更新する。
2. Issue Plannerが plan を独立Issueに分割する。
3. 各Issueを1 agent が担当し、1 Issue = 1 PRで実装する。
4. 各PRで `scripts/pr-review -> scripts/pr-prepare -> scripts/pr-merge verify` を通す。
5. 依存順にPRを統合する（独立PRは小さい順で先に統合）。

## Parallel Rules

- 同時実装の上限: 3 Issue まで（初期運用）
- 同じファイルを2 agentが同時に編集しない。
- 競合しやすい共通ファイル（`AGENTS.md`, `docs/docs.json`, `scripts/ci/*`）は専任1 agentで扱う。
- 各PRは「機能変更」と「運用/ドキュメント変更」を混ぜすぎない。

## Execution Topology

推奨実行形は次のとおり。

- 1 lane = 1 worktree = 1 branch = 1 Codex CLI
- lane 数は最大 3
- lane ごとに担当 Issue を固定する
- lane 間で同一ファイル編集を禁止する

具体手順は [Codex Multi-Agent](/tools/codex-multi-agent) を参照する。

## Branch / PR Rules

- ブランチ命名: `feat/issue-<番号>-<slug>` または `docs/issue-<番号>-<slug>`
- PR本文に必須:
  - Issue URL
  - Plan URL
  - 実行した検証コマンド
  - リスクとロールバック

## Validation Rules

- 各PRで最低限:
  - `./scripts/ci/docs-check.sh`
  - `./scripts/ci/pre-pr.sh`
- 失敗時は同一PR内で修正して再実行し、緑になるまで進めない。

## Conflict Handling

- リベースで解決できる軽微競合: 担当agentが即解消
- 仕様競合: planに戻して合意後に再実装
- 大規模競合: PRを分割して再提出

## Related

- [Issue, Plan, PR Flow](/help/issue-plan-pr)
- [Testing](/help/testing)
- [Local CI with act](/help/local-ci-with-act)
