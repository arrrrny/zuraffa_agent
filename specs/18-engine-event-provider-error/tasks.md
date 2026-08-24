# Tasks: EngineEvent.ProviderError
- T1 Create `provider_error.dart` part file with `final class ProviderError extends EngineEvent`.
- T2 Patch `engine_event.dart` to add `part 'provider_error.dart';`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add ProviderError tests.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
