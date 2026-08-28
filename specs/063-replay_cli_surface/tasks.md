# Tasks: ReplayCliSurface (zfa agent replay)

- T1 Create `lib/src/domain/entities/replay_cli_surface/replay_cli_surface.dart`.
- T2 Create `lib/src/domain/services/replay_cli_surface_service.dart`.
- T3 Create `lib/src/data/providers/replay_cli_surface/replay_cli_surface_provider.dart`.
- T4 Create `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## TDD behavior markers (test-after plan; all DONE on master @ b9ba15c)

> Behavior ids referenced by `tdd/test-list.md` and `tdd/cycle-log.md`. Doc-only
> markers; the original T1-T7 implementation tasks above are unchanged.

- [x] [U1] `ReplayCliSurface` value equality across all four fields + hashCode — `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurface equality is value-based across all fields`
- [x] [U2] `ReplayCliSurface` inequality when a field differs — `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurface inequality differs when a field changes`
- [x] [U3] `ReplayCliSurfaceProvider` is a `ReplayCliSurfaceService` — `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider is a ReplayCliSurfaceService`
- [x] [U4] `current(NoParams)` returns the default active surface — `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider.current returns the active replay CLI surface`
- [x] [U5] `current(NoParams)` returns the injected value object — `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider honours an injected value object`
- [x] [U6] `count(NoParams)` returns 1 — `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart::ReplayCliSurfaceProvider.count returns 1`
