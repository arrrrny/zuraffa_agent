# Tasks: CompactionStrategy (selective retain/summarize)

- [U1] Add regression test: CompactionStrategy value equality across all six fields + hashCode (DONE).
- [U2] Add regression test: CompactionStrategy inequality when any field differs (DONE).
- T1 Create `lib/src/domain/entities/compaction_strategy/compaction_strategy.dart`.
- T2 Create `lib/src/domain/services/compaction_strategy_service.dart`.
- [U3] Add regression test: CompactionStrategyProvider is a CompactionStrategyService (DONE).
- [U4] Add regression test: CompactionStrategyProvider.current returns the active strategy (DONE).
- [U5] Add regression test: CompactionStrategyProvider honors an injected active strategy (DONE).
- [U6] Add regression test: CompactionStrategyProvider.count returns 1 (DONE).
- T3 Create `lib/src/data/providers/compaction_strategy/compaction_strategy_provider.dart`.
- T4 Create `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
