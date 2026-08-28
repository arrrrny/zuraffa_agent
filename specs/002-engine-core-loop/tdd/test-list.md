---
feature: 002-engine-core-loop
loop: outside-in # engine exposes a user-visible mission/loop/event surface (engine operator, UI, kernel host)
profile: .specify/memory/tdd-profile.md
spec_criteria: 10 # numbered Acceptance Scenarios across 5 user stories in spec.md (no global AC ids; traced to FR-xxx)
planned_at: fce207d
updated_at: c4805d5
suite_baseline: green # 929 passed, 2 skipped (after merging feat/spec-069-mission-runner)
---

# Test List: Engine Core Loop (spec 002)

> Derived from `spec.md` (User Scenarios & Testing → Acceptance Scenarios, and
> FR-001..FR-005) on `master` @ `fce207d`. **OUTER-ONLY**: `plan.md` is absent, so
> only the outer-loop acceptance behaviors are derived here; the inner loop is
> deferred (see below). No acceptance/integration test exercises these spec
> criteria through the engine's real entry point yet, so every A behavior is
> `PENDING`.

## Outer loop: acceptance behaviors

One per numbered Acceptance Scenario in `spec.md`. Each stays `PENDING` until a
mission is driven end to end through the engine entry point and asserted via its
typed event stream / outcome.

| id  | behavior                                                                                                                              | traces       | kind    | state   | test |
| --- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------- | ------- | ---- |
| A1  | A mission with tools available dispatches each `tool_calls` result, appends results, and re-invokes the LLM until a non-tool finish reason | FR-001, FR-005 | example | DONE    | test/engine/mission_runner_test.dart :: "tool dispatch round-trip emits correlated events and feeds results back" |
| A2  | A scripted 200-call mission completes without state corruption or event loss                                                          | FR-001       | example | DONE    | test/engine/mission_runner_002_a2_test.dart :: "A2: a 200-call mission completes with no event loss or state corruption" |
| A3  | Identical inputs + a recorded LLM re-run 10× produce a byte-identical event stream (determinism)                                      | FR-001       | example | DONE    | test/engine/mission_runner_002_a3_test.dart :: "A3: 10 identical runs produce a byte-identical event stream" |
| A4  | A provider streaming thinking deltas leaves the assistant message carrying thinking blocks next to tool calls at turn completion       | FR-002       | example | PENDING |      |
| A5  | In a multi-turn mission, prior turns' thinking blocks are present when turn N+1 context is assembled                                  | FR-002       | example | PENDING |      |
| A6  | An enqueued steering message is injected before the next LLM call during a running mission                                            | FR-003       | example | DONE    | test/engine/mission_runner_test.dart :: "steering queue drains at turn start in FIFO order" |
| A7  | Follow-up messages queued at mission end cause the loop to continue with them instead of exiting                                       | FR-003       | example | PENDING |      |
| A8  | With maxTurns=5 and a model that never stops, the mission ends with `MaxTurnsExceeded` after turn 5                                    | FR-004       | example | PENDING |      |
| A9  | Identical repeated tool calls hitting the threshold fire `LoopDetected` and abort the mission cleanly                                  | FR-004       | example | PENDING |      |
| A10 | During any mission, consumers receive events in order with monotonic turn/sequence identifiers                                         | FR-005       | example | DONE    | test/engine/mission_runner_test.dart :: "natural single-turn mission emits the full ordered event sequence" |

## Coverage analysis (after merging `feat/spec-069-mission-runner` @ `c4805d5`)

`MissionRunner` (`lib/src/engine/mission_runner.dart`) is the multi-turn loop
these acceptance behaviors target. Its own TDD suite (`test/engine/mission_runner_test.dart`)
drives it end-to-end, so several `002` acceptance behaviors are already satisfied
by passing tests there — marked `DONE` above per the TDD-run "already covered by a
passing test → verify, mark DONE" rule.

| behavior | status | evidence in `test/engine/mission_runner_test.dart` |
| -------- | ------ | -------------------------------------------------- |
| A1 | DONE | "tool dispatch round-trip emits correlated events and feeds results back" — asserts transcript `[user,assistant,tool,assistant]`, `turnsUsed: 2`, status completed |
| A6 | DONE | "steering queue drains at turn start in FIFO order" — `SteeringInjected` before `TurnStarted`, FIFO order |
| A10 | DONE | "natural single-turn mission emits the full ordered event sequence" + tool-dispatch test assert exact ordered event types |
| A8 | GAP (partial) | 069 stops at maxTurns (`MissionStatus.budgetExhausted`) but `002` requires a typed `MaxTurnsExceeded` outcome; no such event/status exists in the `EngineEvent` set |
| A2 | GAP | no 200-call stress test in 069 |
| A3 | GAP | no determinism (10× byte-identical stream) test |
| A4 | GAP | no thinking/`reasoning` block persistence assertion |
| A5 | GAP | no cross-turn thinking-block-in-context assertion |
| A7 | GAP | queue drains at turn start; no follow-up-at-end continuation |
| A9 | GAP | no repetition/`LoopDetected` wiring (loop detection is spec 011) |

## Inner loop: deferred — plan.md absent

`plan.md` does not exist for this feature, so the inner-loop unit behaviors (per
component) cannot be derived. `/speckit.tdd.plan` must be re-run once `plan.md`
exists to populate the `U1..` table (engine-loop executor, stop policy, event
hierarchy, planner/steering queue, repetition detector, etc.). This list records
only the outer-loop acceptance behaviors.

## Edge cases & invariants (from spec.md)

Carried from the spec's Edge Cases; not yet placed as numbered behaviors:

- Provider returns both final content and tool calls in one message → both honored (content recorded, tools dispatched).
- Tool call referencing an unknown tool → typed tool-error result fed back; mission continues.
- Abort during an in-flight LLM stream → stream cancelled, partial turn discarded, session left resumable.
- Empty tool-call arguments / malformed JSON → validation error returned as tool result, never a crash.

## Shipped unit/provider coverage (inner-loop, NOT outer acceptance — reported, not followed)

The repo already ships inner-loop unit/provider tests for several building blocks
of this feature. These are **not** outer-loop acceptance tests and are explicitly
deferred by this outside-in plan; listed here for accuracy only:

- `test/engine/events/engine_event_test.dart` — `EngineEvent` sealed hierarchy (entity).
- `test/data/providers/engine_loop/engine_loop_executor_test.dart`, `.../engine_loop_provider_test.dart` — loop executor/provider.
- `test/data/providers/stop_policy/*`, `test/domain/entities/stop_policy/*`, `test/data/datasources/stop_policy/*`, `test/data/repositories/stop_policy_repository_impl_test.dart` — stop policy.
- `test/data/providers/planner/planner_provider_test.dart` — planner/steering queue.
- `test/llm/default_loop_detector_test.dart` — repetition detection.

## Out of scope

- Inner-loop unit behaviors: deferred until `plan.md` (see above).
- UI/kernel-host consumption of the event stream: consumer-side concern; this list
  covers the engine emitting correctly, not the consumers.
- Provider/tool wiring (specs 003/004): the loop only selects and forwards calls.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
