# Task Todo

## Plan

- [x] Scope: `scripts/lane-monitor` を廃止し、lane 運用を `lane-worker + agent-reports` に一本化する。
- [x] Implementation: `lane-worker` に config 初期化機能を追加し、関連 docs/session-open を更新する。
- [x] Validation: 構文チェック・`session-open` 実行・docs整合・3lane smoke を確認する。

## Progress

- [x] `scripts/lane-worker init [--force]` を追加して `.local/lanes.tsv` 初期化を内包
- [x] `scripts/session-open` の案内から monitor 導線を除去
- [x] `docs/tools/codex-multi-agent.md` の monitor セクションを削除し、progress check を `lane-worker + reports` に置換
- [x] `scripts/lane-monitor` を削除
- [x] 最小検証と 3lane smoke を実行

## Review

- Summary: `scripts/lane-monitor` を廃止し、lane 運用を `scripts/lane-worker` と `.local/agent-reports` に統一した。初期設定は `scripts/lane-worker init` で実行可能にした。
- Validation commands:
  - `bash -n scripts/lane-worker scripts/session-open`
  - `scripts/lane-worker init --config tmp/lanes.test.tsv --force`
  - `scripts/lane-worker status --config tmp/lanes.test.tsv`
  - `scripts/session-open | sed -n '1,240p'`
  - `./scripts/ci/docs-check.sh`
  - `./scripts/ci/test-3lane-smoke.sh --base HEAD`
  - `rg -n "lane-monitor" -S`
- Risks / rollback:
  - リスク: `scripts/lane-monitor` を直接呼ぶ既存ローカル自動化がある場合は修正が必要。
  - ロールバック: `scripts/lane-monitor` を復元し、`scripts/session-open` と `docs/tools/codex-multi-agent.md` の導線を monitor 併用へ戻す。
