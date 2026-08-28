# Implementation Plan: EngineEvent value semantics

**Branch**: `feat/spec-066-engine-event-value-semantics` | **Date**: 2026-08-28

## Summary

Bring the 9 sealed-union EngineEvent subtypes to house value-object parity:
`==` (identical-or-runtimeType-and-fields), `hashCode` (`Object.hash` over all
fields), `toString` (all fields, declaration order). Mirrors the exact pattern
of `EngineLoop` (spec 045) and `PlanChangedEvent` (spec 014).

## Phase 1 — Design

### Per-subtype additions (9 part files)

Each part file gains, after the constructor:

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    (other is TurnStarted &&
        runtimeType == other.runtimeType &&
        emittedAt == other.emittedAt &&
        turnId == other.turnId);

@override
int get hashCode => Object.hash(emittedAt, turnId);

@override
String toString() => 'TurnStarted(emittedAt: $emittedAt, turnId: $turnId)';
```

Field order matches the field declaration order in every file. Nullable
fields (`turnId`, `reason`, `summary`) interpolate directly (`null` renders
as `null`).

### Test design

One new `spec 066 — EngineEvent value semantics` group in
`test/engine/events/engine_event_test.dart`, one block per subtype asserting:
(a) equality of two independently constructed identical events + inequality
when each field varies in turn, (b) hashCode equality for equal events, and
(c) exact `toString` output for a representative instance. Cross-subtype
inequality (same fields, different type) asserted once via `TurnStarted` vs
`MissionStarted` shape — wait, their fields differ; use the runtimeType guard
check via `ProviderError` vs a hypothetical — simpler: assert
`MissionCompleted(...) != MissionCompleted(...)` with one field changed and
assert a `TurnStarted` never equals a `TurnCompleted` (different runtimeType
even if both carry only emittedAt/reason-shaped data).

### Sequencing note

The 9 events are the union at master `30b4b94`. Spec 067 (`PlanChanged`)
branches independently and brings its own `==`/`hashCode`/`toString` at
birth, so merge order of 066/067 does not leave a semantics gap.

## Phase 2 — Tasks

See `tasks.md`.
