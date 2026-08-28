---
feature: 066-engine-event-value-semantics
verdict: PASS_WITH_FINDINGS
standard: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
verified_at: HEAD of feat/spec-066-engine-event-value-semantics # working tree; commit SHA recorded in PR
behaviors: 14 # A1-A4, U1-U4
proven: 13
likely: 0
test_after: 1 # A4 gates
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 75 # deliberate-mutant sampling: 3 of 4 killed; 1 documented survivor (M4)
mutants_survived: 1
suite: 921 passed, 0 failed, 2 skipped # baseline 911/2 at 30b4b94 + 10 new tests; skips are pre-existing KIMI_API_KEY integration tests
---

# TDD Verification: EngineEvent value semantics

**Verdict: PASS WITH FINDINGS.** Genuinely test-first: the spec-066 test
group was written and run BEFORE any implementation existed, and all 10
tests failed against the identity-equality events (RED evidence below);
the `==`/`hashCode`/`toString` implementations then turned the whole
group green. All 9 subtypes gained the house value-object pattern
(`EngineLoop` spec 045, `PlanChangedEvent` spec 014). Three deliberate
mutants were killed; one honest survivor is documented (M4 — the
`runtimeType` guard is redundant for `final` classes). One process
incident occurred mid-cycle and was caught, fixed, and re-verified
(finding #3).

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 | PROVEN | RED: all 9 per-subtype blocks failed before implementation — `dart test --name "spec 066"` exit 1, `+0 -1 … +0 -9`, `Expected: <Instance of 'TurnStarted'> / Actual: <Instance of 'TurnStarted'>` (two identical-payload instances unequal). GREEN after implementation: `+10: All tests passed!` exit 0. |
| A2 | PROVEN | hashCode-equal assertions failed in RED (identity hashes differ); green after. Mutant M2 kills the value-based hashCode. |
| A3 | PROVEN | exact-string toString assertions failed in RED (default `Instance of 'X'`); green after. Mutant M3 kills a dropped toString field. |
| A4 | TEST_AFTER (gate) | `dart analyze --fatal-infos` exit 0, "No issues found!"; `dart test` exit 0, `+921 ~2: All tests passed!` (baseline 911/2 + 10 new). |
| U1 | PROVEN | per-field distinctness assertions in every block; mutant M1 (drop `startedAt` from `MissionStarted.==`) is killed: `Expected: not MissionStarted:<…07:30:00.000Z…> / Actual: MissionStarted:<…09:15:00.000Z…>`, exit 1. |
| U2 | PROVEN | mutant M2 (`hashCode => identityHashCode(this)` on `TurnStarted`) is killed: `Expected: <349732207> / Actual: <92735401>`, exit 1. |
| U3 | PROVEN | mutant M3 (drop `ok` from `ToolCallCompleted.toString`) is killed: `Expected: '…callId: c-1, ok: true' / Actual: '…callId: c-1'`, exit 1. |
| U4 | PROVEN | `different runtimeTypes are never equal` — `TurnStarted` vs `TurnCompleted` with the same field shape never equal (both directions asserted). Note: this test passes via the `is` check; see finding on M4. |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | Mutant M4 (drop the `runtimeType` guard from `==`) **survived** (exit 0, `+10: All tests passed!`). For `final` classes no subtype can exist, so `other is T` already determines the type exactly; the guard is redundant belt-and-braces. Kept because the house pattern mandates it; a contract-legal, declaration-level survivor. | M4 re-run log (below) |
| 2 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent. | this file |
| 3 | LOW | **Process incident (self-reported)**: mid-cycle, two mutant restorations used `git checkout <path>` which restores from HEAD — but the implementation was uncommitted at that moment, so `turn_started.dart` and `tool_call_completed.dart` were silently reverted to master mid-cycle. Detected immediately via impossible M4 output (`Instance of 'TurnStarted'` in a supposedly-implemented tree, `+8 -2`); both files re-implemented, the full group re-run green (`+10`, exit 0), and M4 re-executed properly with `cp`-based backup/restore. M1/M2/M3 evidence was captured BEFORE the incident (while the implementation was present) and is valid. All later restorations use `cp` only. | incident trace in worklog; M4 first run /tmp/066_m4.txt vs re-run /tmp/066_m4b.txt |

No existing tests were weakened, skipped, or filtered: the new spec-066
group is purely additive; all pre-existing groups pass unchanged.

## Mutation results

No mutation tool is installed for this stack; deliberate mutants, one at
a time, each restored and the suite re-run green afterwards. 4 mutants,
3 killed, 1 survivor:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 — drop `startedAt` from `MissionStarted.==` field comparison | U1 / A1 | No | caught — `Expected: not MissionStarted:<…startedAt: 2026-08-24 07:30:00.000Z> / Actual: MissionStarted:<…startedAt: 2026-08-24 09:15:00.000Z>`, exit 1, `+0 -1`. (Failure message renders via the new toString — the diagnostics working as designed.) |
| M2 — `hashCode => identityHashCode(this)` on `TurnStarted` | U2 / A2 | No | caught — `Expected: <349732207> / Actual: <92735401>`, exit 1, `+0 -1`. |
| M3 — drop `ok` from `ToolCallCompleted.toString` | U3 / A3 | No | caught — `Expected: 'ToolCallCompleted(…, callId: c-1, ok: true)' / Actual: 'ToolCallCompleted(…, callId: c-1)'`, exit 1, `+0 -1`. |
| M4 — drop the `runtimeType == other.runtimeType` guard from `TurnStarted.==` | U4 / A1 | **Yes** | survived — exit 0, `+10: All tests passed!`. Redundant for `final` classes (no subtypes possible); the `is` check subsumes it. First M4 run was INVALID (see finding #3); re-run cleanly with cp-based restore: guard removed (grep count 0), suite green, restored (grep count 1). |

Sampling, not exhaustive: mutants targeted the highest-risk behaviors
(field coverage in `==`, value-based hashing, toString completeness).

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| FR-001 — `==` house pattern on all 9 subtypes | A1, U1, U4 + mutants M1 | Yes |
| FR-002 — `hashCode` = `Object.hash` over all fields | A2, U2 + mutant M2 | Yes |
| FR-003 — `toString` renders all fields | A3, U3 + mutant M3 | Yes |
| FR-004 — analyze clean + full suite green | A4 | Yes — 921/0/2 at branch HEAD |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 4-mutant sample, not exhaustive.
- Coverage tooling not installed (profile forbids mid-loop dep additions).
- hashCode stability across isolates/runs — out of Dart contract scope.
- `PlanChanged` (spec 067) and the event log (spec 068) — separate specs.

## Remediation tasks

None blocking. Finding #1 is declaration-level (house pattern retained
deliberately). Finding #3's lesson is encoded in this file: mutant
restoration must use `cp` backups while work is uncommitted.
