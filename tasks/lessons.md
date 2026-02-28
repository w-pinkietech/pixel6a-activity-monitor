# Lessons

## Entry Template

- Date:
- Context:
- What went wrong:
- Preventive rule:
- How to verify next time:

## Entries

- Date: 2026-02-28
- Context: `scripts/pr-prepare` 実行で `.worktrees/pr-<N>` に rebase 残骸が残り、prepare/verify が失敗した。
- What went wrong: PR wrapper が stale worktree を再利用し、review基準と prepare実行時の commit set 整合を検証していなかった。
- Preventive rule: `scripts/pr-review` で毎回クリーン worktree を作り直し、`scripts/pr-prepare` で review時 baseline（head/commit set）との一致を必須化する。
- How to verify next time: `scripts/pr review-init <PR>` 後に commit set を改ざんすると `scripts/pr prepare-init <PR>` が fail し、再reviewを促すことを確認する。

- Date: 2026-02-28
- Context: 同一PRを対象に `scripts/pr-review` と `scripts/pr-prepare` を並列実行して検証ノイズを増やした。
- What went wrong: 同一リソース（`.worktrees/pr-<N>` と `temp/pr-<N>`）を使うコマンドを並列化した。
- Preventive rule: 同一PR番号の `scripts/pr-*` は必ず直列実行し、並列化は独立PRのみで行う。
- How to verify next time: 実行前に対象PR番号の重複がないことを確認し、ログが時系列1本で流れることを確認する。
