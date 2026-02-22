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

## Implementation (MVP)

実装ファイル: `openclaw/sheets_append.sh`

- 入力: `P6AM_DATA_PATH` のJSONL
- 実行: `gog sheets append`
- 範囲: `P6AM_SHEETS_RANGE`（未指定時は `P6AM_SHEETS_TAB` から `tab!A:F` を自動生成）
- 重複管理: `P6AM_SHEETS_DEDUPE_DB`
- 失敗キュー: `P6AM_SHEETS_RETRY_QUEUE`

```bash
P6AM_GOG_BIN=gog \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_RANGE='raw!A:F' \
./openclaw/sheets_append.sh
```

## Validation

- 1回実行で1行追加される
- 同一イベント再送時は重複登録されない

## Next

- [Architecture](/concepts/architecture)
- [Troubleshooting](/help/troubleshooting)
