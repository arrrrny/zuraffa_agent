**Template Version**: `zuraffa-1.0`

# Feature Specification: EngineEventBus error observability — no silent swallowing

**Branch**: `113-eventbus-error-observability` | **Date**: 2026-09-11

**Status**: Draft

**Input**: GitHub issue #134 — "Fix `EngineEventBus` silent error
swallowing". Severity: medium (area:observability, area:resilience).
Depends on spec 112 (structured logging, issue #119).

## Summary

`EngineEventBus` isolates subscriber exceptions (a throwing observer
never breaks its siblings) but routes the error to an optional
`onSubscriberError` hook and — per its own header — swallows it when no
hook is installed. A broken observer of `MissionCompleted` is invisible.
This spec gives the bus a default error route (a SEVERE record on the
`zuraffa.agent.eventBus` logger from spec 112) and a self-observation
surface (a new sealed `EngineEventSubscriberError` published onto the
bus itself), with a recursion guard so error events never cascade.

**Out of scope**: changing the delivery contract (synchronous,
registration order, error-isolated — all preserved), async subscribers,
retrying failed subscribers, and any new event kinds beyond
`EngineEventSubscriberError`.

## Files

- `lib/src/engine/events/subscriber_error.dart` — NEW part of the
  sealed `EngineEvent` library: `EngineEventSubscriberError(emittedAt,
  error, eventType)`.
- `lib/src/engine/engine_event_bus.dart` — MODIFIED: default
  `onSubscriberError` route (SEVERE log via the `eventBus` logger) +
  post-handling publication of the subscriber-error event + recursion
  guard.
- `test/tdd/113-eventbus-error-observability/` — gen'd behavior tests
  (acceptance + unit + contract lanes).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — A broken observer is visible by default (Priority: P1)

A host runs the bus with no error hook installed. A subscriber throws;
the throw is still isolated, and the incident surfaces as a SEVERE log
record naming the error and the event type.

**Why this priority**: this is the issue's core defect — silent
swallowing defeats observability.

**Independent Test**: subscribe a thrower and a recorder; publish; assert
the record arrived AND a SEVERE record on `zuraffa.agent.eventBus`
carries the error and source event type.

**Acceptance Scenarios**:

1. **Given** a bus with no `onSubscriberError` hook, **When** a
   **Type**: acceptance
   subscriber throws while a later subscriber observes the same event,
   **Then** the later subscriber still receives the event and a SEVERE
   record on the `eventBus` logger carries the thrown error and the
   source event's runtime type.
2. **Given** a bus with a consumer-provided `onSubscriberError` hook,
   **Type**: acceptance
   **When** a subscriber throws, **Then** the hook is invoked with the
   error and event, and the default SEVERE log record is NOT emitted.

### User Story 2 — The bus observes itself (Priority: P1)

The bus publishes an `EngineEventSubscriberError` (error + source event
type) onto itself after handling a subscriber failure, so the same
event-driven consumers that watch mission events can watch bus health —
without recursion when the failing event is itself an error event.

**Why this priority**: without a first-class surface, bus health is only
as good as the log pipeline; with it, bus errors compose with the rest
of the engine's observability model.

**Independent Test**: subscribe a recorder for
`EngineEventSubscriberError`; publish an event to a bus with a throwing
subscriber; assert one error event arrives with the right error and
source type; repeat with the failing event BEING an error event and
assert no new error event is published.

**Acceptance Scenarios**:

3. **Given** a subscriber to `EngineEventSubscriberError`, **When** a
   **Type**: acceptance
   subscriber of another event type throws, **Then** exactly one
   `EngineEventSubscriberError` is published carrying the thrown error
   and the source event's runtime type.
4. **Given** the failing event is itself an
   **Type**: acceptance
   `EngineEventSubscriberError`, **When** its subscriber throws,
   **Then** no NEW `EngineEventSubscriberError` is published (the
   recursion guard holds), and the SEVERE log record still fires.
5. **Given** an `onSubscriberError` hook that itself throws, **When** a
   **Type**: acceptance
   subscriber throws, **Then** `publish` still returns normally, later
   subscribers still receive the original event, and the incident is
   logged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: With no consumer hook installed, the bus MUST route
  subscriber errors to a SEVERE record on the `zuraffa.agent.eventBus`
  logger carrying the thrown error and the source event's runtime type.
  traces: EngineEventBus.logSubscriberError
- **FR-002**: A consumer-provided `onSubscriberError` hook MUST fully
  replace the default route (no duplicate default record) — the pre-113
  contract is preserved.
  traces: EngineEventBus.logSubscriberError
- **FR-003**: After the error route runs, the bus MUST publish an
  `EngineEventSubscriberError` (the thrown error + source event runtime
  type) to its current subscribers, EXCEPT when the failing event is
  itself an `EngineEventSubscriberError` — the recursion guard MUST
  prevent error events from cascading.
  traces: EngineEventBus.subscriberErrorEvent
- **FR-004**: A throwing hook or a throwing subscriber of the
  subscriber-error event MUST NOT break `publish`: isolation of sibling
  delivery is preserved and the failure is logged, never propagated.
  traces: EngineEventBus.logSubscriberError

### Non-Functional Requirements

- NFR-001: The sealed `EngineEvent` union grows by one hand-curated part
  (`subscriber_error.dart`) following the house pattern (no codegen
  annotations; `engine_event.g.dart` placeholder untouched).

## Layer Contracts

**Domain**:

- `EngineEventBus`: `logSubscriberError(error, event) -> void`, `subscriberErrorEvent(error, event) -> EngineEventSubscriberError`

### Key Entities

| Entity | Fields | Purpose |
|--------|--------|---------|
| `EngineEventSubscriberError` | `emittedAt: DateTime`, `error: Object`, `eventType: Type` | The bus's self-observation event for subscriber failures |

### External Dependencies & Contracts

| Dependency | Kind | Contract | Priority |
|--------|--------|--------|--------|
| AgentLog (spec 112) | internal facade | `eventBus` logger + SEVERE policy level | P1 |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: US1 fixtures pass — default SEVERE route fires with error
  + event type; custom hook replaces it (FR-001, FR-002).
- **SC-002**: US2 fixtures pass — one `EngineEventSubscriberError` per
  failure, none on error-event failures, guard holds (FR-003).
- **SC-003**: Isolation preserved — throwing hooks/subscribers never
  escape `publish` (FR-004).
- **SC-004**: `dart analyze` zero issues; full `dart test` green;
  purity gate unchanged.
