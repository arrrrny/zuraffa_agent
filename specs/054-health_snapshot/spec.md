# Feature Specification: HealthSnapshot (chain state)

**Branch**: `054-health_snapshot` | **Date**: 2026-08-24

## Summary
Health snapshot API — exposes chain state per provider (open/closed/half-open) and last-success timestamp (epic #4 §R4.5, issue #5 US4). Used by ops dashboards and the engine's preflight check. This advances epic issue #5 (Providers & Fallback). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/health_snapshot/health_snapshot.dart` - `HealthSnapshot` value object (5 fields; value-based equality).
- `lib/src/domain/services/health_snapshot_service.dart` - abstract `HealthSnapshotService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/health_snapshot/health_snapshot_provider.dart` - concrete `HealthSnapshotProvider` stub (UnimplementedError bodies).
- `test/data/providers/health_snapshot/health_snapshot_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/054-health_snapshot/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #5 (Providers & Fallback)
