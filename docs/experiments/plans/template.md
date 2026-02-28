---
summary: "Planページの作成テンプレート"
owner: "team"
status: "draft"
last_updated: "2026-02-21"
read_when:
  - 新しい実装計画を作るとき
  - Planの書式を揃えたいとき
title: "Plan Template"
---

# Plan Title

## Context

何が問題で、なぜ今やるのか。

## Goals

- 達成したいこと

## Non-goals

- 今回やらないこと

## Proposed Approach

- 設計方針

## Decision Log

- Option A:
  - decision: 採用 / 不採用
  - reason:
- Option B:
  - decision: 採用 / 不採用
  - reason:

## Implementation Plan

1. 実装手順
2. 実装手順
3. 実装手順

## Autonomy Contract

- AIが自律的に進める範囲:
  - 例: 実装、テスト、ドキュメント更新、PR作成
- 人間確認が必須な停止条件:
  - 例: 仕様衝突、破壊的変更、権限/secret要求、法務リスク
- 停止時の報告形式:
  - 例: `blocker / needed decision / options / recommended`

## Verification Matrix

| Check | Command | Expected |
| --- | --- | --- |
| docs | `./scripts/ci/docs-check.sh` | PASS |
| local gate | `<command>` | PASS |
| manual | `<steps>` | 想定どおり |

## Risks and Mitigations

- リスクと緩和策
