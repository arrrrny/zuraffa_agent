# Tasks: ReplayDiff (input drift detection)

- T1 Create `lib/src/domain/entities/replay_diff/replay_diff.dart`.
- T2 Create `lib/src/domain/services/replay_diff_service.dart`.
- T3 Create `lib/src/data/providers/replay_diff/replay_diff_provider.dart`.
- T4 Create `test/data/providers/replay_diff/replay_diff_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## TDD behavior markers (test-after plan; all DONE on master @ b9ba15c)

> Behavior ids referenced by `tdd/test-list.md` and `tdd/cycle-log.md`. Doc-only
> markers; the original T1-T7 implementation tasks above are unchanged.

- [x] [U1] `ReplayDiff` value equality across all four fields + hashCode — `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiff equality is value-based across all fields`
- [x] [U2] `ReplayDiff` inequality when a field differs — `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiff inequality differs when a field changes`
- [x] [U3] `ReplayDiffProvider` is a `ReplayDiffService` — `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider is a ReplayDiffService`
- [x] [U4] `current(NoParams)` returns the default active snapshot — `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider.current returns the active replay diff`
- [x] [U5] `current(NoParams)` returns the injected value object — `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider honours an injected value object`
- [x] [U6] `count(NoParams)` returns 1 — `test/data/providers/replay_diff/replay_diff_provider_test.dart::ReplayDiffProvider.count returns 1`
