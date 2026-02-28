## Summary
- What changed:
- Why:

## Links
- Issue:
- Plan:

## Scope
- [ ] docs only
- [ ] code change
- [ ] behavior change

## Definition of Done
- [ ] Issue と Plan のリンクを記載した
- [ ] 完了条件を満たす変更のみを含めた
- [ ] リスクとロールバックを記載した
- [ ] `docs/reference/dod` を確認した
- [ ] `./scripts/ci/pre-pr.sh` が成功した
- [ ] `./scripts/ci/pre-pr-report.sh` の結果を反映した
- [ ] 実行テスト完了後にPRを作成した（`scripts/pr-open` チェック通過）
- [ ] 並列運用変更時は `./scripts/ci/test-3lane-smoke.sh` を実行し結果を記載した

## Validation
- Commands run:
- Result:
- Execution test evidence (`pre-pr.status`):
- 3lane smoke (if applicable):
- `act` run:
- `pre-pr report`:

## Risks
- Possible regressions:
- Rollback plan:

## Checklist
- [ ] `git diff` reviewed
- [ ] local CI passed with `./scripts/ci/pre-pr.sh`
- [ ] docs updated if behavior changed
- [ ] no secrets/PII added
