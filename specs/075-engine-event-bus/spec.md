**Template Version**: `zuraffa-1.0`

# Feature Specification: Engine event bus

**Branch**: `feat/spec-075-engine-event-bus` (off master `fec7889`) | **Date**: 2026-08-29

## Summary

A typed publish/subscribe bus over the sealed `EngineEvent` union —
implementing the INTENT of the drafted spec 013-event-bus (pub/sub
observability, Status: Draft since 2026-08-27, never scheduled) with the
house's real event model. Plugins, telemetry, and eval harnesses can
observe the engine without touching it: `subscribe<TurnStarted>(...)`,
and every turn start lands in the handler — synchronously, in
registration order, with the publisher never broken by a throwing
subscriber.

What exists today: the 10-member sealed union (specs 016-021, 066, 067)
with value semantics, the EngineEventLog (spec 068, PR #79 — append-only
record + projections), and runtime emitters (MissionRunner and friends,
PRs #80-#83) that fire events through caller-supplied `onEvent`
callbacks. What is missing — per GAP-ANALYSIS row 12 ("Event Bus …
limited observability") — is the fan-out: ONE emission reaching MANY
independent consumers. A bare callback cannot do that; the bus can:
`onEvent: bus.publish` turns any emitter into a multi-subscriber
source.

Honest deviations from the 013 draft, documented rather than silently
dropped:

- **FR-002**: The system MUST satisfy this requirement: request/response (registerHandler / request)**: the draft's
  `BeforeToolCallRequest` and friends do not exist in this repo, and the
  sealed union grows only from its own spec. Deferred until an
  engine-owned request/event spec introduces those types.
  traces: EngineEventBus.fr1
- **FR-004**: The system MUST satisfy this requirement: `AgentController`**: with request/response deferred, the
  controller wrapper would be an empty shell; the bus IS the surface.
  traces: EngineEventBus.fr2
- **FR-005**: "engine MUST emit through the bus"**: the runtimes (PRs
  #80-#83, unmerged stack) emit through `onEvent` callbacks; the bridge
  is `onEvent: bus.publish` — one line at the call site, no engine
  change needed. This spec delivers the bus; an integration test
  proves the bridge pattern with real event objects.
  traces: EngineEventBus.fr3

## Files

- `lib/src/engine/engine_event_bus.dart` — NEW:
  `EngineEventSubscription`, `EngineEventBus`.
- `test/engine/engine_event_bus_test.dart` — NEW.
- `specs/075-engine-event-bus/{spec,plan,tasks}.md` +
  `tdd/{test-list,verification}.md`.

## FRs

- **FR-001**: The system MUST satisfy this requirement: Typed subscription: `subscribe<T extends EngineEvent>(
  void Function(T) handler)` returns an `EngineEventSubscription`
  (handle with `cancel()` and `isActive`). `T` may be a concrete
  subtype (`TurnStarted`) — delivery is EXACT-type — or `EngineEvent`
  itself — delivery is everything. All subtypes are `final`, so
  exact-type matching is unambiguous.
  traces: EngineEventBus.fr4

- **FR-002**: The system MUST satisfy this requirement: `publish(EngineEvent event)`: synchronous delivery, in
  REGISTRATION order, to every subscriber whose type matches
  (`T == event.runtimeType` or `T == EngineEvent`). One emission, many
  independent consumers — the fan-out the onEvent callback cannot do.
  traces: EngineEventBus.fr5

- **FR-003**: The system MUST satisfy this requirement: Subscriber error isolation: a handler that throws must
  NOT break delivery to later subscribers, and must NOT propagate to
  the publisher. Errors (and the event that caused them) go to the
  optional `onSubscriberError` constructor hook; with no hook they are
  swallowed (documented — the bus is infrastructure; a broken observer
  must never break the engine). This repo's dart:io-free discipline
  (spec 064) rules out stderr logging as a default.
  traces: EngineEventBus.fr6

- **FR-004**: The system MUST satisfy this requirement: `cancel()` stops delivery (idempotent — double cancel is
  safe); `isActive` reports liveness; cancelled subscriptions free
  their slot (`subscriberCount` drops).
  traces: EngineEventBus.fr7

- **FR-005**: The system MUST satisfy this requirement: `replay(Iterable<EngineEvent> events)`: re-publishes the
  given history through the bus, in order, to every CURRENT subscriber.
  This is a broadcast, not per-subscriber catch-up: a late subscriber
  that wants history subscribes first, then the caller replays (the
  natural composition with EngineEventLog: `bus.replay(log.events)`).
  traces: EngineEventBus.fr8

- **FR-006**: The system MUST satisfy this requirement: `subscriberCount`: the number of live subscriptions.
  traces: EngineEventBus.fr9

- **FR-007**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test`
  green (baseline 915/2 at `fec7889` + new tests).
  traces: EngineEventBus.fr10

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Request/response patterns (013 FR-002) — blocked on engine-owned
  request event types that do not exist yet (see Summary deviations).
- Async/streaming delivery (`Stream` adapters) — the bus is synchronous
  by design (013 FR-003 "delivered synchronously"); a Stream wrapper is
  trivial sugar if ever needed.
- Wiring an engine runtime to publish through the bus (the runtimes
  live on the unmerged 069-072 stack; the bridge `onEvent: bus.publish`
  needs no engine change).
- Persistence of published events (EngineEventLog, spec 068, owns
  recording).

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** typed subscriptions filter by exact runtime type **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** delivery follows registration order **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** one publish fans out to many subscribers **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** a throwing subscriber never breaks delivery **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** cancel stops delivery and frees the slot **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** subscriberCount tracks live subscriptions **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** replay broadcasts history to current subscribers **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** onEvent bridge: any emitter becomes a multi-subscriber source **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`).
   **Type**: acceptance

## Layer Contracts

**Domain**:

- `EngineEventBus`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`, `fr7(...) -> Result`, `fr8(...) -> Result`, `fr9(...) -> Result`, `fr10(...) -> Result`

