# Tasks: StopPolicy datasource + mock pair
- T1 Create `lib/src/domain/entities/stop_policy/stop_policy.dart` (Zorphy value object).
- T2 Create `lib/src/data/datasources/stop_policy/stop_policy_datasource.dart` (abstract class).
- T3 Create `lib/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart` (concrete stub).
- T4 Create `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` (3 tests).
- T5 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T6 Commit + push + PR + merge + pull + re-test.
