---
summary: "Google Sheets追記の運用仕様"
read_when:
  - Sheets連携を実装・検証するとき
title: "Google Sheets"
---

# Google Sheets

Page type: reference

## Scope

位置情報イベントを追記形式で保存する。

## Row Schema

Sheets へは次の6列を保存する（`termux/collect_location.sh` の追加フィールドはローカルJSONLで保持し、MVPではSheetsには送らない）。

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

収集と追記を連続実行する場合:

```bash
P6AM_TERMUX_SSH_HOST=termux \
P6AM_TERMUX_SSH_USER=u0_a569 \
P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_RANGE='raw!A:F' \
P6AM_LOCATION_REQUEST=last \
./openclaw/collect_sheets_job.sh
```

## Validation

- 1回実行で1行追加される
- 同一イベント再送時は重複登録されない

## Next

- [Architecture](/concepts/architecture)
- [Troubleshooting](/help/troubleshooting)
