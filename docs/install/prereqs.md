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
- `jq`
- `node` と `pnpm` (OpenClaw連携作業用)
- `gog` (gogcli)
- Pixel 6a + Termux
- Google Sheets API を使える Google アカウント
- OpenClaw 側で通知チャネルを設定できる環境

## Accounts and Secrets

- Google credentials JSON
- Sheets ID
- OpenClaw側の通知チャネル認証情報（このリポジトリには保存しない）

秘密情報は `.env` やOSのsecret storeで管理し、リポジトリへコミットしない。

## Verify

```bash
git --version
rg --version
jq --version
node --version
pnpm --version
gog --version
```
