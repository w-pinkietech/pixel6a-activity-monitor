# pixel6a-activity-monitor

Pixel 6a (Termux) の位置情報を収集し、Google Sheets に記録し、
OpenClaw の cron で活動量を判定して Slack 通知するための開発ディレクトリ。

- Vision: `VISION.md`

## Structure
- `termux/` 収集スクリプト（1分ごと）
- `openclaw/` cron 用メッセージ・判定ロジック
- `docs/` OpenClaw準拠のドキュメント構成（`start/`, `concepts/`, `help/`, `experiments/plans/`, `reference/` など）
- `data/` ローカル保存データ（git管理外推奨）
- `tmp/` 一時ファイル

## Development Flow

Issue -> Plan -> PR を標準フローにする。

- Flow: `docs/help/issue-plan-pr.md`
- Plan docs: `docs/experiments/plans/`
- PR template: `.github/pull_request_template.md`
