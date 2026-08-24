# Tasks: EngineEvent.ToolCallStarted
- T1 Create `tool_call_started.dart` part file.
- T2 Patch `engine_event.dart` to add `part 'tool_call_started.dart';`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add ToolCallStarted tests.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
