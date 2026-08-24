# Feature Specification: ReplayCliSurface (zfa agent replay)

**Branch**: `063-replay_cli_surface` | **Date**: 2026-08-24

## Summary
zfa agent replay CLI surface — declarative replay invocation (mission id, recorded traffic, grader matrix) (epic #6 §R6.4, issue #7 US4). This advances epic issue #7 (Eval Harness). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/replay_cli_surface/replay_cli_surface.dart` - `ReplayCliSurface` value object (4 fields; value-based equality).
- `lib/src/domain/services/replay_cli_surface_service.dart` - abstract `ReplayCliSurfaceService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/replay_cli_surface/replay_cli_surface_provider.dart` - concrete `ReplayCliSurfaceProvider` stub (UnimplementedError bodies).
- `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/063-replay_cli_surface/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #7 (Eval Harness)
