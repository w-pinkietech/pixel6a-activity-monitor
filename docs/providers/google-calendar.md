---
summary: "日次判定で参照する Google Calendar read contract"
read_when:
  - 日次判定にイベント文脈を追加するとき
  - Calendar 参照失敗時の挙動を確認したいとき
title: "Google Calendar"
---

# Google Calendar

Page type: reference

## Scope

`openclaw/activity_judge.sh` が対象日の予定を read-only 参照し、`habit_daily_status.event_context` に保存する JSON 文字列の contract を定義する。

## Definition

### Runtime variables

- `P6AM_CALENDAR_ID`: 参照対象 Calendar ID（未設定時は参照をスキップ）
- `P6AM_CALENDAR_TZ`: 参照タイムゾーン（default: `Asia/Tokyo`）
- `P6AM_CALENDAR_MAX_EVENTS`: 保存する最大件数（default: `10`）

### Read window

- 対象日は `P6AM_CALENDAR_TZ` で評価する。
- 対象日の `00:00:00` から `23:59:59` までを参照する。
- 取得件数は最大 `P6AM_CALENDAR_MAX_EVENTS`（default `10`）に制限する。

### `event_context` format

`habit_daily_status.event_context` は次の JSON 文字列を保存する。

```json
{"event_count":2,"top_events":[{"start_at":"2026-02-28T09:00:00+09:00","end_at":"2026-02-28T10:00:00+09:00","summary":"Standup"}],"timezone":"Asia/Tokyo"}
```

固定キー:

- `event_count`: `top_events` 件数
- `top_events`: 最大 10 件。各要素は `start_at`, `end_at`, `summary`
- `timezone`: `P6AM_CALENDAR_TZ`

## Constraints

- Calendar 参照失敗時も判定ジョブは停止しない。
- 失敗時は `event_context` を `event_count=0` / `top_events=[]` で保存し、理由をログ出力する。
- Calendar write（create/update）は行わない。

## Examples

参照付きで判定:

```bash
P6AM_CALENDAR_ID=primary \
P6AM_CALENDAR_TZ=Asia/Tokyo \
P6AM_JUDGE_NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
./openclaw/activity_judge.sh
```

出力確認:

```bash
jq -r '.event_context | fromjson' tmp/activity-latest.json
```

## Next

- [OpenClaw Notification Contract](/gateway/openclaw-notification-contract)
- [CLI Runbook](/cli/runbook)
