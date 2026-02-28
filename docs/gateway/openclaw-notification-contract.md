---
summary: "OpenClaw側が人間向け通知を行うための入力・出力契約"
read_when:
  - OpenClawで通知ワークフローを実装するとき
  - Sheets由来の結果を人間へどう伝えるか決めるとき
title: "OpenClaw Notification Contract"
---

# OpenClaw Notification Contract

## Purpose

このドキュメントは、`pixel6a-activity-monitor` から OpenClaw 側へ渡す通知コンテキストを定義する。
このリポジトリは通知送信を実行せず、OpenClaw 側が最終的な人間向け通知を担当する。

## App Summary for OpenClaw

- Pixel 6a (Termux) で位置情報を収集する。
- 収集データは Google Sheets に追記する。
- 1時間窓で活動量を判定し、判定結果JSONを更新する。
- OpenClaw 側は判定結果を読み取り、通知チャネル（Slack等）へ配信する。

## Input Contract

### Source A: Google Sheets (raw rows)

- schema:
  - `timestamp_utc`
  - `lat`
  - `lng`
  - `accuracy_m`
  - `source`
  - `device_id`
- note:
  - 生座標は OpenClaw 側の最終通知本文には直接含めない。

### Source B: Judge Output (recommended primary input)

- file: `tmp/activity-latest.json`
- schema:
  - `period_start` (ISO8601 UTC)
  - `period_end` (ISO8601 UTC)
  - `distance_m` (number)
  - `movement_level` (`low|medium|high`)
  - `event_count` (number)
  - `event_context` (JSON string)
    - fixed shape: `{"event_count":N,"top_events":[{"start_at":"...","end_at":"...","summary":"..."}],"timezone":"Asia/Tokyo"}`
    - 保存先 contract: `habit_daily_status.event_context`

## Human Message Contract

### Required fields

- 対象期間: `period_start` - `period_end`
- 活動レベル: `movement_level`
- 移動距離: `distance_m`
- 観測件数: `event_count`
- Calendar文脈: `event_context`（`top_events` は最大10件）

### Message template (plain text)

```text
Activity {movement_level}
Period: {period_start} - {period_end}
Distance: {distance_m} m
Events: {event_count}
```

### Level guidance

- `low`: 移動少なめとして通知
- `medium`: 通常活動として通知
- `high`: 活動多めとして通知

## Safety Rules

- 通知本文に `lat`, `lng`, 住所推定情報を出さない。
- token / webhook URL / secret をログ・通知本文に出さない。
- 失敗時は OpenClaw 側で再送し、重複送信防止キーを管理する。

## Operational Notes

- 本リポジトリの `openclaw/judge_notify_job.sh` は判定ジョブと障害ログ記録を担当する。
- `P6AM_NOTIFY_CMD` が未設定の場合、通知送信は OpenClaw 側管理として扱う。
- 失敗ログは `tmp/logs/*.log` の JSONL から追跡する。

## Next

- [Architecture](/concepts/architecture)
- [Google Sheets](/providers/google-sheets)
- [Slack (OpenClaw Managed)](/channels/slack)
