# Tasks: Agent memory — three layers

- T1 Write `specs/073-agent-memory/{spec,plan,tasks}.md` + `tdd/test-list.md`.
- T2 Write `test/engine/agent_memory_test.dart` FIRST; run — RED is the missing-`agent_memory.dart` compile failure; record evidence.
- T3 Implement `lib/src/engine/agent_memory.dart`; green the file.
- T4 Deliberate mutants M1–M5 (cp-restored): salience ranking dropped; recall long-term-only; promote copy-without-remove; neighborsOf outgoing-only; duplicate-link throws. Record kill/survive + evidence.
- T5 Gates: `dart analyze --fatal-infos` + full `dart test`; record actual counts vs baseline 915/2.
- T6 Write `tdd/verification.md`; commit artifacts WITH the code; push; PR (base master).
