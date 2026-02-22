---
summary: "症状ファーストのトラブルシューティング入口"
read_when:
  - 収集/連携/通知のどこかが動かないとき
title: "Troubleshooting"
---

# Troubleshooting

## First 60 seconds

```bash
pwd
rg --files
git status --short
```

## Decision tree

- 位置情報収集が失敗する: `termux/` の実行ログと権限を確認
- Sheets追記が失敗する: 認証情報とAPIレスポンスを確認
- 通知が来ない: cron実行ログとOpenClaw通知ワークフローログを確認
- Tailnet疎通が失敗する: 次を順番に確認
  - サーバー側: `tailscale status` と `tailscale ping "$P6AM_TAILNET_TARGET"`
  - スマホ側: 電源ONか、機内モードOFFか、Tailscale接続中か
  - 失敗時: `./openclaw/judge_notify_job.sh` を中断し、回復後に再実行する

## Next

- 運用ルールに戻る: `AGENTS.md`
- 設計方針に戻る: [Plan](/start/plan)
