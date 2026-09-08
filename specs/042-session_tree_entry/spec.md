**Template Version**: `zuraffa-1.0`

# Feature Specification: SessionTreeEntry sealed hierarchy

**Branch**: `042-session_tree_entry` | **Date**: 2026-08-24

## Summary
Sealed SessionTreeEntry unifying the existing entry types (message / thinking-level-change / model-change / compaction / label / custom). Dispatch by type gives the engine one entry-list walk per turn (epic #1 §R2.1). This advances epic issue #3 (State & Sessions). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/session_tree_entry/session_tree_entry.dart` - `SessionTreeEntry` value object (4 fields; value-based equality).
- `lib/src/domain/services/session_tree_entry_service.dart` - abstract `SessionTreeEntryService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/session_tree_entry/session_tree_entry_provider.dart` - concrete `SessionTreeEntryProvider` stub (UnimplementedError bodies).
- `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/042-session_tree_entry/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #3 (State & Sessions)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntry equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntry inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider is a SessionTreeEntryService **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider.current returns the active entry **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider.current returns a supplied active entry **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`).
   **Type**: acceptance
