# TDD Cycle Log: Eval Suite Health & Release Gate (spec 085)

Append-only record of the red-green-refactor cycles. RED evidence quoted
verbatim from the failing runs.

## Cycle 1 — fail-closed edges + machine-readable veto (U1–U3)

**Scope**: zero-run tasks veto instead of crashing, zero-task suites fail
closed, `GateDecision.incomplete` / `incompleteTaskIds`. Tests T1–T8
written FIRST, in full, before any production edit.

### RED

Step 1 — the test file alone (production untouched):

```
$ dart test test/eval/suite_gate_085_test.dart
test/eval/suite_gate_085_test.dart:81:21: Error: The getter 'incomplete'
  isn't defined for the type 'GateDecision'.
test/eval/suite_gate_085_test.dart:82:21: Error: The getter
  'incompleteTaskIds' isn't defined for the type 'GateDecision'.
test/eval/suite_gate_085_test.dart:93:23: Error: … (same, x5 more sites)
```

Step 2 — the two fields added (veto computed from missing entries only,
no zero-run branch, no empty-suite guard):

```
$ dart test test/eval/suite_gate_085_test.dart
00:00 +5 -3: Some tests failed.

Failing tests:
  ... T1: a zero-task suite fails closed even at threshold 0.0
  ... T2: a zero-run task vetoes instead of crashing
  ... T3: the veto is machine-readable and in suite order
```

(T2 fails via the pre-existing `ArgumentError` from `PassAtK.compute`
reached with `k = 0`; T1 fails because `0.0 >= 0.0` passes — the
fail-open bug.)

Test-bug note (honesty): the first run of this stage also failed T5 —
the fixture asked for pass@2 == 0.5 with `n: 4, c: 2`, but the unbiased
estimator gives 1 - C(2,2)/C(4,2) = 5/6. The fixture was corrected to
`c: 1` (1 - C(3,2)/C(4,2) = 0.5 exactly) BEFORE any production edit; T5
then passed against unmodified behavior, as a pin should.

### GREEN

Zero-run branch (`s == null || s.n == 0` → 0.0 row + veto id, never
reaching `PassAtK`), `rows.isNotEmpty` in `passed`, veto ids collected in
suite order, empty-suite report reason:

```
$ dart test test/eval/suite_gate_085_test.dart
00:00 +8: All tests passed!
$ dart test test/eval/     # incl. the UNMODIFIED spec-006 A4 suite
00:00 +14: All tests passed!
```

### REFACTOR

Reviewed; the veto list is built once in the row loop (single source of
truth) instead of a second pass over `suite.tasks`. Existing report lines
byte-identical. No behavior change beyond the spec'd deltas.

## Cycle 2 — pins (U4–U8)

T4 (all-missing), T5 (`>=` boundary), T6 (unbiased value pass-through,
`n:10 c:4 k:1` → 0.4), T7 (extra ids ignored), T8 (`c > n` throws) pin
behavior that ships on master; they pass by design and are justified by
the mutation kills below (M1/M4 guard the veto, M2 the boundary guard,
M3 the zero-run path).

## Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | veto dropped from `passed` | KILLED by T3 + T4 | 3 failures — score clears threshold while tasks are missing |
| M2  | `rows.isNotEmpty` guard removed | KILLED by T1 | zero-task suite passes at threshold 0.0 again |
| M3  | zero-run branch removed | KILLED by T2 + T3 | the `ArgumentError` crash returns; T3's ids shift |
| M4  | `incompleteIds` never populated | KILLED by T2 + T3 + T4 | veto fields empty/lying |

After each restore the target file returned to 8/8 green.

## Gates

```
$ dart analyze            # 3 issues — identical to master baseline (out of scope)
$ dart test               # 00:41 +1081 ~2: All tests passed!
```

Baseline at master `29b7fef` was 1073 passed / 2 skipped; +8 new tests
(the spec-006 A4 suite passes unmodified).
