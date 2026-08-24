# Implementation Plan: EngineEvent.ToolCallCompleted

**Branch**: `21-engine-event-tool-call-completed` | **Date**: 2026-08-24

## Summary
Emitted by the tool dispatch layer when a tool implementation returns (success or error). Pairs with ToolCallStarted (issue #22). Correlated via callId. Mirrors #34 (TurnCompleted) exactly.

## Phase 1 — Design

### Part file
See `lib/src/engine/events/tool_call_completed.dart`.

### engine_event.dart update
Add `part 'tool_call_completed.dart';` after the last existing `part 'X.dart';` directive.

### Test update
Extend `describe(EngineEvent)` switch with `ToolCallCompleted` case. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
