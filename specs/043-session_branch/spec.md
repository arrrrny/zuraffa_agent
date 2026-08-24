# Feature Specification: SessionBranch (fork/switch/resume)

**Branch**: `043-session_branch` | **Date**: 2026-08-24

## Summary
Branching primitive — fork a session at entry N, switch between branches, resume either. Shares ancestry 1..N with the original (epic #1 §R2.2, issue #3 AC1+2). This advances epic issue #3 (State & Sessions). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/session_branch/session_branch.dart` - `SessionBranch` value object (5 fields; value-based equality).
- `lib/src/domain/services/session_branch_service.dart` - abstract `SessionBranchService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/session_branch/session_branch_provider.dart` - concrete `SessionBranchProvider` stub (UnimplementedError bodies).
- `test/data/providers/session_branch/session_branch_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/043-session_branch/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #3 (State & Sessions)
