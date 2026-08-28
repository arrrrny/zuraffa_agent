---
feature: 013-event-bus
loop: outside-in # EventBus + AgentController are a user-visible pub/sub + request/response surface (plugin developers)
profile: .specify/memory/tdd-profile.md
spec_criteria: 4 # numbered Acceptance Scenarios across 3 user stories in spec.md (no global AC ids; traced to FR-xxx)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: Event Bus (spec 013)

> Derived from `spec.md` (User Scenarios & Testing → Acceptance Scenarios, and
> FR-001..FR-005) on `master` @ `fce207d`. **OUTER-ONLY**: `plan.md` is absent, so
> only the outer-loop acceptance behaviors are derived here; the inner loop is
> deferred (see below). A repo-wide case-insensitive search for `EventBus` /
> `AgentController` in `lib/` and `test/` returned **no matches** — the feature has
> no shipped implementation or tests yet, so every A behavior is `PENDING`.

## Outer loop: acceptance behaviors

One per numbered Acceptance Scenario in `spec.md`. Each stays `PENDING` until the
bus and controller are driven end to end and asserted.

| id  | behavior                                                                                       | traces       | kind    | state   | test |
| --- | --------------------------------------------------------------------------------------------- | ------------ | ------- | ------- | ---- |
| A1  | A subscriber to `LLMChunkEvent` receives each chunk event as the model streams                | FR-001       | example | DONE    | `test/events/event_bus_test.dart::A1: a subscriber to LLMChunkEvent receives each chunk event` |
| A2  | Multiple subscribers each receive an event when it fires                                       | FR-001, FR-003 | example | DONE    | `test/events/event_bus_test.dart::A2: multiple subscribers each receive an event, in registration order` |
| A3  | A registered `BeforeToolCallRequest` handler's response is used when the event fires           | FR-002       | example | DONE    | `test/events/event_bus_test.dart::A3: a registered BeforeToolCallRequest handler response is used` |
| A4  | An `AgentController.publish()` delivers the event to all listeners (identical to EventBus)     | FR-004       | example | DONE    | `test/events/event_bus_test.dart::A4: AgentController.publish delivers to all listeners like EventBus` |

## Inner loop: deferred — plan.md absent

`plan.md` does not exist for this feature, so the inner-loop unit behaviors (per
component) cannot be derived. `/speckit.tdd.plan` must be re-run once `plan.md`
exists to populate the `U1..` table (typed `on<T>`/`emit<T>`, `request<R>`/
`registerHandler<T,R>`, synchronous in-order delivery, controller wrappers, event
types). This list records only the outer-loop acceptance behaviors.

## Edge cases & invariants (from spec.md)

Carried from the spec's FRs / Key Entities; not yet placed as numbered behaviors:

- Events delivered synchronously in registration order (FR-003).
- Typed pub/sub (`on<T>`, `emit<T>`) and typed request/response (`request<R>`, `registerHandler<T,R>`) are distinct contracts.
- Engine emits lifecycle events through the bus (FR-005) — depends on spec 002's event emission landing.

## Shipped unit/provider coverage (reported, not followed)

A case-insensitive search for `eventbus` / `agentcontroller` across `lib/` and
`test/` found **no** implementation or tests. This feature is not yet built; the A
behaviors above are greenfield. (Related engine event types from spec 002 live in
`lib/src/engine/...` and are tested separately — they are not this bus.)

## Out of scope

- Inner-loop unit behaviors: deferred until `plan.md` (see above).
- Engine-side emission wiring (FR-005): depends on spec 002 landing its event stream.
- Observability integrations consuming the bus (spec 012 hooks): downstream consumers.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
