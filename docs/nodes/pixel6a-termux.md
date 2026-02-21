---
summary: "Pixel 6a (Termux) 側の収集要件"
read_when:
  - 端末収集スクリプトを実装するとき
  - 端末側トラブルを調査するとき
title: "Pixel 6a (Termux)"
---

# Pixel 6a (Termux)

## Scope

Termux上で位置情報を1分周期で取得する。

## Requirements

- 位置情報権限が付与されている
- 収集結果をJSONLで出力する
- タイムスタンプはUTCで記録する

## Collector Script

実装ファイル: `termux/collect_location.sh`

```bash
P6AM_DEVICE_ID=pixel6a \
P6AM_DATA_PATH=data/location.jsonl \
./termux/collect_location.sh
```

補足:

- `termux-location -p gps` を呼び出して位置情報を取得する。
- 標準出力には時刻のみ出し、緯度経度はログに出さない。
- テスト時は `P6AM_FORCE_LOCATION_JSON` でモックpayloadを渡せる。

## Output Example

```json
{"timestamp_utc":"2026-02-21T06:30:00Z","lat":35.0,"lng":139.0,"accuracy_m":12.0,"source":"termux","device_id":"pixel6a"}
```

## Next

- [Google Sheets](/providers/google-sheets)
- [Troubleshooting](/help/troubleshooting)
