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
  - `termux-location command not found`: Termux:API アプリ導入後、Termux で `pkg install termux-api`
  - `location payload missing latitude/longitude`: Android側の位置情報権限と GPS 有効化を確認
- SSH collector が失敗する: `openclaw/ssh_collect_job.sh` のログを確認
  - `missing_termux_host`: `P6AM_TERMUX_SSH_HOST` を設定する
  - `lock_busy`: 先行ジョブが残っている可能性があるため、`tmp/locks/ssh-collector.lock` の残存を確認する
  - `tailnet_unreachable`: `tailscale status` と `tailscale ping "$P6AM_TAILNET_TARGET"` を確認する
  - SSH alias（例: `termux`）を使う場合、`P6AM_TERMUX_TAILNET_TARGET` を実際の tailnet 名/IP に設定する
  - `max_retries_exceeded`: `P6AM_COLLECT_TIMEOUT_SEC` の延長、または `P6AM_LOCATION_REQUEST=last` の設定を確認する
- Sheets追記が失敗する: 認証情報とAPIレスポンスを確認
- 通知が来ない: cron実行ログとOpenClaw通知ワークフローログを確認
- Tailnet疎通が失敗する: 次を順番に確認
  - サーバー側: `tailscale status` と `tailscale ping "$P6AM_TAILNET_TARGET"`
  - スマホ側: 電源ONか、機内モードOFFか、Tailscale接続中か
  - 失敗時: `./openclaw/judge_notify_job.sh` を中断し、回復後に再実行する

## Next

- 運用ルールに戻る: `AGENTS.md`
- 設計方針に戻る: [Plan](/start/plan)
