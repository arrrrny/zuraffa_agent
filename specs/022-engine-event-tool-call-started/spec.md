# Feature Specification: EngineEvent.ToolCallStarted

**Branch**: `022-engine-event-tool-call-started` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary
Add `ToolCallStarted` as the third `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended by #34/#23). Emitted by the tool dispatch layer right before invoking a tool implementation.

## Files
- `lib/src/engine/events/tool_call_started.dart` — `final class ToolCallStarted extends EngineEvent { final DateTime emittedAt; final String toolName; final String callId; const ToolCallStarted({required this.emittedAt, required this.toolName, required this.callId}); }`
- `lib/src/engine/events/engine_event.dart` — add `part 'tool_call_started.dart';`
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `ToolCallStarted` case; add is-A + payload tests
- `specs/022-engine-event-tool-call-started/{spec,plan,tasks}.md`

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥145 tests pass

## Closes #22
