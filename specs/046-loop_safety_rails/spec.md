# Feature Specification: LoopSafetyRails typed outcomes

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Typed stop outcomes — MaxTurnsExceeded, WallClockTimeout, LoopDetected — emitted by the loop's safety rails (epic #2 §R1.4, issue #2 US4). This advances epic issue #2 (Engine Core Loop). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
| AC-1 | LoopSafetyRails is a plain Dart value object with 4 required fields (outcomeType, turnNumber, reason, emittedAt) and a const constructor | yes |
| AC-2 | Value equality holds when all 4 fields are identical; inequality is detected when any field differs | yes |
| AC-3 | hashCode is consistent with == (equal instances share hashCode) | yes |
| AC-4 | LoopSafetyRailsService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes |
| AC-5 | LoopSafetyRailsProvider implements LoopSafetyRailsService and throws UnimplementedError for both methods | yes |
| AC-6 | toString includes outcomeType and turnNumber | yes |

## Files
- `lib/src/domain/entities/loop_safety_rails/loop_safety_rails.dart` - `LoopSafetyRails` value object (4 fields; value-based equality).
- `lib/src/domain/services/loop_safety_rails_service.dart` - abstract `LoopSafetyRailsService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/loop_safety_rails/loop_safety_rails_provider.dart` - concrete `LoopSafetyRailsProvider` stub (UnimplementedError bodies).
- `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` - regression tests (entity equality + clean-arch + toString).
- `specs/046-loop_safety_rails/{spec,plan,tasks}.md`.
- `specs/046-loop_safety_rails/tdd/{test-list,verification}.md`.

## Verification
- `dart pub get` clean
- `dart analyze` - No new issues
- `dart test` - All pre-existing + new tests pass

## Advances #2 (Engine Core Loop)
