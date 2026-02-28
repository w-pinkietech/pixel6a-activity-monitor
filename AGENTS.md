# Repository Guidelines

## Project Scope

`pixel6a-activity-monitor` は以下の処理を行うアプリ。

1. Pixel 6a (Termux) で位置情報を定期収集
2. 収集データを Google Sheets に追記
3. 一定時間ごとに活動量を判定
4. Slack に通知

## Project Structure

- `docs/`: ドキュメント
- `data/`: ローカルデータ（原則 Git 管理外）
- `tmp/`: 一時ファイル
- `termux/` (予定): 端末側収集スクリプト
- `openclaw/` (予定): 判定・通知ジョブ
- `.codex/`: Codex multi-agent 設定
- `.agents/skills/`: skill と subagent 設定
- `scripts/`: CI と PR wrapper

## Source of Truth

- 開発フローの基準: `docs/help/issue-plan-pr.md`
- subagent運用: `docs/help/agent-workflow.md`
- 並列実装ルール: `docs/help/parallel-implementation.md`
- GitHub運用ルール: `docs/help/repo-governance.md`
- テスト運用ガイド: `docs/help/testing.md`
- テスト早見表: `docs/reference/test.md`
- Done条件の正本: `docs/reference/dod.md`
- ドキュメント規約: `docs/reference/docs-style.md`

矛盾時は上記の専用ドキュメントを優先し、このファイルを更新して整合させる。

## Docs Rules

- すべての `docs/**/*.md` に frontmatter を付ける。
  - `title`
  - `summary`
  - `read_when`
- 内部リンクはルート相対・拡張子なし（例: `/start/getting-started`）。
- ページ型を明示する（how-to / reference / troubleshooting）。
- 運用ガイドは `docs/help/*`、固定仕様は `docs/reference/*` に置く。

## Development Workflow

- 基本フローは `Issue -> Plan -> PR`。
- Issueは `.github/ISSUE_TEMPLATE/` から作成する。
- Plan は `docs/experiments/plans/` に作成し、Issue は Plan から分割する。
- 1 Issue = 1 PR を原則にし、混在変更を避ける。
- PR には Issue/Plan/検証/リスク/ロールバックを必ず記載する。
- 完了判定は `docs/reference/dod.md` を基準にする。

## Agent Responsibility Matrix

| Stage | Subagent | Skill | Expected Output |
| --- | --- | --- | --- |
| 調査 | `explorer` | n/a | 影響範囲と制約の整理 |
| 計画 | `planner` | `planner` | `docs/experiments/plans/*` |
| Issue分割 | `issue_planner` | `issue-planning` | 実装単位Issue |
| 実装 | `implementer` | `issue-implementation` | 実装差分と検証結果 |
| PRレビュー | `pr_reviewer` | `review-pr` | `.local/review.md/.json` |
| PR準備 | `pr_preparer` | `prepare-pr` | `.local/prep.md` と gate pass |
| マージ判定 | `pr_merger` | `merge-pr` | merge可否の判断 |

## Main/Subagent Reporting Contract

- main agent は orchestration と最終サマリを担当する。
- subagent は完了時に報告Markdownを作成し、main agent へパスを共有する。
- 報告ファイルの保存先: `.local/agent-reports/`
- 命名規則: `<UTC timestamp>-<agent>-<scope>.md`
- 推奨コマンド: `scripts/agent-report <agent> <scope> --task "<task summary>"`

報告Markdownの必須項目:

- Task / Scope
- What changed
- Validation
- Risks / Follow-ups
- Handoff to main agent

エスカレーション:

- 仕様衝突: `planner` に戻して plan を更新する。
- CI失敗: `pr_preparer` が同一PR内で解消する。
- 大規模競合: Issue再分割して parallel 数を下げる。

## Parallel Development Safety

- 複数 agent の同時実装は許可するが、同一ファイルの同時編集は避ける。
- 競合しやすいファイル（`AGENTS.md`, `docs/docs.json`, `scripts/ci/*`）は担当を固定する。
- 明示依頼なしで `git stash` / `git worktree` / branch 切替を行わない。
- 他 agent の未把握変更は壊さず、自分の変更範囲だけを扱う。

例外:

- PR wrapper 運用（`scripts/pr review-init <PR>`）では、レビュー分離のため `.worktrees/pr-<PR>` を自動作成してよい。

## PR and Merge Rules

- script-first contract: `scripts/pr` を正本とし、wrapper から呼び出す。
- レビュー初期化: `scripts/pr-review <PR>`
- 修正とゲート: `scripts/pr-prepare run <PR>`
- 最終確認: `scripts/pr-merge verify <PR>`
- 実マージ: `scripts/pr-merge run <PR> --execute`（明示依頼時のみ）
- `gh pr merge` 直実行ではなく wrapper を優先する。
- `scripts/ci/pre-pr-report.sh` で生成した結果をPR本文に残す。

## Validation Rules

- PR前の最低ゲート:
  - `./scripts/ci/pre-pr.sh`
  - `./scripts/ci/pre-pr-report.sh`
- 失敗時は修正して再実行し、緑になるまで次に進めない。
- CIロジックは workflow 直書きではなく `scripts/ci/*.sh` を単一ソースとして扱う。
- `scripts/pr-merge verify <PR>` では required checks を厳密判定する（0件または非passは失敗）。

## Engineering Rules

- 個人情報（位置情報・住所推定情報）をログにそのまま出さない。
- 破壊的コマンドは明示許可なしで実行しない。
- 失敗時リトライと再実行安全性（冪等性）を優先する。
- 変更後は `git diff` を確認し、検証手順をドキュメントか PR に残す。

## AI Collaboration

- Codex multi-agent 運用: `docs/tools/codex-multi-agent.md`
- skill 一覧と運用: `.agents/skills/README.md`
- PR運用標準: `.agents/skills/PR_WORKFLOW.md`

## Future Additions

以下は現時点では未確定だが、実装フェーズの進行に合わせて追加する。

1. Build / Test matrix の確定
   - 言語・ランタイム・テスト種別（unit/integration/e2e）を固定し、必須コマンドを明文化する。
2. 実装コード向け品質ゲート
   - lint/typecheck/test の必須順序、失敗時の復旧手順、最小カバレッジ基準を定義する。
3. リリース手順
   - versioning、tag、changelog、ロールバック手順を定義する。
4. セキュリティ運用
   - secret 管理、権限最小化、監査ログ、脆弱性対応フローを定義する。
5. データ運用ポリシー
   - 位置情報の保存期間、匿名化方針、削除手順、事故時対応を定義する。
6. 障害対応ランブック
   - Sheets 書き込み失敗、Slack 通知失敗、Termux 停止時の一次対応手順を定義する。
7. 観測性とSLO
   - 監視指標、アラート条件、可用性目標を定義する。
8. 並列実装の上限見直し基準
   - 同時 Issue 数の増減条件と、競合増加時の縮退運用を定義する。

更新ルール:

- 上記項目を新規追加したら、この節から該当ドキュメントへのリンクを張る。
- 未確定項目を確定した時点で、この節の「未確定」説明を削除する。
