---
summary: "Pixel 6a (Termux) 実機で位置情報を収集する手順"
read_when:
  - 端末収集スクリプトを実装するとき
  - 端末側トラブルを調査するとき
title: "Pixel 6a (Termux)"
---

# Pixel 6a (Termux)

Page type: how-to

## Goal

Pixel 6a (Termux) で実機位置情報を収集し、`data/location.jsonl` に記録できる状態まで到達する。

## Prereqs

- [Prerequisites](/install/prereqs) の Required が満たされている。
- Pixel 6a で Termux と Termux:API がインストール済み。
- Android 設定で Termux に位置情報権限が付与されている。

## Steps

### 1. Termux API を確認する

```bash
command -v termux-location
termux-location -p gps
```

`termux-location` が見つからない場合は、Termux で `pkg install termux-api` を実行する。

### 2. 1件収集する（単発）

```bash
cd /path/to/pixel6a-activity-monitor
P6AM_DEVICE_ID=pixel6a \
P6AM_DATA_PATH=data/location.jsonl \
./termux/collect_location.sh
```

実装ファイル: `termux/collect_location.sh`

補足:
- SSH 経由で `once` が待機し続ける場合は `P6AM_LOCATION_REQUEST=last` を指定して last known location を使う。

### 3. 複数件収集する（スモーク）

```bash
cd /path/to/pixel6a-activity-monitor
P6AM_DEVICE_ID=pixel6a \
P6AM_DATA_PATH=data/location.jsonl \
P6AM_LOCATION_REQUEST=last \
P6AM_SMOKE_SAMPLE_COUNT=5 \
P6AM_SMOKE_INTERVAL_SEC=10 \
./termux/collect_smoke.sh
```

実装ファイル: `termux/collect_smoke.sh`

## Validation

収集件数の確認:

```bash
wc -l data/location.jsonl
```

最新3件の構造確認（緯度経度は表示しない）:

```bash
tail -n 3 data/location.jsonl \
  | jq -c '{timestamp_utc, accuracy_m, vertical_accuracy_m, bearing_deg, speed_mps, provider, source, device_id, has_lat: (.lat != null), has_lng: (.lng != null), has_altitude: (.altitude_m != null), has_elapsed: (.elapsed_ms != null)}'
```

期待結果:
- `timestamp_utc`, `source`, `device_id` が存在する。
- `has_lat`, `has_lng` が `true` になる。
- `has_altitude`, `has_elapsed` が `true` になる。
- スクリプト標準出力に生の緯度経度が出ない。

## Output Example

`collect_location.sh` の1行出力例:

```json
{"timestamp_utc":"2026-02-21T06:30:00Z","lat":35.0,"lng":139.0,"altitude_m":44.2,"accuracy_m":12.0,"vertical_accuracy_m":18.4,"bearing_deg":123.5,"speed_mps":0.8,"elapsed_ms":2450,"provider":"gps","source":"termux","device_id":"pixel6a"}
```

補足:
- テスト時は `P6AM_FORCE_LOCATION_JSON` でモック payload を渡せる。
- `data/` は Git 管理外運用を前提とする。

## Next

- [Google Sheets](/providers/google-sheets)
- [Troubleshooting](/help/troubleshooting)
