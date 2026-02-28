# Local Skills

- `review-pr`: review-only PR analysis with structured findings output
- `prepare-pr`: apply agreed findings and run local CI gates
- `merge-pr`: final merge gate with explicit go/no-go checklist
- `mintlify`: docs-focused skill for Mintlify-style docs maintenance
- `planner`: write implementation plans under `docs/experiments/plans/`
- `issue-planning`: split a plan into scoped implementable issues
- `issue-implementation`: implement one scoped issue and run local checks
- `session-open`: session開始時の状況確認（scripts/lane status を含む）

See `PR_WORKFLOW.md` for execution order and rules.

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
- `session-open/agents/openai.yaml`
