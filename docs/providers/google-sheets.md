---
summary: "Google Sheets追記の運用仕様"
read_when:
  - Sheets連携を実装・検証するとき
title: "Google Sheets"
---

# Google Sheets

## Scope

位置情報イベントを追記形式で保存する。

## Row Schema

- `timestamp_utc` (ISO8601)
- `lat`
- `lng`
- `accuracy_m`
- `source` (`termux`)
- `device_id`

## Write Rules

- append-only
- 失敗時は指数バックオフでリトライ
- 重複防止のため `timestamp_utc + device_id` で一意性を確認

## Validation

- 1回実行で1行追加される
- 同一イベント再送時は重複登録されない

## Next

- [Architecture](/concepts/architecture)
- [Troubleshooting](/help/troubleshooting)
