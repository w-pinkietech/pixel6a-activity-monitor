---
summary: "Slack通知の運用仕様"
read_when:
  - 活動量通知を実装・調整するとき
title: "Slack"
---

# Slack

## Scope

1時間ごとの活動量判定結果を通知する。

## Message Contract

- `period_start`
- `period_end`
- `distance_m`
- `movement_level` (`low|medium|high`)
- `event_count`

## Delivery Rules

- 通知先チャネルは環境変数で指定
- 送信失敗時は再試行
- 連続失敗時はエラーログへ記録

## Next

- [Automation / Cron Jobs](/automation/cron-jobs)
- [Troubleshooting](/help/troubleshooting)
