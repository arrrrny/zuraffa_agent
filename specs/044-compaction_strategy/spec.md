**Template Version**: `zuraffa-1.0`

# Feature Specification: CompactionStrategy (selective retain/summarize)

**Branch**: `044-compaction_strategy` | **Date**: 2026-08-24

## Summary
Selective compaction policy — retain decisions/tool names/key results/plan state verbatim; replace verbose outputs with structured summaries referencing artifacts (epic #1 §R2.3, issue #3 AC1). This advances epic issue #3 (State & Sessions). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/compaction_strategy/compaction_strategy.dart` - `CompactionStrategy` value object (6 fields; value-based equality).
- `lib/src/domain/services/compaction_strategy_service.dart` - abstract `CompactionStrategyService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/compaction_strategy/compaction_strategy_provider.dart` - concrete `CompactionStrategyProvider` stub (UnimplementedError bodies).
- `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/044-compaction_strategy/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #3 (State & Sessions)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategy equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategy inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider is a CompactionStrategyService **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider.current returns the active strategy **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider honors an injected active strategy **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`).
   **Type**: acceptance
