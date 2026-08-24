# Feature Specification: FallbackChain (advance policy + state)

**Branch**: `053-fallback_chain` | **Date**: 2026-08-24

## Summary
Fallback chain — advances on connection/timeout/5xx/context-overflow/repeated-429 with per-provider circuit breaker (epic #4 §R4.4, issue #5 US3). Tracks current provider, last error class, advance history. This advances epic issue #5 (Providers & Fallback). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/fallback_chain/fallback_chain.dart` - `FallbackChain` value object (5 fields; value-based equality).
- `lib/src/domain/services/fallback_chain_service.dart` - abstract `FallbackChainService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/fallback_chain/fallback_chain_provider.dart` - concrete `FallbackChainProvider` stub (UnimplementedError bodies).
- `test/data/providers/fallback_chain/fallback_chain_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/053-fallback_chain/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #5 (Providers & Fallback)
