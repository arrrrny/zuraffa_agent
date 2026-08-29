# Tasks: Eval Suite Health & Release Gate (spec 085)

**Input**: spec.md + plan.md under `specs/085-eval-suite-health/`

**Baseline**: master `29b7fef` — `dart test` 1073 passed / 2 skipped / 0
failed; `dart analyze` 3 pre-existing issues (all out of scope).

- [x] 1. RED — write `test/eval/suite_gate_085_test.dart` (T1–T8:
       zero-task fail-closed; zero-run veto without crash; machine-
       readable incomplete/incompleteTaskIds; all-incomplete pin; >=
       boundary pin; unbiased known-value pin; extra-ids-ignored pin;
       c>n still throws pin). First red is the compile failure on the
       missing `incomplete` / `incompleteTaskIds` members, then failing
       assertions (T1 fail-open, T2 crash). Evidence →
       `tdd/cycle-log.md`.
- [x] 2. GREEN — zero-run branch scores 0.0 + veto (no PassAtK call),
       `rows.isNotEmpty` fail-closed guard, veto population in suite
       order, empty-suite report reason. Target file 8/8.
- [x] 3. Pins — T4–T8 verified against unmodified behavior; the
       pre-existing `test/eval/suite_gate_006_a4_test.dart` stays green
       UNMODIFIED.
- [x] 4. Mutations — M1 veto dropped; M2 empty-suite guard removed; M3
       zero-run branch removed; M4 incompleteTaskIds never populated. One
       at a time, cp-restored, each must KILL.
- [x] 5. Gates — `dart analyze` (no new issues vs baseline), full `dart
       test` green (baseline 1073/2 + new).
- [x] 6. `tdd/verification.md` — evidence classification, FR table,
       mutation results verbatim, gates, verdict.
- [x] 7. Commit (artifacts + code together) and open PR base `master`
       (closes #96).
