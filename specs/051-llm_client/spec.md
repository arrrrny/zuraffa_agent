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
