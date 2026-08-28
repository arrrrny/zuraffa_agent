# Tasks: ProviderConfig (typed openai/anthropic/gemini)

- [U1] `ProviderConfig` value equality across all five fields (test: `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfig equality is value-based across all fields`)
- [U2] `ProviderConfig` inequality when any field changes (test: `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfig inequality differs when a field changes`)
- T1 Create `lib/src/domain/entities/provider_config/provider_config.dart`.
- T2 Create `lib/src/domain/services/provider_config_service.dart`.
- [U3] `ProviderConfigProvider` is a `ProviderConfigService` (test: `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfigProvider is a ProviderConfigService`)
- [U4] `ProviderConfigProvider.current(NoParams)` returns the active provider config (test: `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfigProvider.current returns the active provider config`)
- [U5] `ProviderConfigProvider.count(NoParams)` returns 1 (test: `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfigProvider.count returns the configured provider count`)
- T3 Create `lib/src/data/providers/provider_config/provider_config_provider.dart`.
- T4 Create `test/data/providers/provider_config/provider_config_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
