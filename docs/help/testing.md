---
summary: "このリポジトリでのテスト・検証手順（docs/CI/PR前ゲート）"
read_when:
  - 変更前後で何を実行すべきか迷ったとき
  - PR前の検証コマンドを確認したいとき
title: "Testing"
---

# Testing

このリポジトリは現在 docs-first で進めているため、まずはドキュメントとCI再現をテストの基準とする。

## Quick Start

PR前の基本ゲート:

```bash
./scripts/ci/docs-check.sh
./scripts/ci/pre-pr.sh
```

- `docs-check.sh`: Markdown品質とリンク整合性を確認
- `pre-pr.sh`: `act` でGitHub Actions相当のローカル実行

## PR Workflow Gates

PR運用のwrapperを使う場合は次の順で確認する。

```bash
scripts/pr-review <PR番号>
scripts/pr-prepare run <PR番号>
scripts/pr-merge verify <PR番号>
```

実マージを行うときだけ `--execute` を付ける。

```bash
scripts/pr-merge run <PR番号> --execute
```

## Scope

- 現時点の標準ゲートは「docs + local CI再現」。
- 実装コードのユニット/E2Eを追加したら、このページにコマンドと適用条件を追記する。

