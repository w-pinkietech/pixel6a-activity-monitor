# pixel6a-activity-monitor Vision

このリポジトリは、遊びのアプリ開発とコンテクストエンジニアリング学習を両立するための実験場。

## Goal

Pixel 6a で収集した位置情報をもとに、活動量を定期判定し、Slackへ通知するまでを安定運用できる形で実装する。

## Why This Exists

- 生活データを軽量に記録し、行動把握に使える最小システムを作るため。
- OpenClaw型のドキュメント駆動開発（Issue -> Plan -> PR）を実践して学ぶため。

## Current Priorities

1. 収集の安定性（欠損と重複を減らす）
2. データ品質（時刻・位置・送信結果の整合性）
3. 通知の実用性（ノイズを減らし、意味のある要約にする）
4. 運用の再現性（セットアップと障害対応をドキュメント化）

## Development Principles

- 1 Issue = 1トピックで進める。
- Planなしで大きな実装を始めない。
- PRには検証手順と結果を必ず残す。
- 破壊的変更より復旧可能性を優先する。
- 個人情報はログやサンプルに残さない。

## Quality Bar

- 失敗時に再試行できる（冪等性がある）。
- 手動運用でも復旧できる（手順がdocsにある）。
- 主要処理の入力と出力が追跡できる。
- 変更理由がIssue/Plan/PRで追える。

## What We Will Not Do (For Now)

- 早い段階での過剰な最適化。
- 重い可視化UIの先行実装。
- 複数端末・複数ユーザー対応の先行実装。
- 目的が曖昧な機能追加。

## Project Workflow

- 課題定義: Issue
- 設計: `docs/experiments/plans/`
- 実装と検証: PR

運用詳細は `docs/help/issue-plan-pr.md` を参照。

