# Tasks: Engine event bus

- T1 Write `specs/075-engine-event-bus/{spec,plan,tasks}.md` + `tdd/test-list.md`.
- T2 Write `test/engine/engine_event_bus_test.dart` FIRST; run — RED is the missing-`engine_event_bus.dart` compile failure; record evidence.
- T3 Implement `lib/src/engine/engine_event_bus.dart`; green the file.
- T4 Deliberate mutants M1–M5 (cp-restored): first-matching-only delivery; type filter dropped; reversed replay; isolation removed; cancel no-op. Record kill/survive + evidence.
- T5 Gates: `dart analyze --fatal-infos` + full `dart test`; record actual counts vs baseline 915/2.
- T6 Write `tdd/verification.md`; commit artifacts WITH the code; push; PR (base master).
