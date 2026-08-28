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

- **FR-002 request/response (registerHandler / request)**: the draft's
  `BeforeToolCallRequest` and friends do not exist in this repo, and the
  sealed union grows only from its own spec. Deferred until an
  engine-owned request/event spec introduces those types.
- **FR-004 `AgentController`**: with request/response deferred, the
  controller wrapper would be an empty shell; the bus IS the surface.
- **FR-005 "engine MUST emit through the bus"**: the runtimes (PRs
  #80-#83, unmerged stack) emit through `onEvent` callbacks; the bridge
  is `onEvent: bus.publish` — one line at the call site, no engine
  change needed. This spec delivers the bus; an integration test
  proves the bridge pattern with real event objects.

## Files

- `lib/src/engine/engine_event_bus.dart` — NEW:
  `EngineEventSubscription`, `EngineEventBus`.
- `test/engine/engine_event_bus_test.dart` — NEW.
- `specs/075-engine-event-bus/{spec,plan,tasks}.md` +
  `tdd/{test-list,verification}.md`.

## FRs

- **FR-001** — Typed subscription: `subscribe<T extends EngineEvent>(
  void Function(T) handler)` returns an `EngineEventSubscription`
  (handle with `cancel()` and `isActive`). `T` may be a concrete
  subtype (`TurnStarted`) — delivery is EXACT-type — or `EngineEvent`
  itself — delivery is everything. All subtypes are `final`, so
  exact-type matching is unambiguous.

- **FR-002** — `publish(EngineEvent event)`: synchronous delivery, in
  REGISTRATION order, to every subscriber whose type matches
  (`T == event.runtimeType` or `T == EngineEvent`). One emission, many
  independent consumers — the fan-out the onEvent callback cannot do.

- **FR-003** — Subscriber error isolation: a handler that throws must
  NOT break delivery to later subscribers, and must NOT propagate to
  the publisher. Errors (and the event that caused them) go to the
  optional `onSubscriberError` constructor hook; with no hook they are
  swallowed (documented — the bus is infrastructure; a broken observer
  must never break the engine). This repo's dart:io-free discipline
  (spec 064) rules out stderr logging as a default.

- **FR-004** — `cancel()` stops delivery (idempotent — double cancel is
  safe); `isActive` reports liveness; cancelled subscriptions free
  their slot (`subscriberCount` drops).

- **FR-005** — `replay(Iterable<EngineEvent> events)`: re-publishes the
  given history through the bus, in order, to every CURRENT subscriber.
  This is a broadcast, not per-subscriber catch-up: a late subscriber
  that wants history subscribes first, then the caller replays (the
  natural composition with EngineEventLog: `bus.replay(log.events)`).

- **FR-006** — `subscriberCount`: the number of live subscriptions.

- **FR-007** — Gates: `dart analyze --fatal-infos` clean; `dart test`
  green (baseline 915/2 at `fec7889` + new tests).

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
