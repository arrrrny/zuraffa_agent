# Implementation Plan: EngineEventLog

**Branch**: `feat/spec-068-engine-event-log` | **Date**: 2026-08-28

## Summary

A plain-Dart, append-only, in-memory `EngineEventLog` with synchronous
typed/temporal projections — the recording primitive beneath the future
event bus (spec 013) and the eval harness (epic #7). Pattern: house
read-projection like `UsageLedger` (plain Dart, no @Zorphy, no dart:io).

## Phase 1 — Design

### Public API (`lib/src/engine/events/engine_event_log.dart`)

```dart
import 'engine_event.dart';

/// Append-only, in-memory log of [EngineEvent]s with typed and
/// temporal projections.
class EngineEventLog {
  final List<EngineEvent> _events = [];

  void add(EngineEvent event);              // FR-001
  void addAll(Iterable<EngineEvent> events);// FR-001 (iteration order)

  List<EngineEvent> get events;             // FR-002: List.unmodifiable copy
  int get length;                           // FR-002
  bool get isEmpty;                         // FR-002
  bool get isNotEmpty;                      // FR-002

  List<T> byType<T extends EngineEvent>();  // FR-003
  T? firstOfType<T extends EngineEvent>();  // FR-003
  T? lastOfType<T extends EngineEvent>();   // FR-003

  List<EngineEvent> since(DateTime cutoff, {bool inclusive = true}); // FR-004
  List<EngineEvent> before(DateTime cutoff, {bool inclusive = false}); // FR-004
}
```

Notes:
- `List.unmodifiable(_events)` per read: O(n) copy, fine for V1; the
  return contract (throws on mutation, never aliases internal state) is
  what the tests pin.
- `byType<T>` uses `whereType<T>()`; `firstOfType`/`lastOfType` fold via
  `whereType<T>().firstOrNull/lastOrNull`-equivalent explicit loops (no
  collection package dependency — engine purity).
- Temporal filters compare `event.emittedAt` against `cutoff`; boundaries
  tested with identical instants (inclusive true/false).

### Barrel export

`lib/zuraffa_agent.dart` gains `export 'src/engine/events/engine_event_log.dart';`
next to the existing engine_event export.

### Test design (`test/engine/events/engine_event_log_test.dart`)

Fixtures use fixed `DateTime.utc` values and the 9 master events
(Distinct payloads so type-filter results are unambiguous; the log is
union-size agnostic — spec 067's `PlanChanged` is not needed here).
Same-instance assertions via `same(...)` keep this spec independent of
spec 066's `==` (any merge order works).

## Phase 2 — Tasks

See `tasks.md`.
