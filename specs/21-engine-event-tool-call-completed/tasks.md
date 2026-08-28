# Tasks: EngineEvent.ToolCallCompleted

> TEST-AFTER: the class and its tests already ship on master and the suite is green.
> Behavior ids below trace to `tdd/test-list.md`. Tests DONE; see the discrepancy note there
> (no dedicated `describe` routing-assertion test for #21, unlike #16/#17/#18).

- [ ] [U1] Test: `ToolCallCompleted` is `is EngineEvent` AND `is ToolCallCompleted`; `final class` part file with `emittedAt`, `toolName`, `callId`, `ok`.
- T1 Create `tool_call_completed.dart` part file with `final class ToolCallCompleted extends EngineEvent`.
- [ ] [U2] Test: `emittedAt`/`toolName`/`callId`/`ok` constructor params bind to same-named fields (distinct values, no cross-binding).
- [ ] [U3] Test: `engine_event.dart` includes `part 'tool_call_completed.dart';` (sealed library picks it up — CI analyze proves it).
- T2 Patch `engine_event.dart` to add `part 'tool_call_completed.dart';`.
- [ ] [U4] Test: `describe(EngineEvent)` switch handles `ToolCallCompleted` (exhaustive, no default arm) and routes to `tool_call_completed(toolName)`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add ToolCallCompleted tests.
- [ ] [A3] Test gate: `dart analyze --fatal-infos` exits 0.
- [ ] [A4] Test gate: `dart test` passes (full suite green baseline).
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
