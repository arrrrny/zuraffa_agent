# Feature Specification: LoopSafetyRails typed outcomes

**Branch**: `046-loop_safety_rails` | **Date**: 2026-08-24

## Summary
Typed stop outcomes — MaxTurnsExceeded, WallClockTimeout, LoopDetected — emitted by the loop's safety rails (epic #2 §R1.4, issue #2 US4). This advances epic issue #2 (Engine Core Loop). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/loop_safety_rails/loop_safety_rails.dart` - `LoopSafetyRails` value object (4 fields; value-based equality).
- `lib/src/domain/services/loop_safety_rails_service.dart` - abstract `LoopSafetyRailsService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/loop_safety_rails/loop_safety_rails_provider.dart` - concrete `LoopSafetyRailsProvider` stub (UnimplementedError bodies).
- `test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/046-loop_safety_rails/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #2 (Engine Core Loop)
