---
summary: "Slack通知（OpenClaw運用）の連携仕様"
read_when:
  - OpenClaw側の通知メッセージ仕様を確認したいとき
title: "Slack (OpenClaw Managed)"
---

# Slack (OpenClaw Managed)

## Scope

このリポジトリはSlack送信を直接実行しない。
通知は OpenClaw 側で運用し、本リポジトリは通知に必要なデータ契約を提供する。

## Message Contract (Input)

- source: `tmp/activity-latest.json`（`openclaw/activity_judge.sh` 出力）
- fields:
  - `period_start`
  - `period_end`
  - `distance_m`
  - `movement_level` (`low|medium|high`)
  - `event_count`

## Delivery Rules (OpenClaw Side)

- 通知先チャネル管理、再送制御、最終送信は OpenClaw 側で実施する。
- 本リポジトリ側は `openclaw/judge_notify_job.sh` で判定ジョブと障害ログを管理する。
- 失敗ログには `failed_step` と `detail` を記録し、切り分け可能にする。

## Human Message Rules

- 人間向け通知は「期間」「活動レベル」「移動距離」「イベント数」を必須にする。
- 生の位置情報（`lat`,`lng`）は通知本文に出さない。
- メッセージの詳細テンプレートは [OpenClaw Notification Contract](/gateway/openclaw-notification-contract) を正本にする。

## Next

- [Automation / Cron Jobs](/automation/cron-jobs)
- [OpenClaw Notification Contract](/gateway/openclaw-notification-contract)
- [Troubleshooting](/help/troubleshooting)
