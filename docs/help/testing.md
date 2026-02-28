---
summary: "このリポジトリでのテスト・検証手順（docs/CI/PR前ゲート）"
read_when:
  - 変更前後で何を実行すべきか迷ったとき
  - PR前の検証コマンドを確認したいとき
title: "Testing"
---

# Testing

Page type: how-to

このリポジトリは現在 docs-first で進めているため、まずはドキュメントとCI再現をテストの基準とする。

## Quick Start

PR前の基本ゲート:

```bash
./scripts/ci/docs-check.sh
./scripts/ci/test-termux-collector.sh
./scripts/ci/test-termux-smoke.sh
./scripts/ci/test-ssh-collector-job.sh
./scripts/ci/test-sheets-append.sh
./scripts/ci/test-collect-sheets-job.sh
./scripts/ci/test-activity-judge.sh
./scripts/ci/test-ops-runtime.sh
./scripts/ci/pre-pr.sh
./scripts/ci/pre-pr-report.sh
```

- `docs-check.sh`: Markdown品質とリンク整合性を確認
- `test-termux-collector.sh`: Termux収集スクリプトのJSONL出力をモックで検証
- `test-termux-smoke.sh`: 実機向け収集スモークスクリプトの複数回収集をモックで検証
- `test-ssh-collector-job.sh`: OpenClaw側 SSH collector job の lock/timeout/retry/Tailnetチェックをモックで検証
- `test-sheets-append.sh`: Sheets追記スクリプトのdedupe/retryをモックで検証
- `test-collect-sheets-job.sh`: OpenClaw側 collect->Sheets job の lock/retry/failed_step ログをモックで検証
- `test-activity-judge.sh`: 1時間窓の距離判定と再実行安定性を検証
- `test-ops-runtime.sh`: Tailnet事前確認、judge/notifyステップ失敗時の詳細ログ、retry、ログローテーションをモックで検証
- `pre-pr.sh`: `act` でGitHub Actions相当のローカル実行（Docker不可環境では理由付きスキップ）
- `pre-pr-report.sh`: PR本文へ貼る検証証跡を生成

## 3-Lane Smoke (Parallel Ops Changes)

次の変更を含むPRでは、3lane同時実行スモークを必須にする。

- `scripts/lane-monitor`
- `scripts/pr-open`
- `.codex/agents/*`
- `docs/help/parallel-implementation.md`
- `docs/tools/codex-multi-agent.md`

実行コマンド:

```bash
./scripts/ci/test-3lane-smoke.sh
```

期待結果:

- `3lane smoke test: PASS`
- `.local/3lane-smoke-report-<UTC>.md` が生成される

## PR Workflow Gates

PR運用のwrapperを使う場合は次の順で確認する。

```bash
scripts/pr-review <PR番号>
scripts/pr-prepare run <PR番号>
scripts/pr-merge verify <PR番号>
```

実マージを行うときだけ `--execute` を付ける。

```bash
scripts/pr-merge run <PR番号> --execute
```

PRを新規作成する前には `scripts/pr-open` を実行する。

```bash
scripts/pr-open --base main --title "<title>" --body-file <path>
```

## Scope

- 現時点の標準ゲートは「docs + local CI再現」。
- 実装コードのユニット/E2Eを追加したら、このページにコマンドと適用条件を追記する。
