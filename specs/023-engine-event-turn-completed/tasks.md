# Tasks: EngineEvent.TurnCompleted
- T1 Create `lib/src/engine/events/turn_completed.dart` part file with `final class TurnCompleted extends EngineEvent`.
- T2 Patch `lib/src/engine/events/engine_event.dart` to add `part 'turn_completed.dart';`.
- T3 Patch `test/engine/events/engine_event_test.dart` to add TurnCompleted tests + extend the `describe` switch to be exhaustive (2 cases).
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
