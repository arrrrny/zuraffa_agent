# Implementation Plan: EngineEvent.MissionCompleted

**Branch**: `16-engine-event-mission-completed` | **Date**: 2026-08-24

## Summary
Emitted when a mission finishes (success, fail, or cancelled). Pairs with MissionStarted (issue #17). Carries terminal status + optional summary. Mirrors #34 (TurnCompleted) exactly.

## Phase 1 — Design

### Part file
See `lib/src/engine/events/mission_completed.dart`.

### engine_event.dart update
Add `part 'mission_completed.dart';` after the last existing `part 'X.dart';` directive.

### Test update
Extend `describe(EngineEvent)` switch with `MissionCompleted` case. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
