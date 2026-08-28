# Verification: Goal mode (spec 071)

**Branch**: `feat/spec-071-goal-mode` (stacked on `feat/spec-069-mission-runner`)
**Verified at**: branch HEAD | **Baseline**: 925 passed / 2 skipped at `8a5bd83`, analyze clean

## Verdict: PASS

All 7 spec FRs implemented and traced; genuine RED → GREEN; 5/5 deliberate
mutants killed; spec-069 suite re-verified green through the `MissionResult`
surface extension; both gates green with real counts.

## Cycle log

### RED (genuine)

Test file (9 tests) written FIRST — compile failure against the missing
`goal_mode.dart` AND the not-yet-existing enum value / result fields:

```
test/engine/goal_mode_test.dart:15:8: Error: Error when reading 'lib/src/engine/goal_mode.dart': No such file or directory
test/engine/goal_mode_test.dart:102:32: Error: Type 'GoalEvaluator' not found.
test/engine/goal_mode_test.dart:139:14: Error: Method not found: 'Goal'.
test/engine/goal_mode_test.dart:180:43: Error: Member not found: 'goalAchieved'.
00:00 +0 -1: Some tests failed.
```

### GREEN

Implemented `goal_mode.dart` (Goal, GoalEvaluator) + the mission_runner.dart
wiring (enum value, result fields, run params, evaluation point) →
`+9: All tests passed!` on the first full run. Spec-069 regression check
ran explicitly: `+10: All tests passed!` — the `MissionResult` surface
extension (two new optional fields folded into ==/hashCode/toString) broke
nothing.

### Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | evaluation moved BEFORE tool dispatch | KILLED | `+7 -2` — A2: tool-keyed evaluator misses same-turn tool results |
| M2  | status not set to `goalAchieved` on achievement | KILLED | `+6 -3` — A1/A3 status + terminal-event asserts |
| M3  | `MissionResult.goalAchieved` hardcoded false | KILLED | `+7 -2` — A1/A3 flag asserts |
| M4  | evaluator consulted only on turn 1 | KILLED | `+7 -2` — A4 per-turn invocation count |
| M5  | both-or-neither `ArgumentError` removed | KILLED | `+8 -1` — A6 |

Each mutant restored via `cp /tmp/mr071_backup.dart`; both engine files
re-run to green (`+19: All tests passed!`) before the gates.
**5/5 killed — no survivors.**

### Gates (actually run, at branch HEAD after final restore)

- `dart pub get` — clean
- `dart analyze --fatal-infos` — `No issues found!` (exit 0)
- `dart test` — **934 passed / 0 failed / 2 skipped** (baseline 925/2 at
  `8a5bd83` + 9 new; skips are the pre-existing `KIMI_API_KEY` integration
  tests)

## FR traceability

| FR | status | evidence |
| -- | ------ | -------- |
| FR-001 Goal value object | DONE | A7 |
| FR-002 GoalEvaluator seam + unmodifiable transcript | DONE | U2 (add throws `UnsupportedError`) + all rule-based evaluators |
| FR-003 both-or-neither + early stop with terminal `'goalAchieved'` | DONE | A1, A6 |
| FR-004 result surface (`goal`, `goalAchieved`) + extended value semantics | DONE | A1 positive / A4-A5 negative; 069 A9 re-green |
| FR-005 ordering guarantees (post-tool, pre-natural-stop, per-turn, budgets win) | DONE | A2 (same-turn tool visibility), A3 (stop-turn → goalAchieved), A4 (count == turns), U4 (provider-failure never evaluated), A5 (budgetExhausted) |
| FR-006 no new event subtypes | DONE | terminal status string only — A1 asserts `MissionCompleted.status == 'goalAchieved'` |
| FR-007 gates + 069 regression | DONE | counts above |

## Notes / honest limitations

- The evaluator runs synchronously (`bool`); an async LLM-as-judge evaluator
  would require an `async` variant of the seam — deliberately deferred (the
  interface can grow a sibling when needed).
- Strict goal mode (re-prompt until achieved) is explicitly out of scope —
  the early-stop overlay here is its prerequisite.
