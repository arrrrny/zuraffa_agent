# Feature Specification: Request/response pattern — completing spec 013

**Branch**: `feat/spec-078-request-response` (off master `7fa7e82`) | **Date**: 2026-08-29

## Summary

Spec 013 (event bus) landed its outer loop directly on master (A1–A4:
typed pub/sub, multi-subscriber order, basic request/response dispatch,
`AgentController` publish/listen). Two halves of the spec remain unbuilt:

1. **FR-004 is half done.** The spec's Key Entities define
   `AgentController: publish(), listen<T>(), request(), on<T>()` — but the
   shipped controller has only `publish`/`listen`. There is no
   `request()` (the request/response convenience — the pattern this spec
   is named for) and no `on<T>()` alias. A default-constructed controller
   also exposes no path to its wrapped bus, so handlers can never be
   registered against it — `request()` would be unusable end-to-end.
2. **FR-002's semantics are unpinned.** The bus dispatches to the
   most-recently-registered handler and throws `StateError` when none is
   registered — real behavior, but zero tests guard the multi-handler
   rule, handler-exception propagation, the no-handler error, or response
   type honesty. One refactor away from silent breakage.

This spec closes both:

- `AgentController.request<R>(event)` — typed request/response through
  the wrapped bus, identical behavior to `EventBus.request` (013 SC-003
  parity).
- `AgentController.on<T>(listener)` — the documented listen alias.
- `AgentController.bus` — the wrapped bus exposed, making the
  handler-registration surface reachable (the wrap must be transparent,
  not a black box).
- Pinned + mutation-guarded semantics on the bus: last-registered handler
  responds (override semantics — like middleware, a later registrant may
  override an earlier one); handler exceptions propagate to the awaiting
  requester (never swallowed); no handler → `StateError` naming the type;
  the `as R` cast is honest — a wrong `R` surfaces as a `TypeError`, not
  a silent `null`.

**Out of scope, documented deviation**: 013 FR-005 (engine emits
lifecycle events through this bus) stays deferred — the engine's event
channel in this repo is the sealed `EngineEvent` union carried by the
075 `EngineEventBus` (PR #86); 013's prose event names
(`AgentStartedEvent`, `LLMChunkEvent`, …) are not engine emissions here.
Wiring the engine to the generic bus would fork the event channel —
rejected.

## Files

- `lib/src/events/event_bus.dart` — EDIT: `AgentController` gains
  `request<R>`, `on<T>`, `bus`; stale "Stub" doc comment replaced.
  Additive only — A1–A4 behavior untouched.
- `test/events/request_response_test.dart` — NEW: controller surface +
  pinned bus semantics.
- `specs/013-event-bus/` — untouched (its cycle-log stays the A1–A4
  record; this spec's artifacts live in `specs/078-request-response/`).

## User scenarios

### US1 — Ask the agent through the controller (P1)

As a plugin developer, I register a handler on the bus and ask a typed
question through the controller: `controller.request<Response>(request)`
returns the handler's response — no direct bus reference needed after
construction.

**Independent test**: controller over a bus with a registered
`BeforeToolCallRequest` handler → `controller.request` returns the
modified response.

### US2 — Predictable request/response semantics (P1)

As a plugin developer, I can rely on the contract: the latest registered
handler answers; handler errors reach me; asking with no handler is a
`StateError` naming the type; a wrong response type surfaces loudly.

**Independent test**: each rule pinned by a dedicated test and guarded by
a deliberate mutant.

## Requirements

### Functional requirements

- **FR-001**: `AgentController.request<R>(event)` MUST delegate to the
  wrapped bus's typed request/response and behave identically to
  `EventBus.request<R>` (SC-003 parity).
- **FR-002**: `AgentController.on<T>(listener)` MUST subscribe exactly
  like `listen<T>` (documented alias).
- **FR-003**: `AgentController` MUST expose its wrapped `EventBus`
  (`bus` getter) — the handler-registration surface must be reachable
  through the wrap.
- **FR-004** (bus semantics, pinned): when multiple handlers are
  registered for a request type, the MOST RECENTLY registered handler
  responds (override semantics).
- **FR-005** (bus semantics, pinned): a handler exception MUST propagate
  to the awaiting requester.
- **FR-006** (bus semantics, pinned): `request` with no registered
  handler MUST throw `StateError` naming the request type.
- **FR-007** (bus semantics, pinned): the response cast MUST be honest —
  requesting `R` against a handler returning an incompatible type
  surfaces as a `TypeError`, never a silent value.
- **FR-008** (bus semantics, pinned): handlers registered after earlier
  requests serve later requests (registration is live, not cached at
  first use); distinct request types dispatch independently.
- **FR-009**: Gates — `dart analyze --fatal-infos` exit 0; full `dart
  test` green.

### Key entities

- `AgentController` — `publish()`, `listen<T>()`, `on<T>()`,
  `request<R>()`, `bus`.
- `EventBus` — unchanged surface: `on<T>`, `emit<T>`,
  `registerHandler<T,R>`, `request<R>`.

## Success criteria

- **SC-001**: Full request/response round-trip through the controller
  (US1).
- **SC-002**: Every pinned semantic (FR-004..FR-008) guarded by a test
  that a deliberate mutant kills.
- **SC-003**: Controller/bus parity for request (013 SC-003 extended).

## Dependencies

- Builds on: spec 013 A1–A4 (master `7fa7e82`) — the bus and controller
  exist; this spec completes them.
- Independent of: the memory arc PRs (#84/#87/#88) and 075
  EngineEventBus (PR #86) — different files, no conflicts.
