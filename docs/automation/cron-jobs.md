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

## Run Order

- collector は独立実行
- judge-notify は直近1時間のデータを参照

## Safety Rules

- 実行前にロック確認（多重起動防止）
- 失敗ログを `tmp/` か運用ログに残す
- 手動実行コマンドを必ず用意する

## Next

- [Plan](/start/plan)
- [Troubleshooting](/help/troubleshooting)
