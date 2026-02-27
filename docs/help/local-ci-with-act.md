---
summary: "PR前にGitHub Actionsをactでローカル再現する手順"
read_when:
  - PRを出す前にCIエラーを先に潰したいとき
  - agentに事前修正まで実施させたいとき
title: "Local CI with act"
---

# Local CI with act

このリポジトリでは、PR前に `act` でActionsを実行してエラーを解消してからPRを作成する。

## Policy

- 原則: PR前に `act` を実行する。
- 失敗時: 失敗原因を修正し、再実行して緑になるまで繰り返す。
- PR本文: 実行した `act` コマンドと結果を `Validation` に記録する。
- 例外: Dockerソケット制約などで `act` を実行できない環境では、`pre-pr.sh` が理由付きで `act` をスキップする。

## Commands

```bash
./scripts/ci/pre-pr.sh
./scripts/ci/pre-pr-report.sh
```

個別ジョブ指定:

```bash
./scripts/ci/pre-pr.sh pull_request docs
./scripts/ci/pre-pr-report.sh
```

モード指定:

```bash
# default: auto（Docker不可なら act を理由付きスキップ）
P6AM_PRE_PR_ACT_MODE=auto ./scripts/ci/pre-pr.sh

# strict: act 実行必須（従来どおり失敗で停止）
P6AM_PRE_PR_ACT_MODE=required ./scripts/ci/pre-pr.sh
```

## Notes

- `act` のランナー指定は `.actrc` で固定している。
- CIとローカルの差分が出た場合は、workflowとスクリプトの共通化を優先する。
- `pre-pr.sh` は内部で `docs-check` を実行する。
- `pre-pr-report.sh` が `.local/pre-pr-report.md` を生成するので、PR本文へ貼り付ける。
- `act` がスキップされた場合は、PRで `Act Reason` を明記し、GitHub上の required checks を必ず通す。
