# Tasks: LlmClient interface + LlmRequest/LlmResponse

- [U1] `LlmClient` value equality across all five fields (test: `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClient equality is value-based across all fields`)
- [U2] `LlmClient` inequality when any field changes (test: `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClient inequality differs when a field changes`)
- T1 Create `lib/src/domain/entities/llm_client/llm_client.dart`.
- T2 Create `lib/src/domain/services/llm_client_service.dart`.
- [U3] `LlmClientProvider` is a `LlmClientService` (test: `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider is a LlmClientService`)
- [U4] `LlmClientProvider.current(NoParams)` returns the active `LlmClient` resolved from config (test: `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.current returns the active LlmClient (no longer stubbed)`)
- [U5] `LlmClientProvider.count(NoParams)` returns 1 (test: `test/data/providers/llm_client/llm_client_provider_test.dart::LlmClientProvider.count returns the number of usable clients`)
- [U6] `LlmClientProvider.complete` forwards `ProviderConfig.timeoutMs` to transport timeout (test: `test/data/providers/llm_client/llm_client_provider_test.dart::forwards ProviderConfig.timeoutMs to the transport completion timeout`)
- T3 Create `lib/src/data/providers/llm_client/llm_client_provider.dart`.
- T4 Create `test/data/providers/llm_client/llm_client_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
