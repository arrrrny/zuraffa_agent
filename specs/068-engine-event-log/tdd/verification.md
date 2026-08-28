---
feature: 068-engine-event-log
verdict: PASS_WITH_FINDINGS
standard: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
verified_at: HEAD of feat/spec-068-engine-event-log # working tree; commit SHA recorded in PR
behaviors: 10 # A1-A5, U1-U5
proven: 9
likely: 0
test_after: 1 # A5 gates
no_test: 0
high_smells: 0
criteria_total: 5
criteria_covered: 5
mutation_score: 100 # deliberate-mutant sampling: 4 of 4 killed
mutants_survived: 0
suite: 919 passed, 0 failed, 2 skipped # baseline 911/2 at 30b4b94 + 8 new tests; skips are pre-existing KIMI_API_KEY integration tests
---

# TDD Verification: EngineEventLog

**Verdict: PASS WITH FINDINGS.** Genuinely test-first: the 8-test suite
was written and run before the library existed — RED was the missing-file
compile failure. The green phase surfaced two honest findings, both
resolved within the cycle and both recorded below: a design discovery
(`emittedAt` promoted to an abstract getter on the sealed base) and a
bug in one of the test's own expectations (corrected, not the
implementation). The analyze gate then caught 9 `annotate_overrides`
infos from the base-class promotion — halted and fixed per constitution
Principle X, re-run pristine. All four deliberate mutants were killed.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 | PROVEN | RED: `Error when reading 'lib/src/engine/events/engine_event_log.dart': No such file or directory` + `Method not found: 'EngineEventLog'` (exit 1). GREEN: order test passes with 4 mixed events, `same(...)` per slot. |
| A2 | PROVEN | unmodifiable snapshot: add/remove/clear/element-assign all `throwsUnsupportedError`; log unaffected afterwards. Mutant M1 proves the guard is load-bearing. |
| A3 | PROVEN | `byType` (2 MissionStarted among 4 events, exact order + `same`), empty for absent types, `.single` for unique type; `firstOfType`/`lastOfType` incl. `null` cases. Mutant M2. |
| A4 | PROVEN | `since`/`before` inclusive AND exclusive boundaries with events emitted exactly at the cutoff; future/past cutoffs return empty without throwing. Mutants M3/M4. |
| A5 | TEST_AFTER (gate) | `dart analyze --fatal-infos` exit 0 "No issues found!" (after the Principle-X fix below); `dart test` exit 0 `+919 ~2: All tests passed!`. |
| U1 | PROVEN | `empty log behaves as empty` — all projections empty/null. |
| U2 | PROVEN | mutation attempts on two separate `events` reads both throw; length stays 1. |
| U3 | PROVEN | exact-type matching — distinct fixture payloads make cross-type returns visible; mutant M2 killed via cast failure. |
| U4 | PROVEN | boundary fixtures at identical instants (t1/t2/t3); mutants M3/M4. |
| U5 | TEST_AFTER (gate) | barrel export added to `lib/zuraffa_agent.dart` — non-behavioral wiring, analyzer-verified. |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | LOW | **Design discovery (spec refined pre-commit):** the first green run failed with `The getter 'emittedAt' isn't defined for the type 'EngineEvent'` — `emittedAt` lived on each subtype, invisible to union-level temporal filters. Fix: abstract `DateTime get emittedAt;` on the sealed base; all 9 subtypes already conform via their fields. Spec FR-004 updated to record this before any commit. | first green log |
| 2 | LOW | **Test-authoring bug caught by the cycle:** one assertion expected `before(t3, inclusive: true).length == 2`, but FR-004's inclusive semantics (`emittedAt <= cutoff`) include the event emitted exactly at `t3` — the correct expectation is 3. The TEST was corrected (implementation was right); the correction strengthens the boundary coverage (now asserts all three elements by identity). | second green log |
| 3 | LOW | **Analyze gate bite (constitution Principle X):** after the base-class promotion, `dart analyze --fatal-infos` reported 9 `annotate_overrides` infos (each subtype's `emittedAt` now overrides the base getter). Halted, added `@override` to all 9 fields, re-run: exit 0, "No issues found!". This is the gate doing exactly what Principle X demands. | analyze logs (9 issues → 0) |
| 4 | LOW | The auditor is the same session that authored the artifacts — the audit is not independent. | this file |

No existing tests were weakened, skipped, or filtered: the new suite is a
new file; the 9 part files gained only `@override` annotations (no
behavioral change — full suite re-run green).

## Mutation results

Deliberate mutants, one at a time, `cp`-backup restored, suite re-run
green after each. 4 mutants, 4 killed, 0 survivors:

| Mutant | Behavior | Survived | Judgment |
| ------ | -------- | -------- | -------- |
| M1 — `events` returns the internal `_events` list directly | U2 / A2 | No | caught — `Expected: throws <Instance of 'UnsupportedError'> / Actual: <Closure>` (the mutation succeeded instead of throwing), `+7 -1`, exit 1. |
| M2 — `byType` drops the type filter (`_events.cast<T>()`) | U3 / A3 | No | caught — `type 'TurnStarted' is not a subtype of type 'MissionStarted' in type cast`, `+7 -1`, exit 1. |
| M3 — `since` ignores the `inclusive` flag (always exclusive) | U4 / A4 | No | caught — `Expected: <2> / Actual: <1>` (the boundary event was dropped), `+7 -1`, exit 1. |
| M4 — `before` filter inverted (`isAfter` instead of `isBefore`) | U4 / A4 | No | caught — `Expected: same instance as <MissionStarted> / Actual: <MissionCompleted>`, `+7 -1`, exit 1. |

## Traceability

| Criterion | Tests | End to end (public API) |
| --------- | ----- | ----------------------- |
| FR-001 — add/addAll, insertion order | A1 | Yes |
| FR-002 — unmodifiable snapshot + counts/emptiness | A2, U2 + M1 | Yes |
| FR-003 — byType/firstOfType/lastOfType | A3, U1, U3 + M2 | Yes |
| FR-004 — since/before with boundaries (+ base-class promotion) | A4, U4 + M3/M4 | Yes |
| FR-005 — analyze clean, suite green, engine purity | A5, U5 | Yes — 919/0/2; pure Dart, no dart:io, no new deps |

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Mutation coverage is a 4-mutant sample, not exhaustive.
- Coverage tooling not installed (profile forbids mid-loop dep additions).
- Concurrency: the log is single-isolate synchronous by design (bus spec 013 owns async).
- Interaction with spec 066/067 PRs: independent branches; the `@override` annotations and base-class getter touch the same part files as PR #77 — mechanical merge resolution, noted in the PR body.

## Remediation tasks

None blocking. Findings #1–#3 were all resolved inside this cycle and are
recorded for process transparency.
