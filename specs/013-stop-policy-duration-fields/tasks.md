# Tasks: StopPolicy Duration field support
- [x] [U1] StopPolicy defaultPolicy carries the 5 documented field values — `test/domain/entities/stop_policy/stop_policy_test.dart::U1: defaultPolicy carries the documented values`
- [x] [U2] StopPolicy value equality holds across all five fields — `test/domain/entities/stop_policy/stop_policy_test.dart::U2: value equality across all five fields`
- [x] [U3] Equal StopPolicy instances share hashCode; one differing field breaks equality — `test/domain/entities/stop_policy/stop_policy_test.dart::U3: equal instances have equal hashCodes`
- T1 Update `lib/src/domain/entities/stop_policy/stop_policy.dart` with 5 spec-exact fields + value-based equality.
- T2 Update `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` with 5 new #13 regression tests.
- T3 Upload spec/plan/tasks.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.

## Phase 3: TDD remediation

Source: `tdd/verification.md` @ `01618f3` — **verdict FAIL**. This feature is **not
done** until T6 and T7 below are cleared. HIGH findings only; MED/LOW findings 3–7
are recorded in the report and not tracked here.

- [ ] T6 (finding #1, HIGH) Pin value inequality per field in `test/domain/entities/stop_policy/stop_policy_test.dart:22,40`: add one `expect(a, isNot(equals(b)))` case for each of `id`, `maxTurns`, `wallClockTimeout`, `repetitionThreshold`, and `enabled`, where `b` differs from `a` in exactly that field (`enabled` must be set explicitly on both sides, not left to its default). Prove it done: re-apply mutant M1 (drop `enabled == other.enabled` at `lib/src/domain/entities/stop_policy/stop_policy.dart:68`), confirm `dart test test/domain/entities/stop_policy/stop_policy_test.dart` now **fails**, restore the source, and confirm the file is green.
- [ ] T7 (finding #2, HIGH) Record the test-after status honestly rather than leaving `tdd/cycle-log.md` holding only a baseline: append an entry stating that the 5-field surface shipped in `fc512a1` ahead of the referenced tests, and mark U1–U3 in `tdd/test-list.md` as characterization of already-shipped code. Prove it done: `tdd/verification.md` re-run resolves every behavior's class from a cycle-log entry (no class derived from an absent record), and `dart test` is green.
