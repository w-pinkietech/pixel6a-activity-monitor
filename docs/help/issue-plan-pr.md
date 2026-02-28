---
summary: "Issue・Plan・PR の関係と運用ルール"
read_when:
  - 開発フローを統一したいとき
  - どこに何を書くか迷ったとき
title: "Issue, Plan, PR Flow"
---

# Issue, Plan, PR Flow

このリポジトリでは、開発の流れを次で固定する。

1. Issue: 何を解くかを定義
2. Plan: どう解くかを設計
3. PR: 実装と検証を提出

## 1) Issue

- 目的、背景、完了条件を定義する。
- 1 Issue = 1トピックを原則にする。
- 仕様論点がある場合は、先に合意する。
- Issueは `.github/ISSUE_TEMPLATE/` のテンプレートを使って作成する。
- 推奨テンプレート: `feature_request.yml`, `bug_report.yml`, `chore.yml`
- `In Scope` と `Out of Scope` を明示し、実装範囲を固定する。

## 2) Plan

- `docs/experiments/plans/` に計画ファイルを作る。
- frontmatter で `owner`, `status`, `last_updated` を管理する。
- 最低限、`Goals`, `Non-goals`, `Implementation Plan`, `Tests` を書く。
- 実装が進んだら `status` を `draft` から `in-progress` に更新する。
- 完了後は `status` を `complete` に更新する。

subagentを使う場合:

- Plan作成: `planner`
- PlanからIssue分割: `issue-planning`

## 3) PR

- Planに基づいて実装する。
- Issue実装を含むPRは、実行テスト完了前に作成しない。
- PR作成は `scripts/pr-open` を使い、`pre-pr` 証跡とHEAD一致を確認してから開く。
- PR本文で対象 Issue と Plan を明示する。
- 変更の検証手順と結果を必ず残す。
- 並列運用関連の変更では `./scripts/ci/test-3lane-smoke.sh` の結果も残す。
- マージ前に回帰リスクを明示する。
- Done条件は [Definition of Done](/reference/dod) を正本として扱う。

実装フェーズでsubagentを使う場合:

- 実装: `implementer`（対応skill: `issue-implementation`）

PR向けsubagentを使う場合は、次の順で wrapper を実行する。

1. `scripts/pr-review <PR>`
2. `scripts/pr-prepare run <PR>`
3. `scripts/pr-merge verify <PR>`

実マージは最終確認後に明示的に実行する。

- `scripts/pr-merge run <PR> --execute`

## Link Rules

PRテンプレートに次を含める。

- Issue URL
- Plan URL
- 検証コマンド
- リスクとロールバック
- `pre-pr-report` の結果
