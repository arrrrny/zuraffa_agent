# Tasks: EngineEvent.MissionStarted
- T1 Create `mission_started.dart` part file with `final class MissionStarted extends EngineEvent`.
- T2 Patch `engine_event.dart` to add `part 'mission_started.dart';`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add MissionStarted tests.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
