# Tasks: StopPolicy clean-architecture layers
- [x] [U1] StopPolicyRepository defines getCurrent/update/reset; impl delegates + StateError on unknown id — `stop_policy_repository_impl_test.dart::U8: StopPolicyRepositoryImpl is a StopPolicyRepository`
- [x] [U2] StopPolicyService current/defaultPolicy(NoParams); provider is a service; parameterless compiles — `stop_policy_provider_test.dart::U10: StopPolicyProvider is a StopPolicyService`
- [x] [U3] Provider returns default when fresh, serves seeded policy, reset restores default through the chain — `stop_policy_provider_test.dart::A1: a fresh chain returns the default policy from current()`
- T1 Create `lib/src/domain/repositories/stop_policy_repository.dart` (abstract).
- T2 Create `lib/src/domain/services/stop_policy_service.dart` (abstract, NoParams parameterless methods).
- T3 Create `lib/src/data/providers/stop_policy/stop_policy_provider.dart` (concrete stub).
- T4 Create `test/data/providers/stop_policy/stop_policy_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## Phase 3: TDD remediation

Source: `tdd/verification.md` @ `01618f3` — **verdict FAIL**. This feature is **not
done** until T8 and T9 below are cleared. HIGH findings only; MED/LOW findings 3–9
are recorded in the report and not tracked here.

- [ ] T8 (finding #1, HIGH) Replace the vacuous assertion at `test/data/providers/stop_policy/stop_policy_provider_test.dart:27-30`: `U11` asserts `expect(provider, isNotNull)`, which a Dart constructor can never violate. Assert the default wiring it claims instead — that a parameterless `StopPolicyProvider()` reads through its own default datasource, e.g. `expect(await provider.current(NoParams()), equals(StopPolicy.defaultPolicy))` plus an assertion that survives a mutant which swaps the default datasource. Prove it done: `dart test test/data/providers/stop_policy/stop_policy_provider_test.dart -n "U11"` is green, and emptying the `?? StopPolicyMockDatasource()` default at `lib/src/data/providers/stop_policy/stop_policy_provider.dart:34` makes it **fail**.
- [ ] T9 (finding #2, HIGH) Record the test-after status honestly rather than leaving `tdd/cycle-log.md` holding only a baseline: append an entry stating that the three layers shipped with their tests in `7eb6c7c` with no red, and that the corroborating reds (`8de8f41`, `34da014`) belong to spec 027's loop; mark U1–U3 in `tdd/test-list.md` accordingly. Prove it done: `tdd/verification.md` re-run resolves every behavior's class from a cycle-log entry (no class derived from an absent record), and `dart test` is green.
