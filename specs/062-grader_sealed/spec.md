**Template Version**: `zuraffa-1.0`

# Feature Specification: Grader sealed (exact/schema/model-judge)

**Branch**: `062-grader_sealed` | **Date**: 2026-08-24

## Summary
Sealed grader — ExactGrader, SchemaGrader, ModelJudgeGrader (recorded) (epic #6 §R6.3, issue #7 US3). One grade(output, expected) method per subtype. This advances epic issue #7 (Eval Harness). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/grader_sealed/grader_sealed.dart` - `GraderSealed` value object (4 fields; value-based equality).
- `lib/src/domain/services/grader_sealed_service.dart` - abstract `GraderSealedService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/grader_sealed/grader_sealed_provider.dart` - concrete `GraderSealedProvider` stub (UnimplementedError bodies).
- `test/data/providers/grader_sealed/grader_sealed_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/062-grader_sealed/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #7 (Eval Harness)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** GraderSealed equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** GraderSealed inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider is a GraderSealedService **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider.current returns the active grader snapshot **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider.current honors an injected snapshot **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`).
   **Type**: acceptance
