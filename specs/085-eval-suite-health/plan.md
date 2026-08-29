# Implementation Plan: Eval Suite Health & Release Gate (spec 085)

**Branch**: `085-eval-suite-health` | **Date**: 2026-08-29 | **Spec**:
`specs/085-eval-suite-health/spec.md`

## Summary

Fail-closed hardening of the spec-006 gate: zero-run tasks become a veto
instead of an `ArgumentError`, zero-task suites fail instead of passing at
threshold 0.0, and the veto becomes machine-readable
(`GateDecision.incomplete` + `incompleteTaskIds`). The estimator, the mean
aggregation, and the `>=` boundary are untouched.

## Technical Context

**Language/Version**: Dart 3.13.2 (SDK `^3.8.0`), pure deterministic
computation — no clock, no randomness, no I/O (constitution VII).

**Primary Dependencies**: `PassAtK` (domain/entities/pass_at_k —
validates `n >= 1`, `1 <= k <= n`, throws `ArgumentError` otherwise),
`Suite` (Zorphy entity: id, name, tasks, k, gateThreshold), `test` ^1.25.
The existing `suiteWith` helper pattern in
`test/eval/suite_gate_006_a4_test.dart` is reused (per-file copy).

**Consumers**: `SuiteGate.evaluate` is a static pure function; the
`GateDecision` constructor is only invoked there (verified by search), so
adding required fields breaks nothing.

## Components

### 1. Zero-run tasks are a veto, not a crash (FR-005)

```dart
final s = samples[taskId];
if (s == null || s.n == 0) {
  rows.add(TaskGateResult(
      taskId: taskId, passAtK: 0.0, passed: false,
      detail: s == null ? 'no samples recorded' : 'zero runs recorded'));
  incompleteTaskIds.add(taskId);
  continue;
}
```

`PassAtK.compute` is never reached with `n == 0` — its `ArgumentError`
contract stays intact for genuine arithmetic violations (`c > n`), which
FR-009 keeps as a throw.

### 2. Zero-task suites fail closed (FR-007)

```dart
final passed = rows.isNotEmpty && score >= suite.gateThreshold && !incomplete;
// report gains, for the empty case:
// 'FAIL suite <id>: no tasks declared — nothing to gate (fail-closed)'
```

`rows.isNotEmpty` is the zero-task guard: a gate over nothing is not
evidence. The report names the reason so a red run explains itself.

### 3. Machine-readable veto (FR-006)

```dart
class GateDecision {
  // …existing fields…
  /// True when any declared task was missing or had zero runs (FR-006).
  final bool incomplete;
  /// The veto-triggering task ids, in the suite's declared order.
  final List<String> incompleteTaskIds;
}
```

`incomplete = incompleteTaskIds.isNotEmpty`. The existing report lines are
unchanged (006-A4 asserts on them); the empty-suite case appends its own
reason line.

### 4. Tests (`test/eval/suite_gate_085_test.dart` — NEW)

RED (compile failure on the missing fields first, then failing
assertions):

- T1: zero-task suite, threshold 0.0 → `passed == false`, `exitCode == 1`,
  report names the fail-closed reason (currently passes — the fail-open
  bug).
- T2: `TaskSamples(n: 0, c: 0)` for one of two tasks → no throw; the task
  scores 0.0 with a zero-runs detail; gate vetoed (currently throws
  `ArgumentError`).
- T3: mixed missing + zero-run → `incomplete == true`,
  `incompleteTaskIds == ['GM-1', 'GM-3']` (suite order); complete suite →
  `incomplete == false`, empty list.

Pins (existing behavior, previously unguarded at these edges):

- T4: all tasks missing → fail, all ids listed, score 0.0.
- T5: `>=` boundary — score exactly at threshold passes (complements
  006-A4 with a different fixture shape).
- T6: unbiased per-task value — `n: 10, c: 4, k: 1` → breakdown carries
  `0.4` (the estimator pass-through).
- T7: extra sample ids not declared by the suite are ignored (score over
  declared tasks only).
- T8: `c > n` still throws `ArgumentError` (invalid arithmetic is a
  programming error, not an incomplete run).

### 5. Mutations (one at a time, cp-restored, each must KILL)

- M1: veto dropped from `passed` (`score >= threshold` only) → T3/T4
  kill (score clears threshold while tasks are missing).
- M2: `rows.isNotEmpty` guard removed (zero-task reverts to
  `0.0 >= threshold`) → T1 kills at threshold 0.0.
- M3: zero-run branch removed (reaches `PassAtK`) → T2 kills via the
  `ArgumentError`.
- M4: `incompleteTaskIds` never populated → T3/T4 kill.

## Sequencing

1. `/speckit.specify` → spec.md (done).
2. RED — test file: compile failure on missing `incomplete` /
   `incompleteTaskIds`; record; add the fields (incomplete computed from
   missing-only) → T1/T2 still failing (fail-open + crash). Evidence →
   `tdd/cycle-log.md`.
3. GREEN — zero-run branch, `rows.isNotEmpty` guard, veto population.
   Target file 8/8.
4. Pins T4–T8 verified green against unmodified behavior.
5. Mutations M1–M4, one at a time, cp-restored.
6. Gates (`dart analyze`, full `dart test` incl. unmodified 006-A4),
   `tdd/verification.md`, commit + PR (base master).

## Risks / decisions

- **Fail-closed on empty suites is a behavior change** (a threshold-0.0
  empty suite used to pass): intended, spec'd, and flagged in the PR —
  the constitution's "halts by gates" philosophy prefers a loud no over a
  silent yes with zero evidence.
- **`TaskSamples.n == 0` becomes legal input** to the gate (previously a
  de-facto crash); documented on the class.
- **Report stability**: existing lines byte-identical (006-A4 asserts on
  them); only the empty-suite case appends a new line.
- **`GateDecision` constructor growth**: single construction site
  (verified); no external breakage.
