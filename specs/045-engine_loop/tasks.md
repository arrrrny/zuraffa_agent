# Tasks: EngineLoop (while-loop executor)

- [U1] Add regression test: EngineLoop value equality across all five fields + hashCode (DONE).
- [U2] Add regression test: EngineLoop inequality when any field differs (DONE).
- T1 Create `lib/src/domain/entities/engine_loop/engine_loop.dart`.
- T2 Create `lib/src/domain/services/engine_loop_service.dart`.
- [U3] Add regression test: EngineLoopProvider is a EngineLoopService (DONE).
- [U4] Add regression test: EngineLoopProvider.current returns the active loop config (DONE).
- [U5] Add regression test: EngineLoopProvider.count returns 1 (DONE).
- T3 Create `lib/src/data/providers/engine_loop/engine_loop_provider.dart`.
- [U6] Add regression test: EngineLoopExecutor.runTurn delegates to the LLM client and returns the completion (DONE).
- [U7] Add regression test: EngineLoopExecutor.runTurn throws StateError when turnNumber exceeds maxTurns (DONE).
- [U8] Add regression test: EngineLoopExecutor.runTurn throws StateError for a non-positive turnNumber (DONE).
- T4 Create `test/data/providers/engine_loop/engine_loop_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
