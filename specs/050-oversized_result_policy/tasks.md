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
