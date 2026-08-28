# Tasks: Grader sealed (exact/schema/model-judge)

- T1 Create `lib/src/domain/entities/grader_sealed/grader_sealed.dart`.
- T2 Create `lib/src/domain/services/grader_sealed_service.dart`.
- T3 Create `lib/src/data/providers/grader_sealed/grader_sealed_provider.dart`.
- T4 Create `test/data/providers/grader_sealed/grader_sealed_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## TDD behavior markers (test-after plan; all DONE on master @ b9ba15c)

> Behavior ids referenced by `tdd/test-list.md` and `tdd/cycle-log.md`. Doc-only
> markers; the original T1-T7 implementation tasks above are unchanged.

- [x] [U1] `GraderSealed` value equality across all four fields + hashCode — `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealed equality is value-based across all fields`
- [x] [U2] `GraderSealed` inequality when a field differs — `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealed inequality differs when a field changes`
- [x] [U3] `GraderSealedProvider` is a `GraderSealedService` — `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider is a GraderSealedService`
- [x] [U4] `current(NoParams)` returns the default active snapshot — `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider.current returns the active grader snapshot`
- [x] [U5] `current(NoParams)` returns the injected snapshot (same instance) — `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider.current honors an injected snapshot`
- [x] [U6] `count(NoParams)` returns 1 — `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider.count returns 1`
