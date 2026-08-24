# Implementation Plan: EngineEvent.MissionStarted

**Branch**: `17-engine-event-mission-started` | **Date**: 2026-08-24

## Summary
Emitted when a mission begins. Pairs with MissionCompleted (issue #16). Carries the mission spec id + startedAt. Mirrors #34 (TurnCompleted) exactly.

## Phase 1 — Design

### Part file
See `lib/src/engine/events/mission_started.dart`.

### engine_event.dart update
Add `part 'mission_started.dart';` after the last existing `part 'X.dart';` directive.

### Test update
Extend `describe(EngineEvent)` switch with `MissionStarted` case. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
