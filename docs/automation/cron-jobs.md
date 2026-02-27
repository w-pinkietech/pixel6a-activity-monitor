---
summary: "収集・判定ジョブのスケジュール運用"
read_when:
  - cron設定を追加・変更するとき
title: "Cron Jobs"
---

# Cron Jobs

## Jobs

- ssh-collector: every 1 minute (OpenClaw -> Pixel 6a Termux over SSH)
- judge-notify: every 1 hour (judge実行 + OpenClaw通知連携)
- log-rotate: once daily

## Run Order

- ssh-collector は独立実行
- judge-notify は直近1時間のデータを参照し、通知はOpenClaw側に委譲する
- log-rotate は深夜帯に実行し古いログを削除

## Safety Rules

- 実行前にロック確認（多重起動防止、`mkdir` ロック）
- 実行前に Tailnet 到達性を確認（`tailscale status`, `tailscale ping`）
- SSH collector は `timeout` でハングを打ち切る
- 失敗ログを `tmp/` か運用ログに残す
- ログは機微情報を含めず、7日でローテーションする
- 手動実行コマンドを必ず用意する

## Commands (MVP)

```bash
P6AM_TERMUX_SSH_HOST=pixel6a \
P6AM_TERMUX_SSH_USER=u0_a569 \
P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a \
P6AM_LOCATION_REQUEST=last \
./openclaw/ssh_collect_job.sh

./openclaw/judge_notify_job.sh
./openclaw/log_rotate.sh
```

## crontab Example

```cron
* * * * * cd /path/to/pixel6a-activity-monitor && P6AM_TERMUX_SSH_HOST=termux P6AM_TERMUX_SSH_USER=u0_a569 P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a P6AM_LOCATION_REQUEST=last ./openclaw/ssh_collect_job.sh >> tmp/logs/cron-ssh-collector.log 2>&1
0 * * * * cd /path/to/pixel6a-activity-monitor && P6AM_TAILNET_TARGET=pixel6a ./openclaw/judge_notify_job.sh >> tmp/logs/cron-judge-notify.log 2>&1
15 0 * * * cd /path/to/pixel6a-activity-monitor && ./openclaw/log_rotate.sh >> tmp/logs/cron-log-rotate.log 2>&1
```

## Next

- [Plan](/start/plan)
- [Troubleshooting](/help/troubleshooting)
