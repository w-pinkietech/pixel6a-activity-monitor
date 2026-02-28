# Task Todo

## Plan

- [x] Scope: `scripts/pr-prepare` の stale worktree / commit 混在起因の失敗を根本対応する。
- [x] Implementation: `scripts/pr` に clean start、prepare preflight、review基準との commit set 整合チェックを追加する。
- [x] Validation: 正常系（review->prepare->merge verify）と異常系（commit set 不整合）を確認する。

## Progress

- [x] `review-init` 実行時に PR 専用 worktree をクリーン再作成
- [x] `prepare-init` に git 進行中状態 / unresolved / tracked変更 の fail-fast を追加
- [x] review時 commit baseline と prepare時 commit set の一致確認を追加
- [x] `docs/help/repo-governance.md` に再実行ルールを追記

## Review

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
