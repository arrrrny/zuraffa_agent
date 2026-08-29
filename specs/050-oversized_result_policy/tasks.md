# Tasks: OversizedResultPolicy (summarize+artifactRef)

- [U1] Add regression test: OversizedResultPolicy value equality across all four fields + hashCode (DONE).
- [U2] Add regression test: OversizedResultPolicy inequality when any field differs (DONE).
- T1 Create `lib/src/domain/entities/oversized_result_policy/oversized_result_policy.dart`.
- T2 Create `lib/src/domain/services/oversized_result_policy_service.dart`.
- [U3] Add regression test: OversizedResultPolicyProvider is a OversizedResultPolicyService (DONE).
- [U4] Add regression test: OversizedResultPolicyProvider.current returns the active policy (DONE).
- [U5] Add regression test: OversizedResultPolicyProvider honors an injected active policy (DONE).
- [U6] Add regression test: OversizedResultPolicyProvider.count returns 1 (DONE).
- T3 Create `lib/src/data/providers/oversized_result_policy/oversized_result_policy_provider.dart`.
- T4 Create `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.

## Phase N: TDD remediation

Feature is not done until the blocking finding below is cleared (verification.md F1, HIGH).

- [ ] T8 Pin the exact default policy values in U4 instead of weak predicates. Assert `thresholdBytes == 65536`, `summaryMaxChars == 2000`, and `artifactStore == './artifacts'` (the defaults the spec fixes), not merely `greaterThan(0)`/`isNotEmpty`. Proof: `dart test test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart --plain-name "OversizedResultPolicyProvider.current returns the active policy"` exits 0, AND a source mutant setting `thresholdBytes: 1` (or `summaryMaxChars: 1`) in `lib/src/domain/entities/oversized_result_policy/oversized_result_policy.dart` then FAILS that test (currently a `1` default survives the `greaterThan(0)` assertion).
