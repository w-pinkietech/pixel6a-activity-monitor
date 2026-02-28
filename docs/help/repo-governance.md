---
summary: "ブランチ、PR、ラベル、マイルストーンの運用ルール"
read_when:
  - GitHub運用ルールを確認したいとき
  - Issue/PRの命名や分類を決めるとき
title: "Repository Governance"
---

# Repository Governance

このページは GitHub 運用の最小ルールを定義する。

Page type: reference

## Branch Rules

- `main` へ直接pushしない
- 1 Issue = 1 ブランチ = 1 PR
- ブランチ命名:
  - `feat/issue-<番号>-<slug>`
  - `fix/issue-<番号>-<slug>`
  - `docs/issue-<番号>-<slug>`
- 並列実装時は lane ごとに worktree を分離する（例: `.worktrees/lane1`）。
- 1 lane で同時に複数 Issue を持たない。

## PR Rules

- `.github/pull_request_template.md` を埋める
- Issue と Plan のリンクを必須にする
- `scripts/ci/pre-pr.sh` を通してからPR作成する（`act` スキップ時は理由を明記）
- `scripts/ci/pre-pr-report.sh` の内容をPR本文に貼る
- PR作成は `scripts/pr-open` を使い、`pre-pr` 証跡とHEAD一致を検証してから実行する
- 並列運用関連の変更では `./scripts/ci/test-3lane-smoke.sh` を実行し、結果をPRに記録する
- `scripts/pr-merge verify <PR>` の required checks 厳密判定を通す（0件や非passは不可）

## GitHub CLI Rules

- Issue/PR 操作前に `gh auth status` を実行し、token 有効性を確認する。
- token 無効時は `gh auth login -h github.com -p ssh -w` で再認証する。
- Codex 実行時に `gh` コマンドが接続失敗した場合は、実行コンテキストを切り分け、ネットワーク到達可能な環境で再実行する。
- PR 操作は `gh pr *` 直実行より `scripts/pr-*` wrapper を優先する。

## Label Rules

ラベル定義は `.github/labels.yml` を正本にする。

- 種別: `type:*`
- 状態: `status:*`
- 優先度: `priority:*`
- 同期は現時点では手動運用（必要時に `gh label` で更新）
- PRへの自動付与ルールは `.github/labeler.yml` と `.github/workflows/labeler.yml` で管理する。

## Milestone Rules

- マイルストーン名は `YYYY-MM sprint-N` 形式を推奨
- 1 マイルストーンに複数Issueを束ねる
- 完了時に振り返りを Plan または PR に残す

## Ownership Rules

- 所有者ルールは `.github/CODEOWNERS` を正本にする
- 共通運用ファイルのレビューは owner を必須化する

## Related

- [Issue, Plan, PR Flow](/help/issue-plan-pr)
- [Definition of Done](/reference/dod)
