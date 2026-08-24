# Implementation Plan: EngineEvent.TurnCompleted

**Branch**: `023-engine-event-turn-completed` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary
Add `TurnCompleted` as the second `final class` part of the hand-curated `lib/src/engine/events/engine_event.dart` sealed library (established by PR #33). Update the existing `switch` test in `engine_event_test.dart` to handle both subtypes exhaustively.

## Technical Context
- Language: Dart 3.13.1
- Constraints: no `dart:io`; no new analyzer warnings; existing 139 tests must still pass.

## Phase 1 — Design

### Part file
```dart
// lib/src/engine/events/turn_completed.dart
part of 'engine_event.dart';

final class TurnCompleted extends EngineEvent {
  final DateTime emittedAt;
  final String? reason;
  const TurnCompleted({required this.emittedAt, this.reason});
}
```

### engine_event.dart update
Add `part 'turn_completed.dart';` after the existing `part 'turn_started.dart';` line.

### Test update
Extend `test/engine/events/engine_event_test.dart`:
- Add `TurnCompleted is an EngineEvent` test
- Update the existing `describe(EngineEvent)` switch expression to handle both TurnStarted and TurnCompleted (exhaustive with no default arm)
- Add `TurnCompleted carries emittedAt + optional reason` test

## Phase 2 — Tasks
See `tasks.md`.
