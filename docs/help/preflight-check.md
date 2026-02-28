---
summary: "作業開始前の共通チェックリスト"
read_when:
  - 新しいIssueに着手するとき
  - PR作成前に抜け漏れを防ぎたいとき
title: "Preflight Check"
---

# Preflight Check

## Before starting

- 対象Issueと完了条件が明確
- 関連Planの有無を確認
- 影響範囲のdocsを特定

## Before GitHub operations (Issue/PR)

- `gh auth status` が成功することを確認する。
- token 無効時は次を実行して再認証する。

```bash
gh auth logout -h github.com -u cycling777
gh auth login -h github.com -p ssh -w
gh auth status
```

- `gh issue create` / `gh issue comment` / `gh pr *` などのネットワーク必須操作は、Codex 実行時に sandbox 制約で失敗する場合がある。
- 失敗時は実行コンテキストを切り分け、ネットワーク到達可能な環境で再実行する。

## Before opening PR

- `git diff` を確認
- `./scripts/ci/pre-pr.sh` と `./scripts/ci/pre-pr-report.sh` を実行済みにする
- `scripts/pr-open` で PR作成前チェック（`pre-pr` 証跡 + HEAD一致）を通す
- 検証コマンドと結果を記録
- 回帰リスクとロールバック手順を記載
- 機密情報の混入がないことを確認

## Links

- [Issue, Plan, PR Flow](/help/issue-plan-pr)
- [CLI Runbook](/cli/runbook)
- [Environment Variables](/reference/env-vars)
