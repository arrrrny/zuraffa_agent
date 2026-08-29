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

## Phase N: TDD remediation

Feature is not done until the blocking finding below is cleared (verification.md F1, HIGH).

- [ ] T8 Pin the inclusive upper bound of `EngineLoopExecutor.runTurn`: add a test asserting `turnNumber == loop.maxTurns` does NOT throw StateError (only `> maxTurns` throws). Proof: `dart test test/data/providers/engine_loop/engine_loop_executor_test.dart --plain-name "runTurn does not throw at turnNumber == maxTurns"` exits 0, AND a `>`→`>=` mutant at `lib/src/data/providers/engine_loop/engine_loop_executor.dart:34` then fails that test (currently it survives — 3/3 pass).
