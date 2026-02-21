---
name: issue-planning
description: Convert a plan in docs/experiments/plans into scoped, testable GitHub issues with clear acceptance criteria.
---

# issue-planning

## Overview

Planを実行可能なIssue粒度に分割する。

## Inputs

- `docs/experiments/plans/<topic>.md`

## Rules

- 1 Issue = 1つの成果物 + 受け入れ条件。
- 各Issueに目的、対象範囲、完了条件、検証手順を含める。
- Issueは独立して着手可能な順序に並べる。
- Planとのトレーサビリティ（どの節を実装するIssueか）を必ず示す。

## Output

- 推奨Issue一覧（タイトル、本文テンプレート、優先度、依存関係）
