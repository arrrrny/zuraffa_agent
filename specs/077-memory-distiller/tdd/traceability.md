# Traceability: 077-memory-distiller

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:78b0ae09a0d556a580a6731b040ed7610d8e2b01740e40b4c0e38edb6ed2ee2e
statements: 21
automated: 21
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 82 | - **FR-001**: `DistillationPolicy` MUST expose `salienceThreshold` | U1 | automated |
| FR-002 | 85 | - **FR-002**: `distill(sessionId)` MUST promote exactly the session | U2 | automated |
| FR-003 | 88 | - **FR-003**: The system MUST satisfy this requirement: Boundary: `salience == threshold` promotes. | U3 | automated |
| FR-004 | 89 | - **FR-004**: The system MUST satisfy this requirement: A record whose normalized content (trim + case-fold) already | U4 | automated |
| FR-005 | 92 | - **FR-005**: With `maxPerSession` set, promotions MUST be capped to the | U5 | automated |
| FR-006 | 95 | - **FR-006**: Below-threshold records MUST be skipped with | U6 | automated |
| FR-007 | 97 | - **FR-007**: `distill` MUST be idempotent — a second run on the same | U7 | automated |
| FR-008 | 99 | - **FR-008**: The system MUST satisfy this requirement: Unknown / empty session → empty report, no throw. | U8 | automated |
| FR-009 | 100 | - **FR-009**: `DistillationReport` MUST carry `promoted` (ids, promotion | U9 | automated |
| FR-010 | 103 | - **FR-010**: The system MUST satisfy this requirement: Composed with the 076 persistent stores, distilled records | U10 | automated |
| FR-011 | 105 | - **FR-011**: The system MUST satisfy this requirement: Gates — `dart analyze --fatal-infos` exit 0; full `dart | U11 | automated |
| AC-1 | 134 | 1. **Given** the feature implementation under its clean-architecture seams **When** DistillationPolicy defaults and validation **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A1 | automated |
| AC-2 | 136 | 2. **Given** the feature implementation under its clean-architecture seams **When** distills a mixed-salience session — gate, identity, residue **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A2 | automated |
| AC-3 | 138 | 3. **Given** the feature implementation under its clean-architecture seams **When** boundary salience equal to threshold promotes; default is 0.7 **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A3 | automated |
| AC-4 | 140 | 4. **Given** the feature implementation under its clean-architecture seams **When** duplicate guard skips content already known to long-term **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A4 | automated |
| AC-5 | 142 | 5. **Given** the feature implementation under its clean-architecture seams **When** same-content session siblings dedupe within one run **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A5 | automated |
| AC-6 | 144 | 6. **Given** the feature implementation under its clean-architecture seams **When** cap promotes the best N — salience desc, older first among equals **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A6 | automated |
| AC-7 | 146 | 7. **Given** the feature implementation under its clean-architecture seams **When** distill is idempotent — no double promotion, no duplicates **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A7 | automated |
| AC-8 | 148 | 8. **Given** the feature implementation under its clean-architecture seams **When** unknown session distills to an empty report **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A8 | automated |
| AC-9 | 150 | 9. **Given** the feature implementation under its clean-architecture seams **When** DistillationReport accounts for every record **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A9 | automated |
| AC-10 | 152 | 10. **Given** the feature implementation under its clean-architecture seams **When** distilled knowledge is durable across a store rebuild **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | A10 | automated |

