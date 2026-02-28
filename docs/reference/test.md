---
summary: "ローカルで実行するテストコマンドの参照"
read_when:
  - テスト実行コマンドだけをすばやく確認したいとき
title: "Tests"
---

# Tests

Page type: reference

詳細ガイドは [Testing](/help/testing) を参照。

- docsチェック: `./scripts/ci/docs-check.sh`
- Termux収集テスト: `./scripts/ci/test-termux-collector.sh`
- Termux収集スモークテスト: `./scripts/ci/test-termux-smoke.sh`
- SSH collectorジョブテスト: `./scripts/ci/test-ssh-collector-job.sh`
- Sheets追記テスト: `./scripts/ci/test-sheets-append.sh`
- collect + Sheetsジョブテスト: `./scripts/ci/test-collect-sheets-job.sh`
- 活動判定テスト: `./scripts/ci/test-activity-judge.sh`
- 運用ランタイムテスト: `./scripts/ci/test-ops-runtime.sh`
- PR前ゲート: `./scripts/ci/pre-pr.sh`
- PR前レポート: `./scripts/ci/pre-pr-report.sh`
- PR作成ゲート: `scripts/pr-open`
- PR運用ゲート: `scripts/pr-review`, `scripts/pr-prepare`, `scripts/pr-merge`
