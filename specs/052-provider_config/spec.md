**Template Version**: `zuraffa-1.0`

# Feature Specification: ProviderConfig (typed openai/anthropic/gemini)

**Branch**: `052-provider_config` | **Date**: 2026-08-24

## Summary
Typed provider configuration — base URL, API key reference, model list, timeouts (epic #4 §R4.1, issue #5 US1). Provider-specific subclasses carry vendor-only fields. This advances epic issue #5 (Providers & Fallback). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/provider_config/provider_config.dart` - `ProviderConfig` value object (5 fields; value-based equality).
- `lib/src/domain/services/provider_config_service.dart` - abstract `ProviderConfigService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/provider_config/provider_config_provider.dart` - concrete `ProviderConfigProvider` stub (UnimplementedError bodies).
- `test/data/providers/provider_config/provider_config_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/052-provider_config/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #5 (Providers & Fallback)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfig equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfig inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfigProvider is a ProviderConfigService **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfigProvider.current returns the active provider config **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** ProviderConfigProvider.count returns the configured provider count **Then** the pinned regression test passes (`test/data/providers/provider_config/provider_config_provider_test.dart`).
   **Type**: acceptance
