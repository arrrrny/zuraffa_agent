# Feature Specification: EngineEvent.MissionStarted

**Branch**: `17-engine-event-mission-started` | **Date**: 2026-08-24

## Summary
Add `MissionStarted` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted when a mission begins. Pairs with MissionCompleted (issue #16). Carries the mission spec id + startedAt.

## Files
- `lib/src/engine/events/mission_started.dart` — `final class MissionStarted extends EngineEvent` with `emittedAt: DateTime` + missionId: String, startedAt: DateTime.
- `lib/src/engine/events/engine_event.dart` — add `part 'mission_started.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `MissionStarted` case; add is-A + payload tests.
- `specs/17-engine-event-mission-started/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 152 tests pass

## Closes #17
