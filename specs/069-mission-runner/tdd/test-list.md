# Test List: MissionRunner

---
feature: 069-mission-runner
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: fec7889 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 915 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at fec7889
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | A single natural turn (`finishReason: 'stop'`, no planner) emits exactly `[MissionStarted, TurnStarted, TurnCompleted, MissionCompleted]` in order; the tool dispatcher is never called | FR-001, FR-002 | example | DONE | `test/engine/mission_runner_test.dart::spec 069 — MissionRunner::natural single-turn mission emits the full ordered event sequence` |
| A2  | Natural completion returns `status: completed`, `summary` = final assistant content, `turnsUsed: 1`, and the assistant message appended to the transcript | FR-002 | example | DONE | `…::natural completion returns completed status, summary, and grown transcript` |
| A3  | Planned tool calls are dispatched sequentially; `ToolCallStarted`/`ToolCallCompleted` share the `callId`; a `tool`-role message with the result joins the transcript; the mission continues to natural completion on the next turn | FR-003 | example | DONE | `…::tool dispatch round-trip emits correlated events and feeds results back` |
| A4  | A failed tool dispatch emits `ToolCallCompleted(ok: false)` and appends the ERROR text (not the result) — mission continues | FR-003 | example | DONE | `…::failed tool dispatch reports ok:false and the error text, mission continues` |
| A5  | A supplied `SteeringQueue` drains at turn start: 2 pending messages → 2 `SteeringInjected` events BEFORE `TurnStarted`, transcript gains 2 `user` messages in FIFO order | FR-004 | example | DONE | `…::steering queue drains at turn start in FIFO order` |
| A6  | `StopPolicy.maxTurns` (2) caps the loop under `loop.maxTurns` (10) when the model keeps requesting tools: exactly 2 turns, `budgetExhausted`, terminal event status `'budgetExhausted'` — executor's `StateError` backstop never surfaces | FR-005 | example | DONE | `…::maxTurns budget stops the mission before the executor backstop` |
| A7  | `wallClockTimeout` with an injected clock: deadline exceeded after turn 1 stops the mission `budgetExhausted` with `turnsUsed: 1` | FR-005 | example | DONE | `…::wall-clock deadline stops the mission between turns` |
| A8  | Provider exception on turn 1 → `ProviderError(providerName: <config.id>, error: …)` event, `providerFailed` status, terminal `MissionCompleted` still emitted (never a mission without its terminal event) | FR-006 | example | DONE | `…::provider failure emits ProviderError and still closes the mission` |
| A9  | `MissionResult` value semantics: equal fields (incl. element-wise transcript) ⇒ `==` + equal `hashCode`; differing `turnsUsed` ⇒ unequal; `toString` renders id/status/turns | FR-007 | example | DONE | `…::MissionResult value semantics` |
| A10 | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 915/2 + new) | FR-008 | gate | DONE | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/mission_runner.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `ToolCallPlanner.plan` is consulted after EVERY turn (its output participates in the stop decision — FR-002): it receives the turn's `ChatCompletion` and the transcript so far; returning `[]` on a `stop` completion ends the mission naturally, any calls or a non-`stop` finish continue the loop | FR-002, FR-003 | example | DONE | A3/A6 planner invocation asserts + `…::planner seam receives completion and transcript per turn` |
| U2  | The transcript handed to the planner is defensively unmodifiable (mutating it throws) — the runner's working transcript is never aliased | FR-003 | example | DONE | `…::planner receives an unmodifiable transcript view` |
| U3  | Without a planner, zero dispatches (A1's dispatcher-not-called assert); without a queue, zero `SteeringInjected` (A1's event sequence) | FR-003, FR-004 | example | DONE | A1 |
| U4  | Effective turn cap = `min(loop.maxTurns, policy.maxTurns)` when enabled; `loop.maxTurns` alone when disabled — mutant M3 territory | FR-005 | example | DONE | A6 + mutants M3 |
| U5  | `callId` format `'$missionId-call-$turn-$index'`; `isInternalMission: false` at the dispatch boundary | FR-003 | example | DONE | A3 asserts callId correlation + recorded dispatch flags |

## Invariants and edge cases

- Terminal-event invariant: EVERY `run()` exit path (completed / budget / provider failure) emits `MissionCompleted` exactly once — A1/A6/A8.
- Timestamp provenance: every `emittedAt` comes from the injected clock — A1/A7 assert exact `DateTime.utc(2026,1,1)`-derived stamps.
- The queue snapshot is never mutated in place (drain replaces, `pop()` semantics from spec 033).
- `MissionStatus.name` strings on the terminal event: `completed` / `budgetExhausted` / `providerFailed` (A1/A6/A8).

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | Drop the `MissionStarted` emission | A1 (event sequence) |
| M2  | Skip appending the tool result `ChatMessage` to the transcript | A3 (transcript grew with tool role) |
| M3  | Turn-cap off-by-one: `turnsUsed >= cap` → `turnsUsed > cap` | A6 (a 3rd turn would hit the executor `StateError` backstop / wrong status) |
| M4  | Move the steering drain to AFTER `runTurn` (post-turn) | A5 (SteeringInjected must precede TurnStarted) |
| M5  | `ToolCallCompleted.ok` hardcoded `true` | A4 (ok:false on failed dispatch) |
