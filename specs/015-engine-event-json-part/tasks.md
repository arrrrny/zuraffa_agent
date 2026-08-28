# Tasks: EngineEvent json_serializable part directive
- [x] [U1] `engine_event.dart` carries `part 'engine_event.g.dart';` after the 9 subtype parts — verified by package compile (`test/engine/events/engine_event_test.dart` regression gate)
- [x] [U2] `engine_event.g.dart` declares `part of 'engine_event.dart';` and compiles — verified by package compile (`test/engine/events/engine_event_test.dart` regression gate)
- T1 Add `part 'engine_event.g.dart';` directive to `engine_event.dart` after the 9 subtype parts.
- T2 Create `lib/src/engine/events/engine_event.g.dart` placeholder part file.
- T3 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T4 Commit + push + PR + merge + pull + re-test.
