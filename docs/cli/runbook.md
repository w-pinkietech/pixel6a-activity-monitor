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

実装後に、Termux側収集コマンドを1回実行し、`data/` にイベントが追記されることを確認する。

## 3. Sheets連携手動実行

```bash
P6AM_SHEETS_APPEND_URL=https://example.invalid/append \
P6AM_SHEETS_ID=sheet-id \
P6AM_SHEETS_TAB=raw \
./openclaw/sheets_append.sh
```

## 4. 判定・通知手動実行

```bash
P6AM_JUDGE_NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)" ./openclaw/activity_judge.sh
P6AM_SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx/yyy/zzz ./openclaw/slack_notify.sh
```

## 5. 運用ジョブ手動実行

```bash
P6AM_TAILNET_TARGET=pixel6a ./openclaw/tailnet_precheck.sh
P6AM_TAILNET_TARGET=pixel6a ./openclaw/judge_notify_job.sh
./openclaw/log_rotate.sh
```

## 6. ロールバック

- 自動実行を止める。
- 問題のある変更をrevertする。
- `docs/help/troubleshooting` に事象を追記する。
