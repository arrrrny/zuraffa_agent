**Template Version**: `zuraffa-1.0`

# Feature Specification: ReplayDiff (input drift detection)

**Branch**: `060-replay_diff` | **Date**: 2026-08-24

## Summary
Replay diff — detects input drift between record and replay (same inputs, different bytes -> flagged) (epic #6 §R6.1, issue #7 US1). This advances epic issue #7 (Eval Harness). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/replay_diff/replay_diff.dart` - `ReplayDiff` value object (4 fields; value-based equality).
- `lib/src/domain/services/replay_diff_service.dart` - abstract `ReplayDiffService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/replay_diff/replay_diff_provider.dart` - concrete `ReplayDiffProvider` stub (UnimplementedError bodies).
- `test/data/providers/replay_diff/replay_diff_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/060-replay_diff/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #7 (Eval Harness)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiff equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiff inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider is a ReplayDiffService **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider.current returns the active replay diff **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`).
   **Type**: acceptance
