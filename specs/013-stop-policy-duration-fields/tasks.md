# Tasks: StopPolicy Duration field support
- [x] [U1] StopPolicy defaultPolicy carries the 5 documented field values — `test/domain/entities/stop_policy/stop_policy_test.dart::U1: defaultPolicy carries the documented values`
- [x] [U2] StopPolicy value equality holds across all five fields — `test/domain/entities/stop_policy/stop_policy_test.dart::U2: value equality across all five fields`
- [x] [U3] Equal StopPolicy instances share hashCode; one differing field breaks equality — `test/domain/entities/stop_policy/stop_policy_test.dart::U3: equal instances have equal hashCodes`
- T1 Update `lib/src/domain/entities/stop_policy/stop_policy.dart` with 5 spec-exact fields + value-based equality.
- T2 Update `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` with 5 new #13 regression tests.
- T3 Upload spec/plan/tasks.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
