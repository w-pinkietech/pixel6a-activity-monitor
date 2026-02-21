---
summary: "Pixel 6a activity monitor の実装ロードマップ"
read_when:
  - 開発の全体計画を確認したいとき
  - 実装順序を見直したいとき
title: "Plan"
---

# Plan

このページは短いロードマップ。詳細な実装計画は `experiments/plans` で管理する。

- [Plans Hub](/experiments/plans/index)
- [Pixel6a Activity Monitor MVP](/experiments/plans/pixel6a-activity-monitor-mvp)
- [MVP Execution Plan](/experiments/plans/pixel6a-activity-monitor-mvp-execution)

## MVP phases

### Phase 1: Data collection

1. Termuxで1分ごとに位置情報収集
2. ローカルJSONLへ保存

### Phase 2: Data persistence

3. Google Sheetsへ追記
4. 重複防止キーで再送安全化

### Phase 3: Activity judgement

5. 1時間ごとに移動量を算出
6. 活動レベルを判定

### Phase 4: Notification

7. Slackへ定期通知
8. 失敗時リトライと障害ログ記録

## Next

- [Architecture](/concepts/architecture)
- [Cron Jobs](/automation/cron-jobs)
