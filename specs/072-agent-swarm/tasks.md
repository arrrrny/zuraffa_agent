# Tasks: Agent swarm

- T1 Write `specs/072-agent-swarm/{spec,plan,tasks}.md` + `tdd/test-list.md`.
- T2 Write `test/engine/agent_swarm_test.dart` FIRST; run — RED is the missing-`agent_swarm.dart` compile failure; record evidence.
- T3 Implement `lib/src/engine/agent_swarm.dart`; green the file.
- T4 Deliberate mutants M1–M5 (cp-restored): sequential fan-out; allCompleted ignores failures; firstCompleted by submission order; quorum counts failures; winner never set. Record kill/survive + evidence.
- T5 Gates: `dart analyze --fatal-infos` + full `dart test`; record actual counts vs baseline 937/2.
- T6 Write `tdd/verification.md`; commit artifacts WITH the code; push; PR (base `feat/spec-070-sub-agent-dispatch`).
