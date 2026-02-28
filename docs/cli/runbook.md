---
summary: "手動実行と確認のためのCLI runbook"
read_when:
  - cron導入前に手動で流れを検証したいとき
  - 障害時に切り分けしたいとき
title: "CLI Runbook"
---

# CLI Runbook

Page type: how-to

## 1. 現状確認

```bash
pwd
git status --short
rg --files docs | wc -l
```

## 2. 収集ジョブ手動実行

OpenClaw側から SSH collector を1回実行し、Termux側 `data/location.jsonl` が増えることを確認する。

```bash
P6AM_TERMUX_SSH_HOST=termux \
P6AM_TERMUX_SSH_USER=u0_a569 \
P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a \
P6AM_LOCATION_REQUEST=last \
./openclaw/ssh_collect_job.sh
```

`Host key verification failed` が出る場合は、使用する SSH host 名（例: `termux`）で一度だけ鍵登録を行う。

```bash
ssh-keygen -R termux
ssh -p 8022 u0_a569@termux true
```

## 3. Drive/Sheets 保存先プロビジョニング

初回導入または再セットアップ時に、保存先 folder / spreadsheet / header を初期化する。

```bash
P6AM_GOG_BIN=gog \
P6AM_GOG_ACCOUNT=you@example.com \
P6AM_DRIVE_PARENT_ID=root-folder-id \
P6AM_DRIVE_FOLDER_NAME=pixel6a-activity-monitor \
P6AM_SHEETS_TITLE=pixel6a-activity-monitor-raw \
./openclaw/provision_data_target.sh
```

結果は `tmp/provision-data-target.env` に保存される。読み込んで利用する。

```bash
set -a
source tmp/provision-data-target.env
set +a
```

ヘッダー確認:

```bash
gog -a you@example.com sheets get "$P6AM_SHEETS_ID" 'raw!A1:M1'
gog -a you@example.com sheets get "$P6AM_SHEETS_ID" 'conversation_log!A1:H1'
```

## 4. Sheets連携手動実行

```bash
P6AM_GOG_BIN=gog \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_RANGE='raw!A:M' \
./openclaw/sheets_append.sh
```

## 5. 判定・通知手動実行

```bash
P6AM_JUDGE_NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)" ./openclaw/activity_judge.sh
```

通知送信は OpenClaw 側で実行する。通知メッセージ仕様は `/gateway/openclaw-notification-contract` を参照。

## 6. OpenClaw cron 登録・更新

`collect-sheets` / `judge-notify` の定期実行は次のスクリプトで登録する。

```bash
P6AM_OPENCLAW_GATEWAY_URL=ws://127.0.0.1:18791 \
P6AM_OPENCLAW_GATEWAY_TOKEN=your-token \
P6AM_TERMUX_SSH_HOST=termux \
P6AM_TERMUX_SSH_USER=u0_a569 \
P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_RANGE='raw!A:M' \
P6AM_LOCATION_REQUEST=last \
P6AM_TAILNET_TARGET=google-pixel-6a \
./openclaw/register_cron_jobs.sh
```

登録結果の確認:

```bash
openclaw cron list --all --json --url ws://127.0.0.1:18791 --token your-token
```

## 7. 運用ジョブ手動実行

```bash
P6AM_TAILNET_TARGET=google-pixel-6a ./openclaw/tailnet_precheck.sh
P6AM_TERMUX_SSH_HOST=termux P6AM_TERMUX_SSH_USER=u0_a569 P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a P6AM_SHEETS_ID=sheet-id P6AM_SHEETS_RANGE='raw!A:M' P6AM_LOCATION_REQUEST=last ./openclaw/collect_sheets_job.sh
P6AM_TAILNET_TARGET=google-pixel-6a ./openclaw/judge_notify_job.sh
./openclaw/log_rotate.sh
```

## 8. ロールバック

- 自動実行を止める。
- 問題のある変更をrevertする。
- `docs/help/troubleshooting` に事象を追記する。
