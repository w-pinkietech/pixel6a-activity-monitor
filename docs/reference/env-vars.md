---
summary: "このプロジェクトで使う環境変数の基準"
read_when:
  - 新しい実行スクリプトを書くとき
  - 設定値の命名を揃えたいとき
title: "Environment Variables"
---

# Environment Variables

Page type: reference

## Naming Rules

- プロジェクト固有は `P6AM_` プレフィックスを使う。
- 外部サービス標準キーは既存名を維持する。

## Core Keys

- `P6AM_DEVICE_ID` (例: `pixel6a`)
- `P6AM_TZ` (例: `Asia/Tokyo`)
- `P6AM_DATA_PATH` (例: `data/location.jsonl`)
- `P6AM_LOCATION_PROVIDER` (default: `gps`)
- `P6AM_LOCATION_REQUEST` (default: `once`, `once|last|updates`)
- `P6AM_SMOKE_SAMPLE_COUNT` (default: `3`)
- `P6AM_SMOKE_INTERVAL_SEC` (default: `10`)
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
- `P6AM_GOG_BIN` (default: `gog`)
- `P6AM_GOG_ACCOUNT` (例: `you@example.com`, `gog` のAPI実行アカウント)
- `P6AM_SHEETS_ID`
- `P6AM_SHEETS_TAB`
- `P6AM_SHEETS_RANGE` (例: `raw!A:M`)
- `P6AM_SHEETS_INSERT_MODE` (default: `INSERT_ROWS`)
- `P6AM_SHEETS_DEDUPE_DB` (例: `data/sheets-dedupe.keys`)
- `P6AM_SHEETS_RETRY_QUEUE` (例: `tmp/sheets-retry.jsonl`)
- `P6AM_DRIVE_PARENT_ID` (任意: 保存先フォルダの親フォルダID)
- `P6AM_DRIVE_FOLDER_NAME` (default: `pixel6a-activity-monitor`)
- `P6AM_SHEETS_TITLE` (default: `pixel6a-activity-monitor-raw`)
- `P6AM_CONVERSATION_RANGE` (default: `conversation_log!A:H`)
- `P6AM_PROVISION_OUTPUT_PATH` (default: `tmp/provision-data-target.env`)

## OpenClaw/Cron

- `OPENCLAW_GATEWAY_URL`
- `OPENCLAW_GATEWAY_TOKEN`
- `P6AM_TAILNET_CHECK_CMD` (例: `openclaw/tailnet_precheck.sh`)
- `P6AM_JUDGE_CMD` (例: `openclaw/activity_judge.sh`)
- `P6AM_NOTIFY_CMD` (未設定時はOpenClaw側で通知運用する)
- `P6AM_TERMUX_SSH_HOST` (例: `pixel6a` または `100.76.x.x`)
- `P6AM_TERMUX_SSH_USER` (例: `u0_a569`)
- `P6AM_TERMUX_SSH_PORT` (default: `8022`)
- `P6AM_TERMUX_TAILNET_TARGET` (任意: SSH alias と tailnet 名が異なるときに指定)
- `P6AM_TERMUX_COLLECTOR_CMD` (default: `cd ~/pixel6a-activity-monitor && ./termux/collect_location.sh`)
- `P6AM_SSH_BIN` (default: `ssh`)
- `P6AM_TIMEOUT_BIN` (default: `timeout`)
- `P6AM_SSH_CONNECT_TIMEOUT_SEC` (default: `10`)
- `P6AM_COLLECT_TIMEOUT_SEC` (default: `45`)
- `P6AM_SYNC_LOCAL_DATA` (default: `1`, `ssh_collect_job.sh` 実行後に Termux 最新1行をローカルへ同期)
- `P6AM_LOCAL_DATA_PATH` (default: `data/location.jsonl`, 同期先のローカルJSONL)
- `P6AM_TERMUX_DATA_PATH` (default: `~/pixel6a-activity-monitor/data/location.jsonl`, 同期元のTermux JSONL)
- `P6AM_SYNC_TIMEOUT_SEC` (default: `15`)
- `P6AM_COLLECT_CMD` (default: `openclaw/ssh_collect_job.sh`, `collect_sheets_job.sh` から呼ぶ収集ジョブ)
- `P6AM_SHEETS_APPEND_CMD` (default: `openclaw/sheets_append.sh`, `collect_sheets_job.sh` から呼ぶ追記ジョブ)

## Notes

- 環境変数は `docs/experiments/plans` の実装計画で追加理由を明記する。
- 未使用キーは削除してドリフトを防ぐ。
