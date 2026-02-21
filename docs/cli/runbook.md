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

実装後に、1イベントだけ送信して行追加を確認する。

## 4. 判定・通知手動実行

実装後に、サンプルデータで判定してSlack通知を1回送る。

## 5. ロールバック

- 自動実行を止める。
- 問題のある変更をrevertする。
- `docs/help/troubleshooting` に事象を追記する。

