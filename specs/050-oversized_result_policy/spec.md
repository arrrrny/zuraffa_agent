# Feature Specification: OversizedResultPolicy (summarize+artifactRef)

**Branch**: `050-oversized_result_policy` | **Date**: 2026-08-24

## Summary
Policy for oversized tool results — summarize + artifactRef before entering model context (epic #3 §R3.4, issue #4 US4). Keeps the context budget under control without losing the data. This advances epic issue #4 (Tools & MCP). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/oversized_result_policy/oversized_result_policy.dart` - `OversizedResultPolicy` value object (4 fields; value-based equality).
- `lib/src/domain/services/oversized_result_policy_service.dart` - abstract `OversizedResultPolicyService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/oversized_result_policy/oversized_result_policy_provider.dart` - concrete `OversizedResultPolicyProvider` stub (UnimplementedError bodies).
- `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/050-oversized_result_policy/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #4 (Tools & MCP)
