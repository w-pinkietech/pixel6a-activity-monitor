---
summary: "Codex の GitHub CLI 運用で認証/接続失敗を減らす docs 整備計画"
owner: "wataken"
status: "in-progress"
last_updated: "2026-02-28"
read_when:
  - Issue #28 を実装するとき
  - Codex で gh コマンド失敗時の標準対応を確認したいとき
title: "Codex GitHub CLI Guardrails Plan"
---

# Codex GitHub CLI Guardrails Plan

## Context

Codex から `gh issue/pr` を実行する際、`token invalid` と sandbox 由来の
`error connecting to github.com` が混在し、再試行判断にぶれが出ていた。
Issue/PR の停滞を避けるため、認証チェックと再実行方針を docs に固定する。

## Goals

- GitHub 操作前の `gh auth status` 確認を標準化する。
- token 無効時の再認証手順を明文化する。
- sandbox 接続失敗時に escalated 再実行へ切り替える判断基準を明文化する。
- PR 操作で wrapper（`scripts/pr-*`）優先の方針を再確認できる状態にする。

## Non-goals

- アプリ機能コードの変更
- CI スクリプト実装の変更
- GitHub Actions workflow の変更

## Proposed Approach

- 既存の運用 docs を更新し、新規ページは増やさない。
- 影響範囲は以下 3 ファイルに限定する。
  - `/help/preflight-check`
  - `/tools/codex-multi-agent`
  - `/help/repo-governance`
- 失敗パターンは `token invalid` と `error connecting to github.com` の 2 種を
  最小セットとして定義する。

## Implementation Plan

1. Issue #28 の範囲を Plan に固定する。
2. `preflight-check` に GitHub 操作前チェックを追加する。
3. `codex-multi-agent` に gh guardrails を追加する。
4. `repo-governance` に GitHub CLI rules を追加する。
5. docs-check を実行し、差分を Issue/PR に紐付ける。

## Tests and Verification

- `./scripts/ci/docs-check.sh`
- 追記した 3 ファイルで矛盾がないことを目視確認する。

## Risks and Mitigations

- ルール重複で記述が乖離する:
  - 最小限の追記に留め、参照リンクで統一する。
- 実行環境依存の説明不足:
  - sandbox 失敗時の escalated 再実行を明記する。

