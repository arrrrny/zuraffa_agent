# Feature Specification: EngineEvent.ToolCallCompleted

**Branch**: `21-engine-event-tool-call-completed` | **Date**: 2026-08-24

## Summary
Add `ToolCallCompleted` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted by the tool dispatch layer when a tool implementation returns (success or error). Pairs with ToolCallStarted (issue #22). Correlated via callId.

## Files
- `lib/src/engine/events/tool_call_completed.dart` — `final class ToolCallCompleted extends EngineEvent` with `emittedAt: DateTime` + toolName: String, callId: String, ok: bool.
- `lib/src/engine/events/engine_event.dart` — add `part 'tool_call_completed.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `ToolCallCompleted` case; add is-A + payload tests.
- `specs/21-engine-event-tool-call-completed/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 144 tests pass

## Closes #21
