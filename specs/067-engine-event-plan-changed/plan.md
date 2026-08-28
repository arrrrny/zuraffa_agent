# Implementation Plan: EngineEvent.PlanChanged

**Branch**: `feat/spec-067-engine-event-plan-changed` | **Date**: 2026-08-28

## Summary

Grow the sealed EngineEvent union with its 10th member, `PlanChanged`,
wrapping the existing domain `PlanChangedEvent` payload. Mirrors the
per-event spec pattern of issues #16–#24; the event is born with the value
semantics established by spec 066.

## Phase 1 — Design

### Part file (`lib/src/engine/events/plan_changed.dart`)

```dart
part of 'engine_event.dart';

final class PlanChanged extends EngineEvent {
  final DateTime emittedAt;
  final PlanChangedEvent change;

  const PlanChanged({required this.emittedAt, required this.change});

  // == / hashCode / toString per spec 066 house pattern,
  // delegating payload rendering to PlanChangedEvent.toString
}
```

### engine_event.dart update

- `import '../../domain/entities/planner/plan_changed_event.dart';` after `library;`, before the parts (no cycle: planner entities import nothing from `engine/events`).
- `part 'plan_changed.dart';` after `part 'mission_completed.dart';`.

### Test update

- Shared `#24` group's `describe(EngineEvent)` switch gains
  `PlanChanged(:final change) => 'plan_changed(${change.next.id})',` —
  required for exhaustiveness the moment the union grows.
- New `spec 067 — EngineEvent.PlanChanged` group: is-A, payload round-trip
  (both `PlanState` snapshots are the exact instances), describe routing,
  value equality (equal `change` + equal `emittedAt` ⇒ equal; varying either
  ⇒ unequal), and exact `toString` (deterministic: empty-plan `PlanState`
  renders without `PlanStep` noise).

### Sequencing note

Branched independently off master. If merged before spec 066 (PR #77), no
gap: `PlanChanged` brings its own semantics. Open PRs #74–#76 contain their
own 9-arm describe switches; on merge they each need one added
`PlanChanged` arm (noted in this PR's body — inherent to growing a sealed
union, same as PRs #40/#41/#42 before it).

## Phase 2 — Tasks

See `tasks.md`.
