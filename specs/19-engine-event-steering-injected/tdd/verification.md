---
feature: 19-engine-event-steering-injected
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 8
proven: 0
likely: 0
test_after: 8
no_test: 0
high_smells: 0
criteria_total: 4 # test-list derives 4 acceptance behaviors (A1-A4) from spec.md Files + Verification; spec.md declares no explicit SC/FR ids
criteria_covered: 4
mutation_score: n/a # deliberate mutants NOT sampled — low-risk value object, no auth/secrets/persistence/money path
mutants_survived: n/a
suite: #19 group 2 passed inside test/engine/events/engine_event_test.dart; full suite green at HEAD 01618f3
---

# TDD Verification: EngineEvent.SteeringInjected

**Verdict: FAIL.** `SteeringInjected` already ships on master and the suite is
green (test-list states this explicitly: "shipped on master before this TDD pass
ran"). The `cycle-log.md` records only a baseline — no red for any behavior. Per
the rubric, with no recorded red and source predating the pass, every behavior is
`TEST_AFTER`, and any `TEST_AFTER` behavior fails the verdict. The shipped tests
are green; the only structural gap is the routing behavior (see finding #1).

## Test-first evidence

| Behavior | Class     | Evidence |
| -------- | --------- | -------- |
| A1 is-A identity | TEST_AFTER | `#19 group::SteeringInjected is an EngineEvent` — shipped on master; cycle-log baseline only, no red. |
| A2 payload fields (`emittedAt`/`content`/`injectedAt`) | TEST_AFTER | `#19 group::SteeringInjected carries payload fields` — shipped; no red. |
| A3 analyze gate | TEST_AFTER | gate; exit 0 at HEAD; no red. |
| A4 full-suite gate | TEST_AFTER | gate; green at HEAD; no red. |
| U1 value semantics / part file | TEST_AFTER | `steering_injected.dart` shipped; no red. |
| U2 no cross-binding | TEST_AFTER | no red recorded. |
| U3 `part 'steering_injected.dart';` | TEST_AFTER | gate (analyze) only. |
| U4 switch handles + routes `SteeringInjected` | TEST_AFTER | no dedicated routing-assertion test (see finding #1); no red. |

## Findings

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| 1   | MED | U4 "routes to `steering_injected(content)`" is only compile-time guaranteed. The shared `#24` exhaustive-switch test (`test/engine/events/engine_event_test.dart:28`) includes the `SteeringInjected(:final content) => 'steering_injected($content)'` arm and asserts `describe` for a few *other* events, but never constructs a `SteeringInjected` and asserts `describe(steeringEvent) == 'steering_injected(content)'`. A change to the routing output for this subtype would not be caught at runtime. Sibling specs #16/#17/#18/ProviderError each carry the dedicated routing assertion; #19 does not. The test-list acknowledges this discrepancy. | `test/engine/events/engine_event_test.dart:134-148` (no routing assert); `test-list.md` "Discrepancy found" |
| 2   | LOW | `tasks.md` leaves every task `[ ]` (unchecked) while `test-list.md` marks all behaviors DONE — the two artifacts disagree on completion status. No `[X]` task maps to an un-DONE behavior, so this is not the rubric's HIGH rule, but it is an inconsistency. | `specs/19-*/tasks.md` vs `test-list.md` |

No existing tests were weakened or skipped.

## Mutation results

Not sampled (low-risk value object, out of highest-risk scope). The acceptance
behaviors are covered by green tests; the routing gap (finding #1) is the only
structural weakness and is documented rather than mutant-tested.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| A1 is-A identity | `SteeringInjected is an EngineEvent` | Yes |
| A2 payload value-object | `SteeringInjected carries payload fields` | Yes |
| A3 analyze gate | CI `dart analyze --fatal-infos` | Yes (gate) |
| A4 full-suite gate | `dart test` | Yes (gate) |
| U4 switch routing | shared `#24` exhaustive-switch (compile only) | Partial — compile-time only, not behavioral (finding #1) |

Untested criteria: none at the acceptance level. Behavior U4's routing sub-aspect
is not behaviorally asserted (finding #1).

## What was not audited

- Test-first red evidence: absent (cycle-log baseline only; code merged pre-pass).
- Deliberate mutants: not sampled (low-risk value object).
- Coverage: not measured (`package:coverage` not installed).
- The concrete steering layer that emits `SteeringInjected` (spec-002) is out of
  scope.
