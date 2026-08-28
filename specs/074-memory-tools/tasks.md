# Tasks: Memory tools — the agent-facing surface

- T1 Write `specs/074-memory-tools/{spec,plan,tasks}.md` + `tdd/test-list.md`.
- T2 Write `test/engine/memory_tools_test.dart` FIRST; run — RED is the missing-`memory_tools.dart` compile failure; record evidence.
- T3 Implement `lib/src/engine/memory_tools.dart`; green the file.
- T4 Deliberate mutants M1–M5 (cp-restored): remember skips write; recall limit ignored; link type hardcoded; projection insertion order; session_id ignored. Record kill/survive + evidence.
- T5 Gates: `dart analyze --fatal-infos` + full `dart test`; record actual counts vs baseline 925/2.
- T6 Write `tdd/verification.md`; commit artifacts WITH the code; push; PR (base `feat/spec-073-agent-memory`).
