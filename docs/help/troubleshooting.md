---
summary: "症状ファーストのトラブルシューティング入口"
read_when:
  - 収集/連携/通知のどこかが動かないとき
title: "Troubleshooting"
---

# Troubleshooting

Page type: troubleshooting

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
- collect + Sheets ジョブが失敗する: `openclaw/collect_sheets_job.sh` のログを確認
  - `failed_step=collect`: `openclaw/ssh_collect_job.sh` 側のエラーを確認する
  - `failed_step=sheets_append`: `GOOGLE_APPLICATION_CREDENTIALS`, `P6AM_SHEETS_ID`, `P6AM_SHEETS_RANGE` を確認する
  - `max_retries_exceeded`: `P6AM_JOB_MAX_RETRIES` と `P6AM_JOB_RETRY_SLEEP_SEC` を見直す
- collect + Sheets ジョブは成功だが行が増えない:
  - サーバー側 `data/location.jsonl` の最終時刻と、Termux 側 `~/pixel6a-activity-monitor/data/location.jsonl` の最終時刻を比較する
  - `P6AM_SYNC_LOCAL_DATA=1` で Termux 最新1行のローカル同期が有効か確認する
  - `P6AM_LOCAL_DATA_PATH` と `P6AM_DATA_PATH` が同じファイルを指しているか確認する
- SSH collector が失敗する: `openclaw/ssh_collect_job.sh` のログを確認
  - `missing_termux_host`: `P6AM_TERMUX_SSH_HOST` を設定する
  - `lock_busy`: 先行ジョブが残っている可能性があるため、`tmp/locks/ssh-collector.lock` の残存を確認する
  - `tailnet_unreachable`: `tailscale status` と `tailscale ping "$P6AM_TAILNET_TARGET"` を確認する
  - `Host key verification failed`: `P6AM_TERMUX_SSH_HOST` に設定した host 名で known_hosts を更新する（例: `ssh-keygen -R termux` -> `ssh -p 8022 u0_a569@termux true`）
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
