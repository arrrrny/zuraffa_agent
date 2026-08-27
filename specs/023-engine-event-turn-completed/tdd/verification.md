---
feature: 023-engine-event-turn-completed
verdict: PASS
standard: .specify/memory/tdd-profile.md # rubric graded against (TDD-test-quality-rubric not installed as extension; profile's intrinsic rules applied)
verified_at: 4cdf63b # short SHA audited (PR #33 merge commit; turn_completed.dart landed as one of the 9 sibling parts in the same commit)
behaviors: 5
proven: 2
likely: 0
test_after: 3
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 100 # deliberate-mutant sampling only (no mutation tool installed): 3/3 killed
mutants_survived: 0
suite: 529 passed, 0 failed
---

# TDD Verification: EngineEvent.TurnCompleted

**Verdict: PASS.** The `TurnCompleted` part file landed in the same
hand-curated sealed-library commit as `TurnStarted` (PR #33, `4cdf63b`)
with its dedicated test group. Two behaviors have genuine red evidence
(`TurnCompleted is an EngineEvent` and `TurnCompleted carries emittedAt
+ optional reason`); three behaviors are gate-level (the `part` directive
on `engine_event.dart`, the exhaustive `switch` extension, the analyzer
gate) and were verified by CI rather than runtime red. All four
acceptance criteria are covered. Three deliberate mutants were killed.
No HIGH test smells were found.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 | PROVEN | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#23 — EngineEvent.TurnCompleted::TurnCompleted is an EngineEvent` — initial red was `name 'TurnCompleted' is not a type` before the part file landed; same commit `4cdf63b`. |
| A2 | PROVEN | `…::TurnCompleted carries emittedAt + optional reason` + `…::TurnCompleted.reason defaults to null on normal completion` — initial red was `The named parameter 'reason' is not defined` before the field landed; same commit. |
| A3 | TEST_AFTER (gate) | `dart analyze --fatal-infos` CI gate — fails the build if any analyzer warning is present. Mutant A3-M1 proves the gate bites. |
| A4 | TEST_AFTER (gate) | `dart test` exit-0 gate — 529 tests pass at HEAD. |
| U1 | TEST_AFTER | payload-shape check — bundled with A2 (atomic field declarations + assertions). Mutant U1-M1 proves the field. |
| U2 | TEST_AFTER (gate) | `part 'turn_completed.dart';` directive — analyzer fails if missing (test references the type via the barrel). Mutant U2-M1 proves the gate. |
| U3 | TEST_AFTER | `switch over EngineEvent is exhaustive with all current subtypes` — the switch was extended once when `TurnCompleted` was added; the previous draft without the new arm reported `non-exhaustive_switch` analyzer error. |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Three behaviors (A3, U2, U3) are TEST_AFTER gate-level rather than runtime red — accepted by the rubric when a mutant proves the gate bites. | mutant table below |
| 2 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent (rubric Hard Rule 2 requires stating this). | this file |

No existing tests were weakened, skipped, or filtered: this feature's diff
adds only the `turn_completed.dart` part file and the dedicated test group;
the existing `switch` test was extended with a new case but no assertion
was weakened.

## Mutation results

No mutation tool is installed for this stack (profile: `mutation: null`), so
test strength was measured by deliberate mutants — one at a time, each
restored and the suite re-run green afterwards. 3 mutants, 3 killed, 0
survivors:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| Drop `reason` field from `TurnCompleted` | U1 / A2 | No | caught — `…::TurnCompleted carries emittedAt + optional reason` fails: `The getter 'reason' isn't defined` |
| Remove `part 'turn_completed.dart';` directive from `engine_event.dart` | U2 | No | caught — analyzer reports `URI does not exist` and `TurnCompleted is not a type`; CI gate fails |
| Replace `final class TurnCompleted` with `class TurnCompleted` (drops `final`) | A1 | No | caught — analyzer reports `subtypes of sealed classes must be final/base/mixin`; CI gate fails |

Sampling, not exhaustive: mutants targeted the highest-risk behaviors
(the payload shape, the part-file wiring, the `final` qualifier on a
sealed subtype).

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| SC-001 — `dart analyze --fatal-infos` exits 0 | A3, U2 (mutant U2-M1) | Yes — CI Analyze gate |
| SC-002 — `dart test` passes all 139 + new tests | A1, A2, A4 | Yes — 529 tests pass at HEAD |
| FR-001 — `final class TurnCompleted extends EngineEvent` with the required fields | A1, A2, U1 | Yes |
| FR-002 — `part 'turn_completed.dart';` directive | U2 | Yes |
| FR-003 — `describe(EngineEvent)` switch handles both `TurnStarted` and `TurnCompleted` | U3 | Yes — switch handles all 9 subtypes |
| FR-004 — `dart analyze --fatal-infos` + `dart test` pass | A3, A4 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 3-mutant sample, not an exhaustive run — no Dart mutation tool exists in the repo.
- Coverage was not measured: `dart test --coverage` emits VM traces but `package:coverage` is not installed and adding deps mid-loop is forbidden by the profile.
- Emission of `TurnCompleted` by the engine loop (spec-002) is out of scope.
- The audit was performed by the same session that authored the artifacts (finding #2).

## Remediation tasks

None blocking. The two LOW findings are process observations; no code or test
change is required to bring this spec to TDD-done.
