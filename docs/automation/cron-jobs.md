---
summary: "収集・判定ジョブのスケジュール運用"
read_when:
  - cron設定を追加・変更するとき
title: "Cron Jobs"
---

# Cron Jobs

## Jobs

- collector: every 1 minute
- judge-notify: every 1 hour
- log-rotate: once daily

## Run Order

- collector は独立実行
- judge-notify は直近1時間のデータを参照
- log-rotate は深夜帯に実行し古いログを削除

## Safety Rules

- 実行前にロック確認（多重起動防止）
- 実行前に Tailnet 到達性を確認（`tailscale status`, `tailscale ping`）
- 失敗ログを `tmp/` か運用ログに残す
- ログは機微情報を含めず、7日でローテーションする
- 手動実行コマンドを必ず用意する

## Commands (MVP)

```bash
./termux/collect_location.sh
./openclaw/judge_notify_job.sh
./openclaw/log_rotate.sh
```

## Next

- [Plan](/start/plan)
- [Troubleshooting](/help/troubleshooting)
