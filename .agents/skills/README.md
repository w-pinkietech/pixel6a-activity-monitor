# Local Skills

- `review-pr`: review-only PR analysis with structured findings output
- `prepare-pr`: apply agreed findings and run local CI gates
- `merge-pr`: final merge gate with explicit go/no-go checklist
- `mintlify`: docs-focused skill for Mintlify-style docs maintenance
- `planner`: write implementation plans under `docs/experiments/plans/`
- `issue-planning`: split a plan into scoped implementable issues
- `issue-implementation`: implement one scoped issue and run local checks

See `PR_WORKFLOW.md` for execution order and rules.

## Execution Principle

- PR系 skill（`review-pr` / `prepare-pr` / `merge-pr`）は対応 subagent が background terminal で直列実行する。
- 人間への確認は、停止条件ヒットまたは実マージ実行時に限定する。

## Role Mapping

| Codex Agent | Skill | Primary Output |
| --- | --- | --- |
| `planner` | `planner` | Plan in `docs/experiments/plans/` |
| `issue_planner` | `issue-planning` | Scoped implementation issues |
| `implementer` | `issue-implementation` | Issue implementation + local validation |
| `pr_reviewer` | `review-pr` | `.local/review.md` and `.local/review.json` |
| `pr_preparer` | `prepare-pr` | `.local/prep.md` and CI gate pass |
| `pr_merger` | `merge-pr` | merge readiness decision |

## Wrapper Scripts

- `scripts/pr-review`
- `scripts/pr-prepare`
- `scripts/pr-merge`

## Subagents

- `review-pr/agents/openai.yaml`
- `prepare-pr/agents/openai.yaml`
- `merge-pr/agents/openai.yaml`
- `mintlify/agents/openai.yaml`
- `planner/agents/openai.yaml`
- `issue-planning/agents/openai.yaml`
- `issue-implementation/agents/openai.yaml`
