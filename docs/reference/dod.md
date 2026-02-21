---
summary: "PR作成前に満たすべきDefinition of Done"
read_when:
  - PRを出す前に完了条件を確認したいとき
  - Done条件の判断を統一したいとき
title: "Definition of Done"
---

# Definition of Done

このページは `pixel6a-activity-monitor` の Done 条件の正本。

## Scope

- 対象: Issue, Plan, PR の運用
- 非対象: 将来のプロダクト機能の仕様詳細

## Common Done Criteria

- Issue と Plan が PR本文にリンクされている
- 実装範囲が Issue の `In Scope` に収まっている
- 検証コマンドと結果が PR本文に記録されている
- リスクとロールバック案が PR本文に記録されている
- `scripts/ci/pre-pr.sh` が成功している
- `scripts/ci/pre-pr-report.sh` の結果が PR本文に反映されている

## Code Change Done Criteria

- 回帰観点を含むテストを実施した
- 破壊的変更がある場合は移行手順を明記した
- 個人情報や秘密情報を追加していない

## Docs Change Done Criteria

- 関連ページのリンク整合を確認した
- `docs-check` を通過した
- 追加ページを `docs/docs.json` に反映した

## Final Gate

次の順で実行し、失敗がないこと。

```bash
./scripts/pr-review <PR>
./scripts/pr-prepare run <PR>
./scripts/pr-merge verify <PR>
```

## Related

- [Issue, Plan, PR Flow](/help/issue-plan-pr)
- [Local CI with act](/help/local-ci-with-act)
