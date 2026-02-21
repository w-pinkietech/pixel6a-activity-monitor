---
summary: "このリポジトリのドキュメント設計規約"
read_when:
  - 新規ドキュメントを書くとき
  - 既存ドキュメントを整理するとき
title: "Docs Style"
---

# Docs Style

このドキュメントは `pixel6a-activity-monitor` 専用の文書規約です。

## Frontmatter

すべてのページで以下を必須にする。

- `title`
- `summary`
- `read_when`

## Page Types

### How-to

目的達成の手順を書く。

- Goal
- Prereqs
- Steps
- Validation
- Next

### Reference

仕様と固定ルールを書く。

- Scope
- Definition
- Constraints
- Examples

### Troubleshooting

障害時の分岐と確認順を書く。

- First checks
- Symptom branches
- Recovery actions

## Link Rules

- 内部リンクはルート相対
- `.md` 拡張子を付けない
- 可能なら関連ページを末尾の `Next` で案内する

## Writing Rules

- 先に結論、後に詳細
- 1セクション1責務
- コピペ可能なコマンド例を出す
- 正常時の期待結果を明示する
- 個人情報に関わる例はマスキングする
