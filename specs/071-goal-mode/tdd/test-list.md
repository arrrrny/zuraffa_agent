# Test List: Goal mode

---
feature: 071-goal-mode
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 7 # FR-001..FR-007 in spec.md
planned_at: 8a5bd83 # feat/spec-069-mission-runner HEAD (stack base)
updated_at: HEAD
suite_baseline: green # 925 passed / 2 skipped at 8a5bd83
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Goal met on turn 1 (assistant-present evaluator) stops the mission `goalAchieved` with 1 turn, summary = turn-1 content, terminal event status `'goalAchieved'`, result.goalAchieved true, result.goal set | FR-003, FR-004 | example | DONE | `test/engine/goal_mode_test.dart::spec 071 — goal mode::goal achieved on turn 1 stops the mission early` |
| A2  | Tool-result-keyed evaluator fires on the SAME turn the tool result lands (post-tool evaluation) — 1-turn mission with a dispatched tool | FR-005(a) | example | DONE | `…::goal evaluation sees tool results within the same turn` |
| A3  | Goal met on the model's natural-stop turn reports `goalAchieved`, NOT `completed` (evaluation before the natural-stop check) | FR-005(b) | example | DONE | `…::goal met on the natural-stop turn reports goalAchieved` |
| A4  | Goal never met: evaluator consulted once per completed turn (count == turns), mission ends `completed`, goalAchieved false | FR-005(c), FR-004 | example | DONE | `…::unmet goal leaves the mission to its natural stop, evaluator consulted every turn` |
| A5  | Budgets still win: unmet goal + maxTurns 2 → `budgetExhausted`, goalAchieved false | FR-005(d) | example | DONE | `…::budget exhaustion overrides goal mode` |
| A6  | Both-or-neither validation: goal without evaluator and evaluator without goal each throw `ArgumentError` | FR-003 | example | DONE | `…::goal and goalEvaluator must be supplied together` |
| A7  | `Goal` value semantics (==/hashCode/toString) | FR-001 | example | DONE | `…::Goal value semantics` |
| A8  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 925/2 + new; spec-069 suite still green) | FR-007 | gate | DONE | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/goal_mode.dart` (new) + `mission_runner.dart` edits

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `MissionResult.goal`/`goalAchieved` defaults: null/false without goal mode (spec-069 A9 still constructs equal results) | FR-004 | example | DONE | spec-069 suite re-run + A1/A4 positive/negative asserts |
| U2  | The transcript handed to the evaluator is unmodifiable (mutating throws) | FR-002 | example | DONE | `…::evaluator receives an unmodifiable transcript view` |
| U3  | `MissionStatus.goalAchieved` exists and `.name` round-trips onto the terminal event | FR-003, FR-006 | example | DONE | A1 terminal-event assert |
| U4  | Provider-failed turn is never evaluated (evaluator count 0 on the failure path) | FR-005(c) | example | DONE | `…::provider-failed turn is never goal-evaluated` |

## Invariants and edge cases

- Early-stop-only: goal mode never extends a mission past natural stop or budgets (A3, A5).
- Terminal-event invariant preserved: goal-achieved missions still emit exactly one `MissionCompleted` with status `'goalAchieved'` (A1).
- No new EngineEvent subtypes — goal surfaces via terminal status only (FR-006).
- `MissionResult` equality now includes goal + goalAchieved (spec-069 A9 must stay green — U1).

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | evaluation moved BEFORE tool dispatch (post-assistant-append, pre-planner) | A2 (tool-keyed evaluator fires a turn later → turnsUsed 2 vs 1) |
| M2  | on achievement, status left `completed` (goalAchieved never assigned to status) | A1 (status + terminal event string) |
| M3  | `MissionResult.goalAchieved` hardcoded false | A1 (flag assert) |
| M4  | evaluator consulted only on turn 1 | A4 (per-turn count) |
| M5  | both-or-neither `ArgumentError` removed | A6 |
