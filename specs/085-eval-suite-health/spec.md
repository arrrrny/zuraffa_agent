# Feature Specification: R6: Eval Suite Health & Release Gate — pass@k gating

**Branch**: `085-eval-suite-health` (off master `29b7fef`) | **Date**: 2026-08-29

**Status**: Draft → implemented on this branch

**Input**: User description: "R6: Eval Suite Health & Release Gate —
pass@k gating. Per-task unbiased pass@k, suite score, threshold decision
(>= boundary), and an incomplete-run veto so a missing task fails the
gate. Parent epic: R6 eval harness (issue #7). Scope: compute an unbiased
per-task pass@k, aggregate a suite score, decide pass/fail against a
configurable threshold (>= boundary), and veto the release if any task run
is incomplete (missing task fails the gate). Pure, deterministic
computation; define the aggregation and edge cases (zero tasks,
all-incomplete)."

## Summary

`SuiteGate` (lib/src/eval/suite_gate.dart, spec 006 FR-002/AC-2) already
computes the unbiased per-task pass@k (Chen et al., via the `PassAtK`
value object), the suite score (mean over declared tasks), the `>=`
threshold decision, and vetoes a gate when a declared task has no samples
entry — all pinned by `test/eval/suite_gate_006_a4_test.dart`. What the
R6 contract (issue #96) asks for that the tree does not yet satisfy:

1. **A zero-task suite is fail-open.** With no declared tasks the score is
   0.0 and no task is "missing", so `passed = 0.0 >= threshold` — at
   `gateThreshold: 0.0` an empty suite SHIPS. A gate over nothing is not
   evidence; the contract must define the edge: zero tasks → fail, closed.
2. **A present-but-empty run crashes the gate.** `TaskSamples(n: 0, c: 0)`
   (task listed, harness recorded zero runs — a crashed worker, a
   misconfigured filter) reaches `PassAtK.compute` with `k = 0` and throws
   `ArgumentError`. An incomplete run must be a veto, not a crash: the
   task scores 0.0, is named as incomplete, and fails the gate.
3. **The veto is not machine-readable.** Whether the gate was vetoed (and
   by which tasks) lives only in the human-readable `report` string.
   Fallback/CI logic must not parse prose: `GateDecision` needs an
   `incomplete` flag and the `incompleteTaskIds` that triggered it.

This spec closes all three and pins the seed's remaining edges
(all-incomplete, extra sample ids, the `>=` boundary, unbiased per-task
values) alongside the existing 006-A4 tests, which stay unmodified.

**Out of scope**: how samples are produced (the harness/runner — specs
006/061), pass@k estimator changes (spec 037 owns the formula), suite
configuration schema, report formatting beyond the new reason lines.

## Files

- `lib/src/eval/suite_gate.dart` — EDIT: `GateDecision` gains `incomplete`
  + `incompleteTaskIds`; `evaluate` treats zero-run tasks as incomplete
  (no crash), fails closed on zero tasks, and records veto reasons.
- `test/eval/suite_gate_085_test.dart` — NEW: the RED behaviors
  (zero-task fail-closed, zero-run veto, machine-readable veto) and the
  pins (all-incomplete, `>=` boundary, unbiased values, extra ids
  ignored).
- `specs/085-eval-suite-health/` — this artifact set.

## User scenarios

### US1 — Gate a suite with confidence in the verdict (P1)

As a release engineer, the gate's verdict is trustworthy in the corners:
an empty suite fails (nothing was gated — that is not a pass), a task with
zero recorded runs fails the gate as incomplete rather than crashing or
being skipped, and every declared task contributes to the score.

**Why this priority**: these are exactly the shapes a broken CI produces
(empty glob, crashed worker) — the moments the gate must NOT say yes.

**Independent test**: zero-task suite at threshold 0.0 → `passed == false`,
`exitCode == 1`; `TaskSamples(n: 0)` → no throw, task scores 0.0, gate
fails via veto.

### US2 — Read the veto programmatically (P1)

As CI/fallback logic, I consume `decision.incomplete` and
`decision.incompleteTaskIds` to distinguish "scored below threshold" from
"vetoed — evidence missing", without parsing the report string.

**Why this priority**: the veto is the strongest signal (a vetoed gate
means the number itself is untrustworthy); hiding it in prose forces
fragile string matching.

**Independent test**: mixed suite with one missing and one zero-run task →
`incomplete == true`, `incompleteTaskIds == [missing, zero-run]` in suite
order; complete suite → `incomplete == false`, empty list.

### US3 — Trust the arithmetic (P2)

As an operator, the numbers are the spec's: per-task unbiased pass@k
(Chen et al.), suite score = mean over DECLARED tasks, threshold decided
with `>=`, extra sample ids for tasks the suite never declared are
ignored, all-incomplete suites fail loudly.

**Why this priority**: deterministic, pure arithmetic is what makes the
gate auditable; the edges are where aggregation bugs hide.

**Independent test**: known-value task (`n: 10, c: 4, k: 1` → 0.4) in the
breakdown; score exactly at threshold passes; samples map with an extra
id does not move the score.

## Requirements

### Functional requirements

- **FR-001**: Each declared task's score is the unbiased pass@k estimator
  (Chen et al. 2021) computed by the `PassAtK` value object with
  `k = min(suite.k, n)` (existing; pinned here with a known value and by
  spec-006/037 tests cited in the test list).
- **FR-002**: The suite score is the mean of the per-task pass@k values
  over the suite's DECLARED tasks, in the suite's declared order
  (existing; pin — including that sample ids not declared by the suite are
  ignored).
- **FR-003**: The threshold decision is `>=`: a score exactly equal to
  `gateThreshold` passes (existing 006-A4 pin; re-pinned here).
- **FR-004**: A declared task with NO samples entry is INCOMPLETE: it
  scores 0.0, is reported as having no samples, and VETOES the gate
  (existing 006-A4 pin).
- **FR-005** (new): A declared task whose samples entry has `n == 0` (zero
  runs recorded) is INCOMPLETE: it scores 0.0 with a zero-runs detail,
  VETOES the gate, and `evaluate` does NOT throw.
- **FR-006** (new): `GateDecision` exposes `incomplete` (bool) and
  `incompleteTaskIds` (the veto-triggering tasks in suite order) — the
  machine-readable veto surface.
- **FR-007** (new): A suite with ZERO declared tasks FAILS the gate
  (fail-closed): `passed == false`, `exitCode == 1`, score 0.0, and the
  report names the reason. (Fixes the fail-open `0.0 >= 0.0` case.)
- **FR-008** (new): All-incomplete suites (every declared task missing or
  zero-run) fail with `incomplete == true` and all task ids listed.
- **FR-009**: The computation stays pure and deterministic: same inputs →
  same decision (no clock, no randomness, no I/O); invalid sample
  arithmetic (`c > n`) still throws `ArgumentError` (a programming error,
  not an incomplete run).
- **FR-010**: Gates — `dart analyze` reports no new issues relative to the
  master baseline (3 pre-existing, out of scope); the full `dart test`
  suite is green, including the unmodified spec-006
  `suite_gate_006_a4_test.dart`.

### Key entities

- `SuiteGate` / `GateDecision` — decision surface; gains the veto fields.
- `TaskSamples` — `n` runs / `c` correct; `n == 0` now legal (incomplete).
- `PassAtK` — the estimator (unchanged; still validates `n >= 1`, so the
  gate short-circuits zero-run tasks before computing).

## Success criteria

- **SC-001**: Zero-task suite at threshold 0.0 → `passed == false`,
  `exitCode == 1`, report names the reason (US1, FR-007).
- **SC-002**: `TaskSamples(n: 0, c: 0)` → no throw; the task scores 0.0
  with a zero-runs detail; the gate is vetoed (US1, FR-005).
- **SC-003**: `incomplete` / `incompleteTaskIds` correctly distinguish
  vetoed from merely-below-threshold gates, in suite order (US2, FR-006).
- **SC-004**: Gates green; the 006-A4 suite passes unmodified (FR-010).

## Dependencies

- Builds on: spec 006 (gate core + A4 tests), spec 037 (PassAtK
  estimator), spec 061 (empirical pass^k — unaffected).
- Independent of: MCP (082), ledger (083), retry (084) — different files.
