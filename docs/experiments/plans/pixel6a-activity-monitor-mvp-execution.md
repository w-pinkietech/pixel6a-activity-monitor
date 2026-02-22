---
summary: "Pixel6a Activity Monitor MVP の実装順序・Issue分割・検証基準を定義する実行Plan"
owner: "wataken"
status: "in-progress"
last_updated: "2026-02-22"
read_when:
  - MVPをIssue分割して着手するとき
  - 実装順序と受け入れ条件を確認したいとき
title: "Pixel6a Activity Monitor MVP Execution Plan"
---

# Pixel6a Activity Monitor MVP Execution Plan

## Context

MVPの大枠Planは存在するが、実装に入るための Issue 粒度と受け入れ条件が不足している。
本Planで `Issue -> 実装 -> 検証 -> PR` の単位を固定する。

## Goals

- MVPを5つの実装Issueへ分割し、依存関係を明示する。
- 各Issueに受け入れ条件と最小検証コマンドを定義する。
- PR前ゲートとDone条件を一貫運用できる状態にする。
- OpenClaw側通知運用のためのメッセージ契約を固定する。

## Non-goals

- 活動量判定アルゴリズムの高度化。
- 複数端末や複数ユーザー対応。
- Web UIや可視化機能の追加。
- 通知状態ファイルや重複管理ファイルの肥大化対策。

## Proposed Approach

- 基本フローは `Termux収集 -> Sheets追記 -> 判定 -> OpenClaw通知`。
- 各フェーズを1 Issue で閉じる。
- PR前は必ず `./scripts/ci/pre-pr.sh` と `./scripts/ci/pre-pr-report.sh` を実行する。

## Implementation Plan

1. Issue 01: Termux収集スクリプトを安定化する。
2. Issue 02: Google Sheets追記ジョブを実装し、重複防止キーを導入する。
3. Issue 03: 1時間単位の活動量判定ロジックを実装する。
4. Issue 04: OpenClaw向け通知契約ドキュメントを作成する。
5. Issue 05: cron運用とリトライ、障害時ログを整備する。

## Issue Breakdown

### Issue 01: Termux Collector

- Scope:
  - `termux/collect_location.sh` を実行可能にする。
  - JSONL出力と機微情報非表示ログを保証する。
- Acceptance Criteria:
  - 1実行で1行のJSONLが追記される。
  - `timestamp_utc`, `lat`, `lng`, `accuracy_m`, `source`, `device_id` を含む。
- Verification:
  - `./scripts/ci/test-termux-collector.sh`

### Issue 02: Sheets Append + Dedupe

- Scope:
  - `openclaw/` に Sheets追記ジョブを追加する。
  - 同一レコードの重複追記を防ぐキーを実装する。
- Acceptance Criteria:
  - 同一入力を2回実行しても、Sheets側は重複しない。
  - API失敗時に再実行可能な状態を保つ。
- Verification:
  - 追加する `scripts/ci/test-sheets-append.sh`

### Issue 03: Activity Judge

- Scope:
  - 1時間窓の移動量算出を実装する。
  - 活動レベル判定を閾値ベースで実装する。
- Acceptance Criteria:
  - サンプルデータで期待ラベルを返す。
  - 判定ジョブは副作用なしで再実行可能。
- Verification:
  - 追加する `scripts/ci/test-activity-judge.sh`

### Issue 04: OpenClaw Notification Contract (Docs)

- Scope:
  - OpenClaw向け通知契約ドキュメントを作成する。
  - 人間向け通知に必要な必須フィールドとテンプレートを固定する。
  - 機微情報を通知に含めないルールを明文化する。
- Acceptance Criteria:
  - OpenClaw側が通知実装に必要な入力契約を単独で理解できる。
  - 人間向け通知テンプレート（期間・活動レベル・距離・件数）が定義されている。
- Verification:
  - `./scripts/ci/docs-check.sh`

### Issue 05: Cron + Retry + Ops

- Scope:
  - cron設定と運用runbookを整備する。
  - エラー時の一次対応手順を文書化する。
  - Tailnet接続断（端末側/サーバー側VPN断）の検知手順を追加する。
  - 失敗時に `failed_step` と `detail` を含む詳細ログを残す。
- Acceptance Criteria:
  - 収集・判定・通知ジョブが定期実行される。
  - 失敗時に復旧手順で再開できる。
  - Tailscale接続断時の確認手順と復旧手順がrunbookに明記されている。
  - ログ方針に沿って機微情報非表示かつ失敗原因追跡可能な形式になっている。
- Verification:
  - `./scripts/ci/pre-pr.sh`
  - 手動runbook検証手順の実行ログ

## Tests and Verification

- 共通:
  - `./scripts/ci/docs-check.sh`
  - `./scripts/ci/pre-pr.sh`
  - `./scripts/ci/pre-pr-report.sh`
- 各Issue:
  - 専用 `scripts/ci/test-*.sh` を追加して pre-pr へ組み込む。

## Logging Policy (MVP)

- 目的:
  - 障害調査と復旧判断に限定する。
- 形式:
  - 1行JSONログ (`ts`, `level`, `job`, `event`, `result`, `error_code`, `retry_count`, `tailnet_ok`, `failed_step`, `detail`)。
- 出力禁止:
  - `lat`, `lng`, 住所推定情報、token、webhook URL。
- 保存先:
  - サーバー側ジョブ: `tmp/logs/`
  - 端末側ジョブ: `data/logs/`
- 保持期間:
  - MVPでは7日保持し、期限超過ログを削除する。
- Tailnet異常時:
  - `tailscale status` と `tailscale ping` で事前確認する。
  - スマホ電源OFF/機内モードで疎通不可の場合は処理を中断し、`warn` 以上で記録して再試行する。

## Risks and Mitigations

- Android権限不足で収集失敗:
  - `docs/help/troubleshooting.md` に初回確認手順を追記する。
- Sheets/OpenClaw通知連携障害:
  - 冪等キー設計と失敗詳細ログで復旧判断を容易にする。
- Tailnet/VPN接続断（スマホ側またはサーバー側）:
  - ジョブ実行前に Tailnet 到達性を確認し、失敗時は処理を中断して再試行する。
  - 端末電源OFF・機内モードを切り分け項目に含める。
  - `docs/help/troubleshooting.md` に `tailscale status` / `tailscale ping` を使う一次切り分け手順を追加する。
- 実装順序の前後で差分が肥大化:
  - 1 Issue 1 PR を厳守し、Plan外変更を禁止する。

## Planning Checkpoints (decided)

決定日: 2026-02-21

### Checkpoint 1: 先行実装差分の扱い

- Decision: A
- 内容: `termux/collect_location.sh`, `scripts/ci/test-termux-collector.sh`, `scripts/ci/pre-pr.sh` の先行差分を Issue 01 に紐付けて扱う。

### Checkpoint 2: Issue 02 の実装ランタイム

- Decision: A
- 内容: Bash + gogcli で最小実装する。

### Checkpoint 3: 活動量判定の初期判定軸

- Decision: A
- 内容: 移動距離のみで `low / medium / high` を判定する。

### Checkpoint 4: OpenClaw通知仕様の固定方法

- Decision: A
- 内容: OpenClaw側の通知メッセージ契約をドキュメントで固定する。

### Checkpoint 5: cron実行主体

- Decision: A
- 内容: OpenClaw側cronを正本にする。

## Handoff

- 起票済みIssue:
  - #1 Termux Collector
  - #2 Sheets Append + Dedupe
  - #3 Activity Judge
  - #4 OpenClaw Notification Contract (Docs)
  - #5 Cron + Retry + Ops
- 実装進捗（local）:
  - #1 実装・テスト済み
  - #2 実装・テスト済み
  - #3 実装・テスト済み
  - #4 実装・テスト済み
  - #5 実装・テスト済み
- 実装開始条件: Issueと受け入れ条件の合意完了（Issue 01 から着手）。
