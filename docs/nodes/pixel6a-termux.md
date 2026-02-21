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

## Output Example

```json
{"timestamp_utc":"2026-02-21T06:30:00Z","lat":35.0,"lng":139.0,"accuracy_m":12.0,"source":"termux","device_id":"pixel6a"}
```

## Next

- [Google Sheets](/providers/google-sheets)
- [Troubleshooting](/help/troubleshooting)
