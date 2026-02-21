---
summary: "Plan: Pixel 6a 位置情報収集から活動量通知までのMVPを実装する"
owner: "wataken"
status: "draft"
last_updated: "2026-02-21"
read_when:
  - MVP実装の着手前に方針を確認したいとき
  - 実装順序を見直したいとき
title: "Pixel6a Activity Monitor MVP Plan"
---

# Pixel6a Activity Monitor MVP Plan

## Context

Pixel 6a (Termux) の位置情報収集、Google Sheets保存、活動判定、Slack通知の一連フローを最小構成で動かす。

## Goals

- 1分間隔で位置情報を収集して保存できる。
- 収集データをGoogle Sheetsに追記できる。
- 1時間ごとに活動量を判定できる。
- 判定結果をSlackに通知できる。

## Non-goals

- 高度な移動解析アルゴリズム。
- 複数端末の同時運用。
- Web UIの完成版。

## Proposed Approach

- 収集はTermux側スクリプトに限定する。
- 判定と通知はOpenClawのcronで実行する。
- 永続化はまずGoogle Sheetsを正とする。

## Implementation Plan

1. Termux収集スクリプトの作成
2. Sheets追記スクリプトの作成
3. 活動量判定ロジックの実装
4. Slack通知テンプレート作成
5. cron運用と障害時リトライの導入

詳細な実行順序とIssue分割は
[Pixel6a Activity Monitor MVP Execution Plan](/experiments/plans/pixel6a-activity-monitor-mvp-execution)
を正本として扱う。

## Tests and Verification

- 収集スクリプト単体で位置データがJSONLに出力されること。
- Sheetsに重複なく追記されること。
- 判定ロジックがサンプルデータで期待通りになること。
- Slack通知が定期実行で届くこと。

## Risks and Mitigations

- Android側権限不備で位置取得失敗。
  - 初回セットアップ手順を明文化し、起動前チェックを入れる。
- Sheets APIエラーでデータ欠損。
  - 再送可能な一時キューを導入する。
- 通知過多。
  - 送信閾値と最小通知間隔を設定する。
