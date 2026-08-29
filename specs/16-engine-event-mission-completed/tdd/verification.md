---
feature: 016-engine-event-mission-completed
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited (working tree HEAD)
behaviors: 8
proven: 0
likely: 6
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 75 # deliberate sample only (no mutation tool): 3/4 killed; 1 declaration-level survivor (M4)
mutants_survived: 1
suite: RED # test/engine/events/engine_event_test.dart: 'MissionCompleted equality, hashCode, toString' FAILS at 01618f3
---

# TDD Verification: EngineEvent.MissionCompleted (spec 016)

**Verdict: FAIL.** The full suite at the audited HEAD is **red** for this spec's
entry surface: `test/engine/events/engine_event_test.dart :: MissionCompleted
equality, hashCode, toString` fails because `operator ==` in
`lib/src/engine/events/mission_completed.dart` omits `missionId` (while
`hashCode` and `toString` include it), violating the FR-001 value-object contract
and the Dart `==`/`hashCode` equality rule. The bug is in the feature's own
source, not the test — the test correctly asserts two distinct `missionId`s are
not equal. (This also contradicts the group audit's "all 125 tests pass" baseline
claim; see handoff.)

## Test-first evidence

`specs/16-engine-event-mission-completed/tdd/cycle-log.md` does not exist and the
branch history is squashed/stacked, so test-first order is unverifiable; behaviors
graded `LIKELY`. Two value-semantics behaviors (A2, U1) are additionally
**currently FAILING** (suite red) and are recorded as a HIGH finding below.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 is-A (EngineEvent + MissionCompleted) | LIKELY | no cycle-log.md; squashed history |
| A2 carries payload fields incl. `summary` round-trip | LIKELY (FAILING) | value-semantics equality test red at HEAD |
| A3 analyze gate | LIKELY | no cycle-log.md |
| A4 full-suite gate | LIKELY (FAILING) | engine_event_test.dart red at HEAD |
| U1 `final class` payload shape | LIKELY (FAILING) | equality test red at HEAD |
| U2 missionId/status binding | LIKELY | distinct-values assert |
| U3 part-file directive | LIKELY | analyze bite |
| U4 describe(EngineEvent) routing | LIKELY | routing assert |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | **HIGH** | `operator ==` in `lib/src/engine/events/mission_completed.dart` ignores `missionId` while `hashCode` (and `toString`) include it. Two instances with different `missionId` but equal `emittedAt`/`status`/`summary` compare equal — breaks the equality contract and the `MissionCompleted equality, hashCode, toString` test. Defect lives in source, not test. | `lib/src/engine/events/mission_completed.dart:21-25`; test `test/engine/events/engine_event_test.dart:389` (`isNot(equals(MissionCompleted(emittedAt: t, missionId: 'm-8', ...)))`) |
| 2 | LOW | Repo-wide `dart analyze --fatal-infos` is red at HEAD (3 issues: 1 warning + 2 infos) in out-of-scope files (`test/engine/mission_runner_002_a2_test.dart`, `lib/src/eval/cassette_replay_llm_client.dart`, `test/engine/mission_runner_002_a3_test.dart`). This spec's own files are clean. | `dart analyze --fatal-infos` at 01618f3 |

## Mutation results

Prior deliberate-mutant sample (no mutation tool): 3 of 4 killed, 1
declaration-level survivor. The surviving M4 (drop `final`) is non-behavioral and
LOW; the behavioral mutants (M1 drop `summary`, M2b cross-binding, M3 drop
`part` directive) were killed. Note the equality regression above is **not** a
surviving mutant — it is a live source defect now caught by the value-semantics
test.

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 drop `summary` field + param | U1, A2 | No | compile error `No named parameter 'summary'` |
| M2b initializer cross-binding | U2, A2, U4 | No | `Expected: 'm-42' Actual: 'success'` |
| M3 remove `part` directive | U3, A3 | No | analyze + test fail |
| M4 drop `final` | A1 | Yes (LOW) | declaration-level; runtime unobservable |

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| SC-001 analyze exits 0 | A3, U3 | Yes (this spec's files clean) |
| SC-002 full suite passes | A1, A2, A4, U4 | **No** — engine_event_test.dart red at HEAD |
| FR-001 `final class` extends EngineEvent with payload | A1, A2, U1, U2 | **No** — `==` omits missionId (HIGH finding #1) |
| FR-002 `part` directive | U3 | Yes |
| FR-003 describe switch routes MissionCompleted | U4 | Yes |
| FR-004 analyze + test gates | A3, A4 | Partial — analyze clean for this spec, test red |

Tests tracing to nothing: none. Untested criteria: none declared; FR-001 /
SC-002 currently fail.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 4-mutant sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Emission of `MissionCompleted` by the engine loop / mission runner (spec-002 /
  spec-005) is out of scope.
- The equality regression was found by the existing value-semantics test, not by a
  deliberate mutant in this audit.

## Remediation tasks

See `tasks.md` (Phase N: TDD remediation). The feature is **not done** until
finding #1 is cleared.
