---
summary: "収集・判定ジョブのスケジュール運用"
read_when:
  - cron設定を追加・変更するとき
title: "Cron Jobs"
---

# Cron Jobs

Page type: reference

## Jobs

- collect-sheets: every 1 minute (OpenClaw -> Pixel 6a Termux over SSH -> Google Sheets append)
- judge-notify: every 1 hour (judge実行 + OpenClaw通知連携)
- log-rotate: once daily

## Run Order

- collect-sheets は `ssh_collect_job.sh` と `sheets_append.sh` を順に実行する
- judge-notify は直近1時間のデータを参照し、通知はOpenClaw側に委譲する
- log-rotate は深夜帯に実行し古いログを削除

## Safety Rules

- 実行前にロック確認（多重起動防止、`mkdir` ロック）
- 実行前に Tailnet 到達性を確認（`tailscale status`, `tailscale ping`）
- SSH collector は `timeout` でハングを打ち切る
- Sheets追記は dedupe と retry queue で再実行安全性を担保する
- 失敗ログを `tmp/` か運用ログに残す
- ログは機微情報を含めず、7日でローテーションする
- 手動実行コマンドを必ず用意する

## Commands (MVP)

```bash
P6AM_TERMUX_SSH_HOST=termux \
P6AM_TERMUX_SSH_USER=u0_a569 \
P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_RANGE='raw!A:M' \
P6AM_LOCATION_REQUEST=last \
./openclaw/collect_sheets_job.sh

P6AM_TAILNET_TARGET=google-pixel-6a ./openclaw/judge_notify_job.sh
./openclaw/log_rotate.sh
```

補足:
- `P6AM_TERMUX_SSH_HOST` は SSH で接続できる host 名または IP を指定する。
- `P6AM_TERMUX_TAILNET_TARGET` / `P6AM_TAILNET_TARGET` は `tailscale status` に表示される実ノード名またはIPに合わせる。
- `P6AM_SHEETS_ID` / `P6AM_SHEETS_RANGE` は事前に設定する（認証は `GOOGLE_APPLICATION_CREDENTIALS` を利用）。

## OpenClaw Cron Registration as Code

`collect-sheets` / `judge-notify` の登録・更新は手書きせず、次のスクリプトで管理する。

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

確認:

```bash
openclaw cron list --all --json \
  --url ws://127.0.0.1:18791 \
  --token your-token
```

補足:
- 再実行時は同名ジョブを重複作成せず、`cron edit` で更新する。
- `--collect-cron` / `--judge-cron` でスケジュールを上書きできる。
- job message はスクリプト内テンプレートで生成され、手書きの構文ミスを防ぐ。

## crontab Example

```cron
* * * * * cd /path/to/pixel6a-activity-monitor && P6AM_TERMUX_SSH_HOST=termux P6AM_TERMUX_SSH_USER=u0_a569 P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a P6AM_SHEETS_ID=sheet-id P6AM_SHEETS_RANGE='raw!A:M' P6AM_LOCATION_REQUEST=last ./openclaw/collect_sheets_job.sh >> tmp/logs/cron-collect-sheets.log 2>&1
0 * * * * cd /path/to/pixel6a-activity-monitor && P6AM_TAILNET_TARGET=google-pixel-6a ./openclaw/judge_notify_job.sh >> tmp/logs/cron-judge-notify.log 2>&1
15 0 * * * cd /path/to/pixel6a-activity-monitor && ./openclaw/log_rotate.sh >> tmp/logs/cron-log-rotate.log 2>&1
```

## Next

- [Plan](/start/plan)
- [Troubleshooting](/help/troubleshooting)
