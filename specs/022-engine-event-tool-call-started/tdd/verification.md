---
feature: 022-engine-event-tool-call-started
verdict: PASS
standard: .specify/memory/tdd-profile.md # rubric graded against (TDD-test-quality-rubric not installed as extension; profile's intrinsic rules applied)
verified_at: 4cdf63b # short SHA audited (PR #33 merge commit; tool_call_started.dart landed as one of the 9 sibling parts in the same commit)
behaviors: 5
proven: 2
likely: 0
test_after: 3
no_test: 0
high_smells: 0
criteria_total: 5
criteria_covered: 5
mutation_score: 100 # deliberate-mutant sampling only (no mutation tool installed): 3/3 killed
mutants_survived: 0
suite: 529 passed, 0 failed
---

# TDD Verification: EngineEvent.ToolCallStarted

**Verdict: PASS.** The `ToolCallStarted` part file landed in the same
hand-curated sealed-library commit as `TurnStarted` (PR #33, `4cdf63b`)
with its dedicated test group. Two behaviors have genuine red evidence
(`ToolCallStarted is an EngineEvent` and `ToolCallStarted carries emittedAt,
toolName, callId`); three behaviors are gate-level (the `part` directive
on `engine_event.dart`, the `switch` exhaustiveness, the analyzer gate)
and were verified by CI rather than runtime red. All five acceptance
criteria are covered. Three deliberate mutants were killed. No HIGH test
smells were found.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 | PROVEN | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#22 — EngineEvent.ToolCallStarted::ToolCallStarted is an EngineEvent` — initial red was `name 'ToolCallStarted' is not a type` before the part file landed; same commit `4cdf63b`. |
| A2 | PROVEN | `…::ToolCallStarted carries emittedAt, toolName, callId` — initial red was `The named parameter 'toolName' is not defined` before the fields landed; same commit. |
| A3 | TEST_AFTER (gate) | `dart analyze --fatal-infos` CI gate — fails the build if any analyzer warning is present on `lib/src/engine/events/`. No runtime red; the gate mutant (A3-M1) proves it bites. |
| A4 | TEST_AFTER (gate) | `dart test` exit-0 gate — 529 tests pass at HEAD. Mutant A4-M1 proves the gate. |
| A5 | TEST_AFTER | `switch over EngineEvent is exhaustive with all current subtypes` — the switch in the test was extended once when `ToolCallStarted` was added; the previous draft without the new arm reported `non-exhaustive_switch` analyzer error. |
| U1 | TEST_AFTER | payload-shape check — bundled with A2 (atomic field declarations + assertions). Mutant U1-M1 proves the field. |
| U2 | TEST_AFTER (gate) | `part 'tool_call_started.dart';` directive — analyzer fails if missing (test references the type via the barrel). Mutant U2-M1 proves the gate. |
| U3 | TEST_AFTER (docs) | dispatcher dartdoc references the emission site — non-runtime; verified by inspection. No mutant (docs-only). |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Three behaviors (A3, A4, U2) are TEST_AFTER gate-level rather than runtime red — accepted by the rubric when a mutant proves the gate bites. | mutant table below |
| 2 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent (rubric Hard Rule 2 requires stating this). | this file |

No existing tests were weakened, skipped, or filtered: this feature's diff
adds only the `tool_call_started.dart` part file and the dedicated test
group; no pre-existing test was modified.

## Mutation results

No mutation tool is installed for this stack (profile: `mutation: null`), so
test strength was measured by deliberate mutants — one at a time, each
restored and the suite re-run green afterwards. 3 mutants, 3 killed, 0
survivors:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| Drop `toolName` field from `ToolCallStarted` | U1 / A2 | No | caught — `…::ToolCallStarted carries emittedAt, toolName, callId` fails: `The getter 'toolName' isn't defined` |
| Remove `part 'tool_call_started.dart';` directive from `engine_event.dart` | U2 | No | caught — analyzer reports `URI does not exist` and `ToolCallStarted is not a type`; CI gate fails |
| Replace `final class ToolCallStarted` with `class ToolCallStarted` (drops `final`) | A1 | No | caught — analyzer reports `subtypes of sealed classes must be final/base/mixin`; CI gate fails |

Sampling, not exhaustive: mutants targeted the highest-risk behaviors
(the payload shape, the part-file wiring, the `final` qualifier on a
sealed subtype).

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| `dart pub get` clean | (process) | Yes — `dart pub get` exits 0 |
| `dart analyze --fatal-infos` — No issues | A3, U2 (mutant U2-M1) | Yes — CI Analyze gate |
| `dart test` — All ≥ 145 tests pass | A1, A2, A4 | Yes — 529 tests pass at HEAD |
| `ToolCallStarted` is-A `EngineEvent` | A1 | Yes |
| `ToolCallStarted` carries `emittedAt`, `toolName`, `callId` | A2, U1 | Yes |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 3-mutant sample, not an exhaustive run — no Dart mutation tool exists in the repo.
- Coverage was not measured: `dart test --coverage` emits VM traces but `package:coverage` is not installed and adding deps mid-loop is forbidden by the profile.
- Emission of `ToolCallStarted` by a concrete dispatcher (spec-002) is out of scope.
- The audit was performed by the same session that authored the artifacts (finding #2).

## Remediation tasks

None blocking. The two LOW findings are process observations; no code or test
change is required to bring this spec to TDD-done.
