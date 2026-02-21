---
summary: "このプロジェクトで使う環境変数の基準"
read_when:
  - 新しい実行スクリプトを書くとき
  - 設定値の命名を揃えたいとき
title: "Environment Variables"
---

# Environment Variables

## Naming Rules

- プロジェクト固有は `P6AM_` プレフィックスを使う。
- 外部サービス標準キーは既存名を維持する。

## Core Keys

- `P6AM_DEVICE_ID` (例: `pixel6a`)
- `P6AM_TZ` (例: `Asia/Tokyo`)
- `P6AM_DATA_PATH` (例: `data/location.jsonl`)
- `P6AM_LOG_LEVEL` (`debug|info|warn|error`)

## Google Sheets

- `GOOGLE_APPLICATION_CREDENTIALS`
- `P6AM_SHEETS_ID`
- `P6AM_SHEETS_TAB`

## Slack

- `P6AM_SLACK_WEBHOOK_URL` または `P6AM_SLACK_BOT_TOKEN`
- `P6AM_SLACK_CHANNEL`

## OpenClaw/Cron

- `OPENCLAW_GATEWAY_URL`
- `OPENCLAW_GATEWAY_TOKEN`

## Notes

- 環境変数は `docs/experiments/plans` の実装計画で追加理由を明記する。
- 未使用キーは削除してドリフトを防ぐ。

