# Feature Specification: PassKEmpirical (pass^k metric)

**Branch**: `061-pass_k_empirical` | **Date**: 2026-08-24

## Summary
pass^k empirical metric — fraction of k independent runs that succeeded (epic #6 §R6.2, issue #7 US2). Complements the existing pass@k unbiased estimator (spec 037). This advances epic issue #7 (Eval Harness). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/pass_k_empirical/pass_k_empirical.dart` - `PassKEmpirical` value object (5 fields; value-based equality).
- `lib/src/domain/services/pass_k_empirical_service.dart` - abstract `PassKEmpiricalService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/pass_k_empirical/pass_k_empirical_provider.dart` - concrete `PassKEmpiricalProvider` stub (UnimplementedError bodies).
- `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/061-pass_k_empirical/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #7 (Eval Harness)
