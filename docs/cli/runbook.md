---
summary: "手動実行と確認のためのCLI runbook"
read_when:
  - cron導入前に手動で流れを検証したいとき
  - 障害時に切り分けしたいとき
title: "CLI Runbook"
---

# CLI Runbook

## 1. 現状確認

```bash
pwd
git status --short
rg --files docs | wc -l
```

## 2. 収集ジョブ手動実行

OpenClaw側から SSH collector を1回実行し、Termux側 `data/location.jsonl` が増えることを確認する。

```bash
P6AM_TERMUX_SSH_HOST=pixel6a \
P6AM_TERMUX_SSH_USER=u0_a569 \
P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a \
P6AM_LOCATION_REQUEST=last \
./openclaw/ssh_collect_job.sh
```

## 3. Sheets連携手動実行

```bash
P6AM_GOG_BIN=gog \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_RANGE='raw!A:F' \
./openclaw/sheets_append.sh
```

## 4. 判定・通知手動実行

```bash
P6AM_JUDGE_NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)" ./openclaw/activity_judge.sh
```

通知送信は OpenClaw 側で実行する。通知メッセージ仕様は `/gateway/openclaw-notification-contract` を参照。

## 5. 運用ジョブ手動実行

```bash
P6AM_TAILNET_TARGET=pixel6a ./openclaw/tailnet_precheck.sh
P6AM_TERMUX_SSH_HOST=termux P6AM_TERMUX_SSH_USER=u0_a569 P6AM_TERMUX_TAILNET_TARGET=google-pixel-6a P6AM_LOCATION_REQUEST=last ./openclaw/ssh_collect_job.sh
P6AM_TAILNET_TARGET=pixel6a ./openclaw/judge_notify_job.sh
./openclaw/log_rotate.sh
```

## 6. ロールバック

- 自動実行を止める。
- 問題のある変更をrevertする。
- `docs/help/troubleshooting` に事象を追記する。
