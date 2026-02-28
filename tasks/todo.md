# Task Todo

## Plan

- [x] Scope: `session-open` の custom prompt 運用を skill 運用へ移行する。
- [x] Implementation: `session-open` skill を `.agents/skills/` に追加し、関連 docs を更新する。
- [x] Validation: 参照整合と最小コマンド確認（`scripts/session-open`）を行う。

## Progress

- [x] current scope を確定（custom prompt -> skill 移行）
- [x] skill を追加（`.agents/skills/session-open/`）
- [x] docs を skill 前提に更新

## Review

- Summary: `session-open` を custom prompt から skill に移行し、利用ドキュメントを `/session-open` 表記から `$session-open` 表記へ更新した。旧 `.codex/prompts/session-open.md` は削除した。
- Validation commands:
  - `scripts/session-open`
  - `./scripts/ci/docs-check.sh`
  - `rg -uu -n "session-open|prompts/session-open|/session-open|\\$session-open" -S .`
- Risks / rollback:
  - リスク: 既存運用で `/session-open` を使っている場合は呼び方変更が必要。
  - ロールバック: `.codex/prompts/session-open.md` を復元し、`docs/tools/codex-multi-agent.md` の該当節を custom prompt 記述へ戻す。
