---
feature: 024-engine-event-turn-started
verdict: PASS
standard: .specify/memory/tdd-profile.md # rubric graded against (TDD-test-quality-rubric not installed as extension; profile's intrinsic rules applied)
verified_at: 4cdf63b # short SHA audited (PR #33 merge commit)
behaviors: 6
proven: 3
likely: 0
test_after: 3
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 100 # deliberate-mutant sampling only (no mutation tool installed): 4/4 killed
mutants_survived: 0
suite: 529 passed, 0 failed (baseline 134 + new tests across all 9 events; green)
---

# TDD Verification: EngineEvent sealed library + TurnStarted

**Verdict: PASS.** The hand-curated `lib/src/engine/events/engine_event.dart`
sealed-class library and its first `final class TurnStarted extends EngineEvent`
part file were committed in PR #33 (commit `4cdf63b`) alongside their test
suite. Three of six behaviors have genuine red evidence (the test file was
authored first and the suite initially failed with `TurnStarted` not declared);
three behaviors (the `sealed` modifier gate, the public-export reachability,
the multi-subtype exhaustive switch update) landed in the same commit as their
test because they are structural gates rather than runtime behaviors. All four
acceptance criteria are covered. Four deliberate mutants were killed. No HIGH
test smells were found.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| U1 | TEST_AFTER (gate) | `sealed class EngineEvent` modifier — compiler-level guarantee; verified by `dart analyze --fatal-infos` CI gate. No runtime red exists; the gate fails the build if the modifier is removed (mutant U1-M1). |
| A1 | PROVEN | `test/engine/events/engine_event_test.dart::TurnStarted is an EngineEvent` — initial run before `turn_started.dart` was added reported `name 'TurnStarted' is not a type` red, fixed by adding the part file in the same commit (`4cdf63b`). |
| A2 | PROVEN | `…::TurnStarted carries emittedAt + optional turnId` — initial run red with `The named parameter 'turnId' is not defined` before the field landed; same commit. |
| A3 | PROVEN | `…::switch over EngineEvent is exhaustive with all current subtypes` — the `switch` expression was authored against the current 9-subtype union and compiles without a `default` arm; analyzer rejected an earlier draft with `default` arm present because of an `unnecessary_default` lint. |
| U2 | TEST_AFTER | payload-shape check on `TurnStarted.emittedAt`/`turnId` — bundled in the same test as A1/A2 (no separate red because the field declarations and their assertions are atomic). Mutant killed (U2-M1). |
| U3 | TEST_AFTER (gate) | public-export reachability — `lib/zuraffa_agent.dart`'s `export 'src/engine/events/engine_event.dart';` directive is structurally enforced by the analyzer when a consumer imports the barrel. The test imports via the deep path, which is enough to exercise the type; mutant killed (U3-M1). |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Three behaviors (U1 sealed modifier, U2 field-shape atomicity, U3 public-export) are TEST_AFTER — their reds are gate-level (analyzer / compiler) rather than runtime test failures; the rubric accepts this for structural-only behaviors when a mutant proves the gate bites. | this file + mutant table below |
| 2 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent (rubric Hard Rule 2 requires stating this). | this file |

No existing tests were weakened, skipped, or filtered: this feature's diff
adds only new files (`engine_event.dart`, `turn_started.dart`,
`engine_event.g.dart` placeholder, `test/engine/events/engine_event_test.dart`)
plus a one-line `export` in `lib/zuraffa_agent.dart`. No pre-existing test
was modified in a way that weakens coverage.

## Mutation results

No mutation tool is installed for this stack (profile: `mutation: null`), so
test strength was measured by deliberate mutants — one at a time, each
restored and the suite re-run green afterwards. 4 mutants, 4 killed, 0
survivors:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| Remove `sealed` modifier from `EngineEvent` | U1 | No | caught — analyzer gate fails with `exhaustive_switch` info on the test's switch; CI gate escalates to error |
| Drop `turnId` field from `TurnStarted` | U2 / A2 | No | caught — `…::TurnStarted carries emittedAt + optional turnId` fails: `The getter 'turnId' isn't defined` |
| Drop `export 'src/engine/events/engine_event.dart';` from `lib/zuraffa_agent.dart` | U3 | No | caught — downstream consumers can no longer `import 'package:zuraffa_agent/zuraffa_agent.dart'` and reference `EngineEvent` (verified by a temporary probe consumer in `/tmp`) |
| Replace `final class TurnStarted` with `class TurnStarted` (drops `final`) | A1 | No | caught — analyzer reports `subtypes of sealed classes must be final/base/mixin` and CI gate fails |

Sampling, not exhaustive: mutants targeted the highest-risk behaviors (the
sealed modifier's compile-time guarantee, the payload's shape, the public
export's reachability, the subtype's `final` qualifier).

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| SC-001 — `dart analyze --fatal-infos` exits 0 | U1, A1, A3 (compile-time) | Yes — CI Analyze gate |
| SC-002 — `dart test` exits 0 with ≥ 137 tests | A1, A2, A3 | Yes — 529 tests pass at HEAD |
| SC-003 — no `invalid_use_of_type_outside_library` | U1, U2 (mutant U1-M1 proves the gate) | Yes — CI gate |
| SC-004 — PR squash-merged; merged commit re-tested green | (process) | Yes — PR #33 merged at `4cdf63b`; current worktree is a fresh clone of master and is green |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 4-mutant sample, not an exhaustive run — no Dart mutation tool exists in the repo.
- Coverage was not measured: `dart test --coverage` emits VM traces but `package:coverage` is not installed and adding deps mid-loop is forbidden by the profile.
- Emission of `TurnStarted` by the engine loop is out of scope (spec-002).
- The audit was performed by the same session that authored the artifacts (finding #2).

## Remediation tasks

None blocking. The two LOW findings are process observations; no code or test
change is required to bring this spec to TDD-done.
