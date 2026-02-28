新しい Codex セッションの開始時チェックを実行する。

次を順に実行して、結果を簡潔に報告する。

1. `scripts/session-open`
2. `scripts/lane-worker status`
3. `scripts/lane-monitor status`

出力ルール:

- まず現在の `Issue / Plan / PR` 文脈を要約する。
- `gh auth` が `ok` でない場合は、再認証が必要だと明記する。
- unified_exec 前提の background-first 方針を確認し、次の実行候補を番号付きで 2-3 個提示する。
- ユーザーが追加引数を渡した場合は、それを優先事項として最後に反映する。

追加引数:

`$ARGUMENTS`
