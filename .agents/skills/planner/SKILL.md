---
name: planner
description: Create implementation plans under docs/experiments/plans with consistent sections, status tracking, and verification criteria.
---

# planner

## Overview

実装前の設計Planを `docs/experiments/plans/` に作成・更新する。

## Inputs

- 課題の背景と目的
- 想定するユーザー影響
- 既知の制約

## Rules

- 出力先は `docs/experiments/plans/*.md`。
- 既存Planがあれば追記・更新を優先する。
- frontmatter は `title`, `summary`, `read_when`, `owner`, `status`, `last_updated` を含める。
- 本文は最低 `Goals`, `Non-goals`, `Implementation Plan`, `Tests`, `Risks` を含める。

## Validation

- `./scripts/ci/docs-check.sh`

## Output

- 変更したPlanファイル
- 実装に渡す作業単位（候補Issue一覧）
