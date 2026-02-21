---
name: prepare-pr
description: Script-first PR preparation that resolves review findings and runs gates.
---

# Prepare PR

## Overview

`review-pr` の成果物を元に、PR を merge-ready にする。

## Inputs

- PR番号またはURL（必須）
- `.local/review.json`（必須）

## Safety

- `main` へ直接pushしない。
- `BLOCKER` と `IMPORTANT` は必ず解消する。

## Execution Contract

1. 準備:

```sh
scripts/pr-prepare init <PR>
```

`init` は `review-init` で作られた `.worktrees/pr-<PR>` 上で実行される。

2. findings 解消と修正実装

3. gate 実行:

```sh
scripts/pr-prepare gates <PR>
```

4. 必要時のみ push:

```sh
scripts/pr-prepare push <PR> --execute
```

5. 一括実行:

```sh
scripts/pr-prepare run <PR>
```

## Required Artifacts

- `.local/prep.md`
- `.local/prep.env`
- `.local/pre-pr-report.md`

## Guardrails

- 修正は Issue/Plan の範囲から逸脱しない。
- 検証結果は `.local/prep.md` に残す。
