---
name: session-open
description: Run startup checks for a new Codex session by executing scripts/session-open and lane status commands, then summarize Issue/Plan/PR context and next actions.
---

# session-open

## Overview

新しいセッション開始時に、現在の作業文脈と background 実行状態を短時間で確認する。

## Inputs

- ユーザーの任意フォーカス（例: `issue-28 を優先確認`）

## Steps

1. `scripts/session-open`
2. `scripts/lane-worker status`
3. `scripts/lane-monitor status`

## Output Rules

- 先頭で `Issue / Plan / PR` 文脈を要約する。
- `gh auth` が `ok` でない場合は再認証が必要だと明記する。
- unified_exec 前提の background-first 方針を確認する。
- 次の実行候補を番号付きで 2-3 個提示する。
- ユーザーの追加フォーカスがある場合は最後に反映する。

## Validation

- コマンド失敗時は失敗コマンドと原因を簡潔に報告する。
- 重い処理は行わず、起動時チェックに必要な最小コマンドだけ実行する。

## Output

- セッション開始の運用判断に必要なサマリー
