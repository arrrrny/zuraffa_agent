# Feature Specification: Eval Suite Health & Release Gate

**Feature Branch**: `085-eval-suite-health`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for the Eval Suite release gate — per-task pass@k scoring, suite score, threshold decision, and incomplete-run veto — that is not yet covered by an existing spec (R6)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Turn sample counts into a CI verdict (Priority: P1)

A suite declares tasks and a `gateThreshold`. Given per-task sample counts (`n` runs, `c` correct), the gate computes the unbiased pass@k per task (Chen et al. estimator), the suite score (mean of per-task pass@k), and a pass/fail decision. Missing a task is a gate failure, never a silent skip.

**Why this priority**: This is the release gate that decides whether an eval suite is green; a wrong or lenient decision ships broken agents.

**Independent Test**: Can be fully tested by constructing a `Suite` and a `samples` map and asserting the `GateDecision` score, per-task rows, and `passed` flag.

**Acceptance Scenarios**:

1. **Given** a suite with `gateThreshold=0.8` and a task with `n=4, c=4` (k=1), **When** evaluated, **Then** that task's pass@k is 1.0, the suite score is 1.0, and `passed == true`.
2. **Given** a suite where one declared task has no entry in `samples`, **When** evaluated, **Then** that task scores 0.0, is reported as "no samples recorded", and the gate `passed == false` (incomplete veto).

---

### User Story 2 - Name the regressing task in a red run (Priority: P2)

When the gate fails, the decision's report must enumerate every task with its pass@k and sample counts so CI output pinpoints the regression instead of just printing "FAIL".

**Why this priority**: A red CI run that names the culprit task is debuggable; a bare failure is not.

**Independent Test**: Can be fully tested by asserting `breakdown` has one row per declared task in suite order, each with `taskId`, `passAtK`, `passed`, and a human-readable `detail`.

**Acceptance Scenarios**:

1. **Given** a failing suite, **When** the decision is rendered, **Then** `report` lists `FAIL <taskId>: <pass@k> (n=.. c=.. k=..)` for every task in declared order.
2. **Given** a score exactly equal to `gateThreshold`, **When** evaluated, **Then** `passed == true` (the `≥` boundary ships at threshold).

---

### Edge Cases

- A task with `k > n` clamps `k` to `n` for the pass@k computation (cannot sample more than drawn).
- A suite with zero tasks scores 0.0 and fails (an empty suite cannot pass a gate).
- A missing task vetoes the gate even if the mean of present tasks clears the threshold — skipping the hardest mission must not let the suite pass.
- `GateDecision.exitCode` is 0 on pass, 1 on fail (the process owner decides what to do with it).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `SuiteGate.evaluate` MUST compute per-task pass@k (unbiased estimator) from `TaskSamples(n, c)` using the suite's `k` (clamped to `n`).
- **FR-002**: The suite score MUST be the mean of per-task pass@k over all declared tasks.
- **FR-003**: A task absent from `samples` MUST score 0.0 and be reported (`detail: 'no samples recorded'`); an incomplete suite MUST veto the gate (fail), never silently skip the task.
- **FR-004**: `GateDecision.passed` MUST be true iff `score >= gateThreshold` AND the suite is complete; `exitCode` MUST be 0 on pass, 1 on fail.
- **FR-005**: The gate MUST be dart:io-free (pure Dart); it returns the exit code as a value rather than calling `exit()`.

### Key Entities

- **TaskSamples**: `{ n, c }` — samples drawn and correct for one task.
- **TaskGateResult**: `{ taskId, passAtK, passed, detail }` — one breakdown row.
- **GateDecision**: `{ suiteId, score, threshold, passed, breakdown, report, exitCode }` — the verdict.
- **SuiteGate**: the pure evaluator over a `Suite` + `samples` map.
- **Suite / PassAtK**: provided by sibling modules (specs 006/037); this spec owns the gating decision.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A suite with a missing task always fails the gate, regardless of the present-task mean.
- **SC-002**: A suite scoring exactly at `gateThreshold` passes (the `≥` boundary).
- **SC-003**: The breakdown names every declared task in order with its pass@k and sample counts, so a red run is debuggable.

## Assumptions

- `PassAtK` (unbiased estimator) and `Suite` are provided by specs 037 / 006; this spec owns only the gating/verdict logic.
- "Calibration / saturation" advanced analytics from the original gap analysis are explicitly out of scope for v1 (noted, not built here).
- This feature maps to **R6 (eval harness, issue #7)** — the golden-mission release gate.
