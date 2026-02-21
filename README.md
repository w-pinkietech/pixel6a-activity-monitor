# pixel6a-activity-monitor

Pixel 6a (Termux) の位置情報を収集し、Google Sheets に記録し、
OpenClaw の cron で活動量を判定して Slack 通知するための開発ディレクトリ。

## Structure
- `termux/` 収集スクリプト（1分ごと）
- `openclaw/` cron 用メッセージ・判定ロジック
- `docs/` 設計メモ
- `data/` ローカル保存データ（git管理外推奨）
- `tmp/` 一時ファイル
