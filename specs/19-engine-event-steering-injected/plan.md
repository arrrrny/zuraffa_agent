# Implementation Plan: EngineEvent.SteeringInjected

**Branch**: `19-engine-event-steering-injected` | **Date**: 2026-08-24

## Summary
Emitted by the steering layer when an injected system message overrides the loop's next-iteration context. Pairs with spec-002 steering. Mirrors #34 (TurnCompleted) exactly.

## Phase 1 — Design

### Part file
See `lib/src/engine/events/steering_injected.dart`.

### engine_event.dart update
Add `part 'steering_injected.dart';` after the last existing `part 'X.dart';` directive.

### Test update
Extend `describe(EngineEvent)` switch with `SteeringInjected` case. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
