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
- `P6AM_LOG_DIR` (例: `tmp/logs` または `data/logs`)
- `P6AM_LOG_RETENTION_DAYS` (例: `7`)
- `P6AM_TAILNET_TARGET` (例: `pixel6a` または tailnet内ホスト名)
- `P6AM_TAILNET_PING_TIMEOUT_SEC` (例: `5`)
- `P6AM_LOCK_DIR` (例: `tmp/locks`)
- `P6AM_JOB_MAX_RETRIES` (例: `3`)
- `P6AM_JOB_RETRY_SLEEP_SEC` (例: `2`)
- `P6AM_JUDGE_OUTPUT_PATH` (例: `tmp/activity-latest.json`)

## Google Sheets

- `GOOGLE_APPLICATION_CREDENTIALS`
- `P6AM_SHEETS_ID`
- `P6AM_SHEETS_TAB`
- `P6AM_SHEETS_APPEND_URL` (Sheets append endpoint)
- `P6AM_SHEETS_DEDUPE_DB` (例: `data/sheets-dedupe.keys`)
- `P6AM_SHEETS_RETRY_QUEUE` (例: `tmp/sheets-retry.jsonl`)

## Slack

- `P6AM_SLACK_WEBHOOK_URL` または `P6AM_SLACK_BOT_TOKEN`
- `P6AM_SLACK_CHANNEL`
- `P6AM_NOTIFY_STATE_DB` (例: `data/slack-notified.keys`)
- `P6AM_NOTIFY_RETRY_QUEUE` (例: `tmp/slack-retry.jsonl`)

## OpenClaw/Cron

- `OPENCLAW_GATEWAY_URL`
- `OPENCLAW_GATEWAY_TOKEN`

## Notes

- 環境変数は `docs/experiments/plans` の実装計画で追加理由を明記する。
- 未使用キーは削除してドリフトを防ぐ。
