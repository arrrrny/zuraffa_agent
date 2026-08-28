# Test List: Engine event bus

---
feature: 075-engine-event-bus
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 7 # FR-001..FR-007 in spec.md
planned_at: fec7889 # master
updated_at: HEAD
suite_baseline: green # 915 passed / 2 skipped at fec7889
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Fan-out: ONE publish reaches BOTH a typed subscriber and an everything-subscriber; two same-type subscribers both receive it (the onEvent callback cannot do this) | FR-002 | example | PASSING | `test/engine/engine_event_bus_test.dart::spec 075 — EngineEventBus::one publish fans out to many subscribers` |
| A2  | Error isolation: first subscriber throws, second still receives the event, publish does not propagate the error; onSubscriberError hook gets the error + the offending event | FR-003 | example | PASSING | `…::a throwing subscriber never breaks delivery` |
| A3  | Replay: subscriber added AFTER three publishes; replay(history) delivers all three in order to it (and re-delivers to earlier subscribers); composes with an Iterable source like EngineEventLog.events | FR-005 | example | PASSING | `…::replay broadcasts history to current subscribers` |
| A4  | The bridge pattern: an emitter's `onEvent: bus.publish` callback feeds the bus — real EngineEvent objects flow end-to-end from a callback-shaped source to typed subscribers | FR-002 | example | PASSING | `…::onEvent bridge: any emitter becomes a multi-subscriber source` |
| A5  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 915/2 + new) | FR-007 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/engine_event_bus.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Typed delivery: subscribe<TurnStarted> receives TurnStarted but NOT TurnCompleted/ToolCallStarted; subscribe<EngineEvent> receives all three | FR-001 | example | PASSING | `…::typed subscriptions filter by exact runtime type` |
| U2  | Registration order: two same-type subscribers are invoked in subscription order for each published event | FR-002 | example | PASSING | `…::delivery follows registration order` |
| U3  | Cancel: isActive true → cancel → no further delivery, isActive false, double cancel safe, subscriberCount drops; a NEW subscriber after cancel still receives events | FR-004 | example | PASSING | `…::cancel stops delivery and frees the slot` |
| U4  | subscriberCount tracks subscribe/cancel bookkeeping | FR-006 | example | PASSING | `…::subscriberCount tracks live subscriptions` |

## Invariants and edge cases

- Isolation invariant: no subscriber exception can escape publish (A2) — the publisher's control flow is sacred.
- Order invariants: registration order across subscribers within one publish (U2); history order within replay (A3).
- Matching invariant: exact runtime type OR EngineEvent wildcard — never a subclass walk (all members are final; U1 pins it).
- Cancel idempotence: double cancel is safe, no throw (U3).
- No dynamic dispatch: handler invocation goes through a typed erasing closure (implementation discipline; pinned by analyze-clean, not a test).

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | publish delivers to the FIRST matching subscriber only (break after first) | A1 (second same-type subscriber starves) |
| M2  | type filter dropped — every subscriber invoked for every event | U1 (TurnStarted subscriber receives TurnCompleted) |
| M3  | replay iterates the history reversed | A3 (order assertion) |
| M4  | isolation removed — subscriber exceptions propagate to the publisher | A2 (publish throws / second subscriber starves) |
| M5  | cancel is a no-op (entry stays live) | U3 (delivery continues after cancel) |
