# Feature Specification: EngineEvent.ThinkingDelta

**Branch**: `20-engine-event-thinking-delta` | **Date**: 2026-08-24

## Summary
Add `ThinkingDelta` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted by the engine loop on every thinking-text delta chunk from the provider. Streamed; not persisted.

## Files
- `lib/src/engine/events/thinking_delta.dart` — `final class ThinkingDelta extends EngineEvent` with `emittedAt: DateTime` + delta: String.
- `lib/src/engine/events/engine_event.dart` — add `part 'thinking_delta.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `ThinkingDelta` case; add is-A + payload tests.
- `specs/20-engine-event-thinking-delta/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 146 tests pass

## Closes #20
