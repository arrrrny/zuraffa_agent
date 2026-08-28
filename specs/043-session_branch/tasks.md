# Tasks: SessionBranch (fork/switch/resume)

- [U1] Add regression test: SessionBranch value equality across all five fields + hashCode (DONE).
- [U2] Add regression test: SessionBranch inequality when any field differs (DONE).
- T1 Create `lib/src/domain/entities/session_branch/session_branch.dart`.
- T2 Create `lib/src/domain/services/session_branch_service.dart`.
- [U3] Add regression test: SessionBranchProvider is a SessionBranchService (DONE).
- [U4] Add regression test: SessionBranchProvider.current returns the active branch (DONE).
- [U5] Add regression test: SessionBranchProvider.current returns a supplied active branch (DONE).
- [U6] Add regression test: SessionBranchProvider.count returns 1 (DONE).
- T3 Create `lib/src/data/providers/session_branch/session_branch_provider.dart`.
- T4 Create `test/data/providers/session_branch/session_branch_provider_test.dart` (5 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
