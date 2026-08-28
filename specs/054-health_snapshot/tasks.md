# Tasks: HealthSnapshot (chain state)

- [U1] `HealthSnapshot` value equality across all five fields (test: `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshot equality is value-based across all fields`)
- [U2] `HealthSnapshot` inequality when any field changes (test: `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshot inequality differs when a field changes`)
- T1 Create `lib/src/domain/entities/health_snapshot/health_snapshot.dart`.
- T2 Create `lib/src/domain/services/health_snapshot_service.dart`.
- [U3] `HealthSnapshotProvider` is a `HealthSnapshotService` (test: `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider is a HealthSnapshotService`)
- [U4] `HealthSnapshotProvider.current(NoParams)` returns the active chain snapshot (test: `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider.current returns the active chain snapshot`)
- [U5] `HealthSnapshotProvider.count(NoParams)` returns 1 (test: `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider.count returns 1`)
- [U6] `HealthSnapshotProvider.current(NoParams)` honours an injected value object (test: `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider honours an injected value object`)
- T3 Create `lib/src/data/providers/health_snapshot/health_snapshot_provider.dart`.
- T4 Create `test/data/providers/health_snapshot/health_snapshot_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
