# Contributing

このリポジトリは次の流れで開発する。

1. Issue で課題を定義
2. Plan で設計を定義
3. PR で実装と検証を提出

詳細:

- 運用フロー: `docs/help/issue-plan-pr.md`
- subagent運用: `docs/help/agent-workflow.md`
- GitHub運用: `docs/help/repo-governance.md`
- Plan置き場: `docs/experiments/plans/`
- PRテンプレート: `.github/pull_request_template.md`
- Issueテンプレート: `.github/ISSUE_TEMPLATE/`
- DoDの正本: `docs/reference/dod.md`
- AI運用ルール: `AGENTS.md`

## PR before merge

- `git diff` を確認
- `./scripts/ci/pre-pr.sh` を実行（actでローカルCI再現）
- `./scripts/ci/pre-pr-report.sh` でレポートを生成
- 検証コマンドと結果をPRに記録
- 回帰リスクとロールバック案を記載

## PR Wrapper Commands

- レビュー初期化: `scripts/pr-review <PR>`
- 修正とGate: `scripts/pr-prepare run <PR>`
- 最終確認: `scripts/pr-merge verify <PR>`
- 実マージ: `scripts/pr-merge run <PR> --execute`
