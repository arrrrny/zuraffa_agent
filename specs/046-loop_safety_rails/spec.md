**Template Version**: `zuraffa-1.0`

# Feature Specification: LoopSafetyRails typed outcomes

**Branch**: `feat/specs-046-047-048-049` | **Date**: 2026-08-28

## Summary
Typed stop outcomes — MaxTurnsExceeded, WallClockTimeout, LoopDetected — emitted by the loop's safety rails (epic #2 §R1.4, issue #2 US4). This advances epic issue #2 (Engine Core Loop). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Acceptance Criteria

| id | criterion | verified |
|----|-----------|----------|
1. **Given** the implemented feature **When** its acceptance criterion applies — | LoopSafetyRails is a plain Dart value object with 4 required fields (outcomeType, turnNumber, reason, emittedAt) and a const constructor | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
2. **Given** the implemented feature **When** its acceptance criterion applies — | Value equality holds when all 4 fields are identical; inequality is detected when any field differs | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
3. **Given** the implemented feature **When** its acceptance criterion applies — | hashCode is consistent with == (equal instances share hashCode) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
4. **Given** the implemented feature **When** its acceptance criterion applies — | LoopSafetyRailsService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
5. **Given** the implemented feature **When** its acceptance criterion applies — | LoopSafetyRailsProvider implements LoopSafetyRailsService and throws UnimplementedError for both methods | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance
6. **Given** the implemented feature **When** its acceptance criterion applies — | toString includes outcomeType and turnNumber | yes | — **Then** the pinned regression suite confirms it.
   **Type**: acceptance

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

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
7. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
9. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: outcomeType **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: turnNumber **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: reason **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: emittedAt **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** identical instances are equal via identical() shortcut **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** toString includes outcomeType and turnNumber **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
15. **Given** the feature implementation under its clean-architecture seams **When** toString includes reason **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
16. **Given** the feature implementation under its clean-architecture seams **When** toString omits emittedAt for readability **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
17. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider is a LoopSafetyRailsService **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
18. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider.current returns the active rails snapshot **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
19. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
20. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider constructor takes no arguments **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`).
   **Type**: acceptance
