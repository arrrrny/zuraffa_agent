# Tasks: SessionTreeEntry sealed hierarchy

- T1 [U1][U2] Create `lib/src/domain/entities/session_tree_entry/session_tree_entry.dart`.
- T2 Create `lib/src/domain/services/session_tree_entry_service.dart`.
- T3 [U3][U4][U5][U6] Create `lib/src/data/providers/session_tree_entry/session_tree_entry_provider.dart`.
- T4 [U1][U2][U3][U4][U5][U6] Create `test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart` (6 tests).
- T5 Upload spec/plan/tasks.
- T6 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T7 Commit + push + PR + merge + pull + re-test.
- T8 Gate: every TDD behavior in `tdd/test-list.md` is `DONE` and `dart test` is green before the story is considered complete.
