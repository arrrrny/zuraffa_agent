# Implementation Plan: EngineEvent.ThinkingDelta

**Branch**: `20-engine-event-thinking-delta` | **Date**: 2026-08-24

## Summary
Emitted by the engine loop on every thinking-text delta chunk from the provider. Streamed; not persisted. Mirrors #34 (TurnCompleted) exactly.

## Phase 1 — Design

### Part file
See `lib/src/engine/events/thinking_delta.dart`.

### engine_event.dart update
Add `part 'thinking_delta.dart';` after the last existing `part 'X.dart';` directive.

### Test update
Extend `describe(EngineEvent)` switch with `ThinkingDelta` case. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
