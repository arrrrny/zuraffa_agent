---
feature: 21-engine-event-tool-call-completed
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
suite: #21 group 2 passed inside test/engine/events/engine_event_test.dart; full suite green at HEAD 01618f3
---

# TDD Verification: EngineEvent.ToolCallCompleted

**Verdict: FAIL.** `ToolCallCompleted` already ships on master and the suite is
green (test-list: "shipped on master before this TDD pass ran"). The
`cycle-log.md` records only a baseline — no red for any behavior. Per the rubric,
no recorded red + source predating the pass ⇒ every behavior is `TEST_AFTER`,
which fails the verdict. Shipped tests are green; the routing behavior is only
compile-time guaranteed (finding #1).

## Test-first evidence

| Behavior | Class     | Evidence |
| -------- | --------- | -------- |
| A1 is-A identity | TEST_AFTER | `#21 group::ToolCallCompleted is an EngineEvent` — shipped; cycle-log baseline only. |
| A2 payload fields (`toolName`/`callId`/`ok`) | TEST_AFTER | `#21 group::ToolCallCompleted carries payload fields` — shipped; no red. |
| A3 analyze gate | TEST_AFTER | gate; no red. |
| A4 full-suite gate | TEST_AFTER | gate; no red. |
| U1 value semantics / part file | TEST_AFTER | `tool_call_completed.dart` shipped; no red. |
| U2 no cross-binding | TEST_AFTER | no red. |
| U3 `part 'tool_call_completed.dart';` | TEST_AFTER | gate only. |
| U4 switch handles + routes `ToolCallCompleted` | TEST_AFTER | no dedicated routing-assertion test (finding #1); no red. |

## Findings

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| 1   | MED | U4 "routes to `tool_call_completed(toolName)`" is only compile-time guaranteed. The shared `#24` exhaustive-switch test (`test/engine/events/engine_event_test.dart:28`) carries the `ToolCallCompleted(:final toolName) => 'tool_call_completed($toolName)'` arm and asserts `describe` for a few other events, but never constructs a `ToolCallCompleted` and asserts `describe(toolCallCompleted) == 'tool_call_completed(toolName)'`. A routing change for this subtype would not be caught at runtime. Siblings #16/#17/#18/ProviderError carry the dedicated routing assertion; #21 does not. The test-list acknowledges this. | `test/engine/events/engine_event_test.dart:104-119` (no routing assert); `test-list.md` "Discrepancy found" |
| 2   | LOW | `tasks.md` leaves every task `[ ]` while `test-list.md` marks all behaviors DONE — artifacts disagree on completion status (not the rubric's HIGH `[X]` rule). | `specs/21-*/tasks.md` vs `test-list.md` |

No existing tests were weakened or skipped. Note: A2 uses identical `'sample'`
values for `toolName`/`callId`/`ok` (lines 113-118) — acceptable for the
value-object round-trip, but it does not exercise a distinct `callId` vs
`toolName` the way #18 exercises distinct `providerName`/`error`. Not a smell by
itself; recorded for transparency.

## Mutation results

Not sampled (low-risk value object, out of highest-risk scope). Acceptance
behaviors covered by green tests; routing gap documented in finding #1.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| A1 is-A identity | `ToolCallCompleted is an EngineEvent` | Yes |
| A2 payload value-object | `ToolCallCompleted carries payload fields` | Yes |
| A3 analyze gate | CI `dart analyze --fatal-infos` | Yes (gate) |
| A4 full-suite gate | `dart test` | Yes (gate) |
| U4 switch routing | shared `#24` exhaustive-switch (compile only) | Partial — compile-time only, not behavioral (finding #1) |

Untested criteria: none at acceptance level. U4 routing sub-aspect not
behaviorally asserted (finding #1).

## What was not audited

- Test-first red evidence: absent (cycle-log baseline only; code merged pre-pass).
- Deliberate mutants: not sampled (low-risk value object).
- Coverage: not measured.
- The tool-dispatch layer that emits `ToolCallCompleted` (spec-002/003) is out of
  scope.
