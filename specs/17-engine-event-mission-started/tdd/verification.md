---
feature: 017-engine-event-mission-started
verdict: PASS_WITH_GAPS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # corrected 2026-08-29: prior audit graded an uncommitted WIP, not this HEAD
behaviors: 8
proven: 0
likely: 6
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 75 # deliberate sample only (no mutation tool): 3/4 killed; 1 declaration-level survivor (M4)
mutants_survived: 1 # M4 (drop final), LOW, non-behavioral
suite: 1073 passed, 2 skipped, 0 failed (`dart test`) # green at HEAD 01618f3
---

# TDD Verification: EngineEvent.MissionStarted (spec 017)

**Verdict: PASS_WITH_GAPS.** At the committed HEAD (`01618f3`) the suite is green
(1073 passed / 2 skipped). `MissionStarted.operator ==` *does* compare `missionId`
(`lib/src/engine/events/mission_started.dart:18`), and `hashCode`/`toString` include it,
so the FR-001 value-object equality contract holds and the value-semantics test
(`engine_event_test.dart:375`) passes. No HIGH smells remain. The only gap is test-first
evidence: there is no `cycle-log.md` and the branch history is squashed/stacked, so
behaviors are graded `LIKELY` rather than `PROVEN`.

## Correction note (2026-08-29)

The earlier audit (agent-43) reported this spec FAIL on a live `missionId` equality
defect and a red suite. That finding was a **false positive**. Re-examination of the
committed source shows `missionId` *is* compared in `operator ==` at HEAD
(`mission_started.dart:18`); `git diff` confirmed the omission existed only as an
uncommitted local edit (a `missionId` line deleted from `operator ==`) that was never
part of HEAD and has since been reverted. The full suite is green. The R1 remediation
task in `tasks.md` is therefore retracted — there is no source change to make.

## Test-first evidence

`specs/17-engine-event-mission-started/tdd/cycle-log.md` does not exist and the branch
history is squashed/stacked, so test-first order is unverifiable; behaviors graded
`LIKELY`. All value-semantics behaviors are green at HEAD.

| Behavior | Class  | Evidence |
| -------- | ------ | -------- |
| A1 is-A (EngineEvent + MissionStarted) | LIKELY | no cycle-log.md; squashed history |
| A2 carries payload fields (distinct emittedAt/startedAt) | LIKELY | value-semantics equality test green at HEAD |
| A3 analyze gate | LIKELY | no cycle-log.md |
| A4 full-suite gate | LIKELY | engine_event_test.dart green at HEAD |
| U1 `final class` payload shape | LIKELY | equality test green at HEAD |
| U2 emittedAt/startedAt binding | LIKELY | distinct-timestamps assert |
| U3 part-file directive | LIKELY | analyze bite |
| U4 describe(EngineEvent) routing | LIKELY | routing assert |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | RETRACTED (false positive) | Prior claim that `operator ==` omits `missionId` — false at HEAD; the field *is* compared (`mission_started.dart:18`). Graded against an uncommitted WIP regression, not committed code. See correction note. | `lib/src/engine/events/mission_started.dart:13-19`; `engine_event_test.dart:375` |
| 2 | LOW | Repo-wide `dart analyze --fatal-infos` has 3 issues (1 warning + 2 infos) in out-of-scope files (`test/engine/mission_runner_002_a2_test.dart`, `lib/src/eval/cassette_replay_llm_client.dart`, `test/engine/mission_runner_002_a3_test.dart`). This spec's own files are clean. | `dart analyze --fatal-infos` at 01618f3 |

## Mutation results

Prior deliberate-mutant sample (no mutation tool): 3 of 4 killed, 1
declaration-level survivor. The surviving M4 (drop `final`) is non-behavioral and
LOW; the behavioral mutants (M1 drop `startedAt`, M2 cross-binding, M3 drop
`part` directive) were killed.

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 drop `startedAt` field + param | U1, A2 | No | compile error `No named parameter 'startedAt'` |
| M2 initializer cross-binding | U2, A2 | No | `Expected: 08:00Z Actual: 07:45Z` |
| M3 remove `part` directive | U3, A3 | No | analyze + test fail |
| M4 drop `final` | A1 | Yes (LOW) | declaration-level; runtime unobservable |

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| SC-001 analyze exits 0 | A3, U3 | Yes (this spec's files clean) |
| SC-002 full suite passes | A1, A2, A4, U4 | Yes — engine_event_test.dart green at HEAD |
| FR-001 `final class` extends EngineEvent with payload | A1, A2, U1, U2 | Yes — `==` compares missionId (no defect) |
| FR-002 `part` directive | U3 | Yes |
| FR-003 describe switch routes MissionStarted | U4 | Yes |
| FR-004 analyze + test gates | A3, A4 | Yes — analyze clean, suite green |

Tests tracing to nothing: none. Untested criteria: none.

## What was not audited

- `cycle-log.md` absent → ordering unverified (`LIKELY`).
- Mutation scoped to a 4-mutant sample; not exhaustive (no mutation tool).
- Coverage not measured (`package:coverage` not installed).
- Emission of `MissionStarted` by the engine loop / mission runner (spec-002 / spec-005) is out of scope.

## Remediation tasks

None required. The prior R1 task in `tasks.md` is retracted: `operator ==` already
compares `missionId` at HEAD and the suite is green. The only durable gap is test-first
evidence (squashed history), which cannot be repaired retroactively.
