---
summary: "Pixel 6a activity monitor の基本アーキテクチャ"
read_when:
  - 実装前に全体構成を確認したいとき
  - どこで失敗しうるかを整理したいとき
title: "Architecture"
---

# Architecture

## Scope

対象フロー:

1. Pixel 6a (Termux) で位置情報収集
2. ローカル一時保存
3. Google Sheets へ追記
4. 1時間単位で活動量判定
5. Slack 通知

## Data Flow

```text
Pixel6a/Termux -> local JSONL -> Google Sheets -> activity judge -> Slack
```

## Design Constraints

- 収集ジョブは1分周期
- 判定ジョブは1時間周期
- 同一データの重複書き込みを避ける
- 障害時に再実行できること

## Failure Points

- 端末側権限不足（位置情報取得失敗）
- Google API認証エラー
- Sheetsレート制限
- Slack API送信失敗

## Next

- [Plan](/start/plan)
- [Pixel 6a (Termux)](/nodes/pixel6a-termux)
- [Google Sheets](/providers/google-sheets)
- [Slack](/channels/slack)
