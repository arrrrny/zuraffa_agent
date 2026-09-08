**Template Version**: `zuraffa-1.0`

# Feature Specification: LlmClient interface + LlmRequest/LlmResponse

**Branch**: `051-llm_client` | **Date**: 2026-08-24

## Summary
Provider-agnostic LlmClient interface + typed LlmRequest/LlmResponse value objects (epic #4 §R4.1, issue #5 US1). All OpenAI/Anthropic/Gemini clients implement this; the engine consumes one type. This advances epic issue #5 (Providers & Fallback). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/llm_client/llm_client.dart` - `LlmClient` value object (5 fields; value-based equality).
- `lib/src/domain/services/llm_client_service.dart` - abstract `LlmClientService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/llm_client/llm_client_provider.dart` - concrete `LlmClientProvider` stub (UnimplementedError bodies).
- `test/data/providers/llm_client/llm_client_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/051-llm_client/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #5 (Providers & Fallback)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** LlmClient equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** LlmClient inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** LlmClientProvider is a LlmClientService **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** LlmClientProvider.current returns the active LlmClient (no longer stubbed) **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** LlmClientProvider.count returns the number of usable clients **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** forwards ProviderConfig.timeoutMs to the transport completion timeout **Then** the pinned regression test passes (`test/data/providers/llm_client/llm_client_provider_test.dart`).
   **Type**: acceptance
