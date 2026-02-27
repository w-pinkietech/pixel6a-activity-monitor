---
summary: "Issue 16 完了後に judge/notify を運用化する次フェーズ計画"
owner: "wataken"
status: "draft"
last_updated: "2026-02-27"
read_when:
  - Issue 16 の次に着手する作業を決めるとき
  - OpenClaw cron と Slack 通知の運用化を進めるとき
title: "Pixel6a Activity Monitor Phase 2 Ops Plan"
---

# Pixel6a Activity Monitor Phase 2 Ops Plan

## Context

Issue 16 までで、1分間隔の `collect -> sheets append` は OpenClaw cron で実行可能になった。
次フェーズでは、`judge -> notify` を定期運用に接続し、復旧しやすい運用手順までを固める。

## Goals

- OpenClaw cron で `judge-notify` を定期実行し、運用コマンドを一本化する。
- Slack 通知（OpenClaw 側管理）への連携に必要な入力契約と実行手順を確定する。
- 収集停止や Sheets 追記停止を早期検知できる運用チェックを追加する。
- 再セットアップ時に、データ保存先（Drive フォルダ/Sheets）を短時間で再作成できるようにする。

## Non-goals

- 活動量判定ロジック自体の高度化（閾値・アルゴリズム変更）。
- 複数端末・複数ユーザー対応。
- 可視化ダッシュボード実装。

## Proposed Approach

- 「運用の再現性」を優先し、手動操作をスクリプト化する。
- cron ジョブ登録は `add` ではなく `edit` ベースで冪等更新できる設計にする。
- 通知本文は `activity-latest.json` を唯一の入力として扱い、生位置情報を通知経路に乗せない。
- 障害時は `tmp/logs/*.log` と cron runs だけで一次切り分けできる状態を目標にする。

## Implementation Plan

1. Issue 17: データ保存先（Drive フォルダ/Sheets）プロビジョニングをスクリプト化する。
2. Issue 18: OpenClaw cron 登録/更新をスクリプト化し、collect + judge の2ジョブを管理する。
3. Issue 19: OpenClaw 側 Slack 通知連携の実行手順と入力契約を固定する。
4. Issue 20: 運用監視（データ鮮度・失敗再実行・一次対応手順）を追加する。

## Issue Breakdown

### Issue 17: Data Target Provisioning

- Scope:
  - Drive 配下に収集用ディレクトリを作成する手順を標準化する。
  - 配下に raw 収集用 Spreadsheet を作成し、ヘッダーを初期化する。
  - 生成結果（folder id / sheet id / range）を運用で再利用できる形式で出力する。
- Acceptance Criteria:
  - 同じ手順で再実行しても運用が破綻しない（再実行安全）。
  - 作成されたシートに `raw!A:M` で追記可能な状態になる。
- Verification:
  - 手動検証: 作成直後に `gog sheets get <sheet-id> raw!A:M` でヘッダー確認。
  - `./scripts/ci/docs-check.sh`

### Issue 18: Cron Registration as Code

- Scope:
  - OpenClaw の `collect-sheets` / `judge-notify` ジョブを登録・更新するスクリプトを追加する。
  - `ws://127.0.0.1:18791` と token を引数/環境変数で切り替え可能にする。
  - job message の構文エラーを防ぐため、コマンド組み立てを明示化する。
- Acceptance Criteria:
  - 同一ジョブ名で再実行時に重複登録されない。
  - `openclaw cron list` で2ジョブが `enabled=true` で確認できる。
  - `openclaw cron run` で両ジョブが成功する。
- Verification:
  - 手動検証: `openclaw cron list --all --json` / `openclaw cron runs --id ...`
  - `./scripts/ci/pre-pr.sh`

### Issue 19: Judge-to-Slack Delivery Contract

- Scope:
  - `tmp/activity-latest.json` を入力にした通知コンテキストの生成ルールを固定する。
  - Slack 側へ渡す項目を `period_start`, `period_end`, `movement_level`, `distance_m`, `event_count` に限定する。
  - 通知重複防止キー（例: `period_end`）の扱いを runbook へ明記する。
- Acceptance Criteria:
  - 通知本文に `lat/lng` や secret が含まれない。
  - OpenClaw 側で通知実装時に必要な入力が docs だけで再現できる。
- Verification:
  - `./scripts/ci/docs-check.sh`
  - 可能ならステージング通知で文面確認（本番チャンネル以外）。

### Issue 20: Ops Monitoring and Runbook Hardening

- Scope:
  - 「直近 N 分でデータ行が増えているか」を確認する運用チェックを追加する。
  - 失敗キュー（Sheets retry queue）確認手順を runbook に追記する。
  - 障害時の一次対応（tailnet / ssh / sheets / notify）を優先度付きで整理する。
- Acceptance Criteria:
  - 障害発生時に 10 分以内で一次切り分け開始できる手順になっている。
  - 運用者が runbook だけで復旧コマンドに到達できる。
- Verification:
  - `./scripts/ci/docs-check.sh`
  - 手動障害シナリオで runbook 手順をトレース。

## Tests and Verification

- 共通:
  - `./scripts/ci/docs-check.sh`
  - `./scripts/ci/pre-pr.sh`
  - `./scripts/ci/pre-pr-report.sh`
- 運用確認:
  - `openclaw cron list --all --json`
  - `openclaw cron runs --id <job-id>`
  - `gog sheets get <sheet-id> 'raw!A:M'`

## Risks and Mitigations

- OpenClaw 接続先ずれ（port/token mismatch）:
  - systemd user service の実値を正として runbook に固定する。
- cron message のシェル構文ミス:
  - 登録スクリプト側で message をテンプレート化し、手書きを避ける。
- 通知経路での機微情報漏えい:
  - contract 上の許可項目を限定し、レビュー時に本文サンプルを確認する。
- 手順の属人化:
  - 作業ログではなく docs + script を Source of Truth にする。
