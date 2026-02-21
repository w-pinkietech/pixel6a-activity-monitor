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
- 通知が来ない: cron実行ログとSlack送信ログを確認

## Next

- 運用ルールに戻る: `AGENTS.md`
- 設計方針に戻る: [Plan](/start/plan)
