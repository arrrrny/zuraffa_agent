# Tasks: EngineEvent.SteeringInjected
- T1 Create `steering_injected.dart` part file with `final class SteeringInjected extends EngineEvent`.
- T2 Patch `engine_event.dart` to add `part 'steering_injected.dart';`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add SteeringInjected tests.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
