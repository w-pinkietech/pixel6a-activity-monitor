# Task Todo

## Plan

- [x] Scope: Plan合意後の「AI自走（PR作成まで）」を実現するため、Plan定義を実行契約として強化する。
- [x] Implementation: plan template / planner skill / workflow docs を更新し、停止条件と検証マトリクスを明文化する。
- [x] Validation: docs-check で整合を確認し、更新内容をレビューに記録する。
- [x] Scope: `scripts/pr-prepare` の stale worktree / commit 混在起因の失敗を根本対応する。
- [x] Implementation: `scripts/pr` に clean start、prepare preflight、review基準との commit set 整合チェックを追加する。
- [x] Validation: 正常系（review->prepare->merge verify）と異常系（commit set 不整合）を確認する。
- [x] Scope: `pr_reviewer` 以降を background で自走させる運用を docs/skills で明文化する。
- [x] Implementation: `AGENTS.md` / `docs/help/agent-workflow.md` / `docs/tools/codex-multi-agent.md` / `.agents/skills/review-pr/SKILL.md` / `.agents/skills/README.md` を更新する。
- [x] Validation: docs-check と参照整合確認を実施する。

## Progress

- [x] 影響範囲を確認（`docs/experiments/plans/template.md`, `.agents/skills/planner/SKILL.md`, `docs/help/workflow-design.md`, `docs/help/issue-plan-pr.md`
- [x] 実装と検証を実施
- [x] `review-init` 実行時に PR 専用 worktree をクリーン再作成
- [x] `prepare-init` に git 進行中状態 / unresolved / tracked変更 の fail-fast を追加
- [x] review時 commit baseline と prepare時 commit set の一致確認を追加
- [x] `docs/help/repo-governance.md` に再実行ルールを追記
- [x] 現行記述を確認し、暗黙だった運用（完了時通知・停止条件時のみ介入）を抽出
- [x] docs/skills へ追記
- [x] 検証実行と review 追記

## Review

### Plan Contract

- Summary: Planを「実行契約」として強化し、`Decision Log` / `Autonomy Contract` / `Verification Matrix` を template と planner skill と運用docsへ横断反映した。これにより、Plan合意後は停止条件に該当しない限り AI が PR 作成まで自走できる前提を明文化した。
- Validation commands:
  - `./scripts/ci/docs-check.sh`
  - `rg -n "Decision Log|Autonomy Contract|Verification Matrix|例外時のみ人間介入" docs/experiments/plans/template.md docs/help/workflow-design.md docs/help/issue-plan-pr.md .agents/skills/planner/SKILL.md`
- Risks / rollback:
  - リスク: 既存Planが新規必須項目を満たさない場合、運用移行時に追記負荷が発生する。
  - ロールバック: 追加した必須項目定義を `template.md` と `planner/SKILL.md` と運用docsから戻し、従来の最小セクション運用へ戻す。

### PR46 Review

- Summary: `scripts/pr-review` と `scripts/pr-prepare` を stale 状態に依存しない実行モデルへ更新し、review時点から PR head/commit set が変化した場合は明示的に停止するようにした。
- Validation commands:
  - `bash -n scripts/pr scripts/pr-review scripts/pr-prepare`
  - `./scripts/ci/docs-check.sh`
  - `scripts/pr review-init 40`
  - `scripts/pr prepare-init 40`
  - `printf 'bogus-sha\n' >> /home/wataken/pixel6a-activity-monitor/.worktrees/pr-40/.local/review-commits.txt && scripts/pr prepare-init 40`（想定どおり fail）
  - `scripts/pr review-init 40 && scripts/pr prepare-run 40`
  - `scripts/pr merge-verify 40`
- Risks / rollback:
  - リスク: review後に PR head が更新された場合、prepare は意図的に fail し、review再実行が必須になる。
  - ロールバック: `scripts/pr` の commit baseline 検証と clean start ロジックを戻し、従来の再利用フローへ復帰する。

### Background PR Ops Docs

- Summary: `pr_reviewer` 以降の PR工程を background terminal の直列自走として運用定義へ反映し、介入タイミングを「停止条件ヒット時」と「実マージ依頼時」に限定した。これにより、人間は Plan/仕様検討に集中しつつ、PR工程はサブエージェントに継続実行させられる。
- Validation commands:
  - `./scripts/ci/docs-check.sh`
  - `rg -n "background terminal|停止条件|直列実行|pr_reviewer|pr_preparer|pr_merger" AGENTS.md docs/help/agent-workflow.md docs/tools/codex-multi-agent.md .agents/skills/review-pr/SKILL.md .agents/skills/README.md .agents/skills/PR_WORKFLOW.md -S`
- Risks / rollback:
  - リスク: 途中承認前提で運用しているメンバーには、通知タイミング変更（完了/停止条件のみ）の周知が必要。
  - ロールバック: 本タスクで追加した background 直列自走と停止条件限定の記述を削除し、従来の逐次確認運用へ戻す。
