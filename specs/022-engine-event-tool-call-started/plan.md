# Implementation Plan: EngineEvent.ToolCallStarted
**Branch**: `022-engine-event-tool-call-started` | **Date**: 2026-08-24

## Summary
Third `final class` part of the hand-curated `engine_event.dart` sealed library. Mirrors #34 (TurnCompleted) exactly. Carries `emittedAt`, `toolName`, `callId`.

## Phase 1 — Design

### Part file
```dart
// lib/src/engine/events/tool_call_started.dart
part of 'engine_event.dart';
final class ToolCallStarted extends EngineEvent {
  final DateTime emittedAt;
  final String toolName;
  final String callId;
  const ToolCallStarted({required this.emittedAt, required this.toolName, required this.callId});
}
```

### engine_event.dart update
Add `part 'tool_call_started.dart';` after `part 'turn_completed.dart';`.

### Test update
Extend `describe(EngineEvent)` switch with `ToolCallStarted(:final toolName) => 'tool_call_started($toolName)'`. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
