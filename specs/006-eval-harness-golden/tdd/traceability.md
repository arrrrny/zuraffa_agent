# Traceability: 006-eval-harness-golden

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:9ca207fa5fa52228e5eafc146a4d76832866c2076f24c1e4d0b8bc6b4ea62087
statements: 14
automated: 14
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a recorded cassette (LLM responses keyed by request, tool results), **When** replayed, **Then** the engine consumes recordings instead of live calls with identical event order. | A1 | automated |
| AC-2 | 27 | 2. **Given** a replay whose inputs drift from the recording (prompt change), **Then** the harness reports a mismatch loudly — never silently passes. | A2 | automated |
| AC-3 | 40 | 3. **Given** a suite with k samples per task and known pass counts, **When** scored, **Then** pass@k matches the analytic value. | A3 | automated |
| AC-4 | 42 | 4. **Given** a release gate of pass@k ≥ threshold, **When** a suite scores below, **Then** CI fails with per-task breakdown. | A4 | automated |
| AC-5 | 55 | 5. **Given** a task with an exact grader, **Then** byte-equality decides. | A5 | automated |
| AC-6 | 57 | 6. **Given** a schema grader, **Then** JSON-Schema validity decides. | A6 | automated |
| AC-7 | 59 | 7. **Given** a model-judge grader (recorded judge), **Then** the parsed verdict decides, and the judge call is replayed deterministically. | A7 | automated |
| AC-8 | 72 | 8. **Given** GM-1..GM-5 defined as harness suites, **When** CI runs, **Then** all report and gate correctly. | A8 | automated |
| AC-9 | 85 | 9. **Given** the eval runtime package, **When** scanned, **Then** no dart:io imports exist (CLI/loader layers exempt). | A9 | automated |
| FR-001 | 99 | - **FR-001**: The harness MUST record LLM + tool traffic and replay deterministically, detecting input drift. | U1 | automated |
| FR-002 | 100 | - **FR-002**: Scoring MUST implement pass@k (unbiased estimator) and pass^k (empirical) with per-task breakdowns. | U2 | automated |
| FR-003 | 101 | - **FR-003**: Graders MUST include exact, schema, and model-judge (recorded) types. | U3 | automated |
| FR-004 | 102 | - **FR-004**: The harness MUST be consumable by `zfa agent replay` (plugin CLI) and dws_playground suites. | U4 | automated |
| FR-005 | 103 | - **FR-005**: The eval runtime MUST be dart:io-free (enforced by static gate). | U5 | automated |

