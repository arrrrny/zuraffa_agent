# Traceability: 085-eval-suite-health

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:926eedc15d0d81ac3fa987401498e9fc30cf76a4de19cc217b35eaa2cf7651ce
statements: 21
automated: 21
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 109 | - **FR-001**: The system MUST satisfy this requirement: Each declared task's score is the unbiased pass@k estimator | U1 | automated |
| FR-002 | 113 | - **FR-002**: The system MUST satisfy this requirement: The suite score is the mean of the per-task pass@k values | U2 | automated |
| FR-003 | 117 | - **FR-003**: The system MUST satisfy this requirement: The threshold decision is `>=`: a score exactly equal to | U3 | automated |
| FR-004 | 119 | - **FR-004**: The system MUST satisfy this requirement: A declared task with NO samples entry is INCOMPLETE: it | U4 | automated |
| FR-005 | 122 | - **FR-005**: The system MUST satisfy this requirement: A declared task whose samples entry has `n == 0` (zero | U5 | automated |
| FR-006 | 125 | - **FR-006**: The system MUST satisfy this requirement: `GateDecision` exposes `incomplete` (bool) and | U6 | automated |
| FR-007 | 128 | - **FR-007**: The system MUST satisfy this requirement: A suite with ZERO declared tasks FAILS the gate | U7 | automated |
| FR-008 | 131 | - **FR-008**: The system MUST satisfy this requirement: All-incomplete suites (every declared task missing or | U8 | automated |
| FR-009 | 133 | - **FR-009**: The system MUST satisfy this requirement: The computation stays pure and deterministic: same inputs → | U9 | automated |
| FR-010 | 137 | - **FR-010**: The system MUST satisfy this requirement: Gates — `dart analyze` reports no new issues relative to the | U10 | automated |
| AC-1 | 170 | 1. **Given** the feature implementation under its clean-architecture seams **When** A4: a suite scoring below the gate threshold fails with a per-task **Then** the pinned regression test passes (`test/eval/suite_gate_006_a4_test.dart`). | A1 | automated |
| AC-2 | 171 | 2. **Given** the feature implementation under its clean-architecture seams **When** A4: a suite exactly at the gate threshold passes (>=, not >) **Then** the pinned regression test passes (`test/eval/suite_gate_006_a4_test.dart`). | A2 | automated |
| AC-3 | 172 | 3. **Given** the feature implementation under its clean-architecture seams **When** A4: a task with no samples fails the gate loudly instead of being **Then** the pinned regression test passes (`test/eval/suite_gate_006_a4_test.dart`). | A3 | automated |
| AC-4 | 173 | 4. **Given** the feature implementation under its clean-architecture seams **When** T1: a zero-task suite fails closed even at threshold 0.0 **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A4 | automated |
| AC-5 | 174 | 5. **Given** the feature implementation under its clean-architecture seams **When** T2: a zero-run task vetoes instead of crashing **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A5 | automated |
| AC-6 | 175 | 6. **Given** the feature implementation under its clean-architecture seams **When** T3: the veto is machine-readable and in suite order **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A6 | automated |
| AC-7 | 176 | 7. **Given** the feature implementation under its clean-architecture seams **When** T4 (pin): all tasks missing → fail with every id listed **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A7 | automated |
| AC-8 | 177 | 8. **Given** the feature implementation under its clean-architecture seams **When** T5 (pin): a score exactly at the threshold passes (>=, not >) **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A8 | automated |
| AC-9 | 178 | 9. **Given** the feature implementation under its clean-architecture seams **When** T6 (pin): per-task breakdown carries the unbiased pass@k value **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A9 | automated |
| AC-10 | 179 | 10. **Given** the feature implementation under its clean-architecture seams **When** T7 (pin): sample ids the suite never declared are ignored **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A10 | automated |
| AC-11 | 180 | 11. **Given** the feature implementation under its clean-architecture seams **When** T8 (pin): c > n is a programming error, not an incomplete run **Then** the pinned regression test passes (`test/eval/suite_gate_085_test.dart`). | A11 | automated |

