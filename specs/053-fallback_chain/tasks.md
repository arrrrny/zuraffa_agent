# Tasks: FallbackChain (advance policy + state)

- [U1] `FallbackChain` value equality across all fields (test: `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChain equality is value-based across all fields`)
- [U2] `FallbackChain` inequality when any field changes (test: `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChain inequality differs when a field changes`)
- T1 Create `lib/src/domain/entities/fallback_chain/fallback_chain.dart`.
- T2 Create `lib/src/domain/services/fallback_chain_service.dart`.
- [U3] `FallbackChainProvider` is a `FallbackChainService` (test: `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChainProvider is a FallbackChainService`)
- [U4] `FallbackChainProvider.current(NoParams)` returns the active chain snapshot (test: `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChainProvider.current returns the active chain snapshot`)
- [U5] `FallbackChainProvider.count(NoParams)` returns 1 (test: `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChainProvider.count returns 1`)
- T3 Create `lib/src/data/providers/fallback_chain/fallback_chain_provider.dart`.
- T4 Create `test/data/providers/fallback_chain/fallback_chain_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
