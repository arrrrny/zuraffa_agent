# Feature Specification: EngineEvent.MissionCompleted

**Branch**: `16-engine-event-mission-completed` | **Date**: 2026-08-24

## Summary
Add `MissionCompleted` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted when a mission finishes (success, fail, or cancelled). Pairs with MissionStarted (issue #17). Carries terminal status + optional summary.

## Files
- `lib/src/engine/events/mission_completed.dart` — `final class MissionCompleted extends EngineEvent` with `emittedAt: DateTime` + missionId: String, status: String, summary: String?.
- `lib/src/engine/events/engine_event.dart` — add `part 'mission_completed.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `MissionCompleted` case; add is-A + payload tests.
- `specs/16-engine-event-mission-completed/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 154 tests pass

## Closes #16
