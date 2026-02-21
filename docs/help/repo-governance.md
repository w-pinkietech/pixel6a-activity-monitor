---
summary: "ブランチ、PR、ラベル、マイルストーンの運用ルール"
read_when:
  - GitHub運用ルールを確認したいとき
  - Issue/PRの命名や分類を決めるとき
title: "Repository Governance"
---

# Repository Governance

このページは GitHub 運用の最小ルールを定義する。

## Branch Rules

- `main` へ直接pushしない
- 1 Issue = 1 ブランチ = 1 PR
- ブランチ命名:
  - `feat/issue-<番号>-<slug>`
  - `fix/issue-<番号>-<slug>`
  - `docs/issue-<番号>-<slug>`

## PR Rules

- `.github/pull_request_template.md` を埋める
- Issue と Plan のリンクを必須にする
- `scripts/ci/pre-pr.sh` を通してからPR作成する
- `scripts/ci/pre-pr-report.sh` の内容をPR本文に貼る
- `scripts/pr-merge verify <PR>` の required checks 厳密判定を通す（0件や非passは不可）

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
