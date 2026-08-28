# Tasks: PassKEmpirical (pass^k metric)

- T1 Create `lib/src/domain/entities/pass_k_empirical/pass_k_empirical.dart`.
- T2 Create `lib/src/domain/services/pass_k_empirical_service.dart`.
- T3 Create `lib/src/data/providers/pass_k_empirical/pass_k_empirical_provider.dart`.
- T4 Create `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## TDD behavior markers (test-after plan; all DONE on master @ b9ba15c)

> Behavior ids referenced by `tdd/test-list.md` and `tdd/cycle-log.md`. Doc-only
> markers; the original T1-T7 implementation tasks above are unchanged.

- [x] [U1] `PassKEmpirical` value equality across all five fields + hashCode — `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpirical equality is value-based across all fields`
- [x] [U2] `PassKEmpirical` inequality when a field differs — `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpirical inequality differs when a field changes`
- [x] [U3] `PassKEmpiricalProvider` is a `PassKEmpiricalService` — `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider is a PassKEmpiricalService`
- [x] [U4] `current(NoParams)` returns the default active snapshot — `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider.current returns the active pass^k snapshot`
- [x] [U5] `current(NoParams)` returns the injected snapshot (same instance) — `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider.current honors an injected snapshot`
- [x] [U6] `count(NoParams)` returns 1 — `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider.count returns 1`
