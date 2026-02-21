---
summary: "開発開始前の前提ソフトとアカウント要件"
read_when:
  - 初回セットアップ前
  - 環境差分を確認したいとき
title: "Prerequisites"
---

# Prerequisites

## Required

- `git`
- `rg` (ripgrep)
- `node` と `pnpm` (OpenClaw連携作業用)
- Pixel 6a + Termux
- Google Sheets API を使える Google アカウント
- Slack Incoming Webhook または Bot Token

## Accounts and Secrets

- Google credentials JSON
- Sheets ID
- Slack webhook URL または token

秘密情報は `.env` やOSのsecret storeで管理し、リポジトリへコミットしない。

## Verify

```bash
git --version
rg --version
node --version
pnpm --version
```

