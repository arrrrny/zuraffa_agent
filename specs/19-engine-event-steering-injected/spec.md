# Feature Specification: EngineEvent.SteeringInjected

**Branch**: `19-engine-event-steering-injected` | **Date**: 2026-08-24

## Summary
Add `SteeringInjected` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted by the steering layer when an injected system message overrides the loop's next-iteration context. Pairs with spec-002 steering.

## Files
- `lib/src/engine/events/steering_injected.dart` — `final class SteeringInjected extends EngineEvent` with `emittedAt: DateTime` + content: String, injectedAt: DateTime.
- `lib/src/engine/events/engine_event.dart` — add `part 'steering_injected.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `SteeringInjected` case; add is-A + payload tests.
- `specs/19-engine-event-steering-injected/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 148 tests pass

## Closes #19
