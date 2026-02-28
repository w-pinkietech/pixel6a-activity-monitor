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
- `tasks/`: タスク計画と lessons 記録
- `termux/` (予定): 端末側収集スクリプト
- `openclaw/` (予定): 判定・通知ジョブ
- `.codex/`: Codex multi-agent 設定
- `.agents/skills/`: skill と subagent 設定
- `scripts/`: CI と PR wrapper

## Source of Truth

- 開発フローの基準: `docs/help/issue-plan-pr.md`
- ワークフロー設計/タスク管理: `docs/help/workflow-design.md`
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

## Workflow Design

### 1. Planモードを基本とする

- 3ステップ以上、またはアーキテクチャに関わるタスクは Plan モードで開始する。
- 途中で行き詰まったら、無理に進めず立ち止まって再計画する。
- 実装だけでなく検証ステップにも Plan モードを使う。
- 実装前に仕様を明文化し、曖昧さを減らす。

### 2. サブエージェント戦略

- メインコンテキストをクリーンに保つため、サブエージェントを積極活用する。
- リサーチ・調査・並列分析はサブエージェントに委譲する。
- 複雑な課題はサブエージェントを使って計算リソースを増やす。
- 1サブエージェントにつき1タスクを割り当てる。

### 3. 自己改善ループ

- ユーザーから修正を受けたら、再発防止パターンを `tasks/lessons.md` に記録する。
- 同じミスを繰り返さないよう、行動ルールとして明文化する。
- ミス率が下がるまでルールを継続的に改善する。
- セッション開始時に、そのプロジェクトに関係する lessons を確認する。

### 4. 完了前に必ず検証する

- 動作を証明できるまでタスクを完了扱いにしない。
- 必要に応じて `main` と変更差分を確認する。
- 「スタッフエンジニアが承認できるか」を基準に自己レビューする。
- テスト実行とログ確認で正しさを示す。

### 5. エレガントさを追求する（バランス重視）

- 重要変更の前に「よりエレガントな方法がないか」を一度検討する。
- ハック的修正と判断した場合は、前提を更新してより良い解決策を選び直す。
- シンプルで明白な修正では過剰設計を避ける。
- 提示前に自己レビューし、説明責任を持てる状態にする。

### 6. 自律的なバグ修正

- バグ報告を受けたら、追加指示を待たずに原因調査と修正を進める。
- ログ・エラー・失敗テストを起点に自律的に解決する。
- ユーザーのコンテキスト切り替えコストを最小化する。
- 指示がなくても、失敗している CI テストの修正候補を確認する。

## Task Management

1. まず `tasks/todo.md` にチェック可能な計画を書く。
2. 実装前に計画内容を確認する。
3. 進捗に応じて完了項目を随時更新する。
4. 各ステップで高レベルの変更サマリーを残す。
5. 完了時に `tasks/todo.md` に review セクションを追記する。
6. 修正を受けた後は `tasks/lessons.md` を更新する。

## Core Principles

- **シンプル第一**: 変更はできる限り単純にし、影響範囲を最小化する。
- **手を抜かない**: 根本原因を特定し、一時しのぎを避ける。
- **影響を最小化する**: 必要箇所だけを変更し、新規不具合を持ち込まない。

## Agent Responsibility Matrix

| Stage | Subagent | Skill | Expected Output |
| --- | --- | --- | --- |
| 調査 | `explorer` | n/a | 影響範囲と制約の整理 |
| 計画 | `planner` | `planner` | `docs/experiments/plans/*` |
| Issue分割 | `issue_planner` | `issue-planning` | 実装単位Issue |
| 実装（背景） | `implementer_bg` | `issue-implementation` | Issue実装〜PR作成までの自動実行結果 |
| 実装（対話） | `implementer` | `issue-implementation` | ユーザー対話ベースの実装差分と検証結果 |
| PRレビュー | `pr_reviewer` | `review-pr` | `.local/review.md/.json` |
| PR準備 | `pr_preparer` | `prepare-pr` | `.local/prep.md` と gate pass |
| マージ判定 | `pr_merger` | `merge-pr` | merge可否の判断 |

## Background-First Agent Policy

- 標準運用は `implementer_bg` を使い、`scripts/lane-worker` で Issue 実装から PR 作成までを background 実行する。
- `lane-worker` は `codex exec --enable unified_exec` を前提に動かす。
- `implementer` は、仕様確認やスコープ調整などユーザーとの直接対話が必要な場合のみ使う。
- `scripts/pr-review` / `scripts/pr-prepare run` / `scripts/pr-merge verify` は background terminal 実行を標準にする。
- PR系は `review -> prepare -> merge verify` を直列に自走し、完了通知または停止条件ヒット時のみ main/user へ報告する。
- 実マージ（`scripts/pr-merge run <PR> --execute`）は明示依頼がある場合のみ実行する。

## Main/Subagent Reporting Contract

- main agent は orchestration と最終サマリを担当する。
- main agent の最終報告には `Implemented Features` セクションを必ず含める。
- `Implemented Features` には「今回実装した機能」をユーザー視点で列挙する（該当なしの場合は `none` と明記）。
- subagent は完了時に報告Markdownを作成し、main agent へパスを共有する。
- 報告ファイルの保存先: `.local/agent-reports/`
- 命名規則: `<UTC timestamp>-<agent>-<scope>.md`
- 推奨コマンド: `scripts/agent-report <agent> <scope> --task "<task summary>"`

報告Markdownの必須項目:

- Task / Scope
- Implemented Features
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
- 実行主体は main agent ではなく、対応 skill を実行する subagent とする。
- `pr_reviewer` / `pr_preparer` / `pr_merger` は background terminal で実行し、原則ノンブロッキングで進める。
- PR作成時は `gh pr create` 直実行ではなく `scripts/pr-open` を使う。
- Issue実装を含むPRは、実行テスト完了（`pre-pr.status` が `PASS` かつ現HEAD一致）前に作成しない。
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
- PR作成前ゲート:
  - `scripts/pr-open ...` が成功すること（`pre-pr` 証跡とHEAD一致を検証）
- 並列運用関連の変更（`scripts/lane-monitor`, `scripts/pr-open`, `.codex/agents/*`, `docs/help/parallel-implementation.md`, `docs/tools/codex-multi-agent.md` など）では:
  - `./scripts/ci/test-3lane-smoke.sh` を実行し、結果レポートをPR本文またはコメントに残す
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
