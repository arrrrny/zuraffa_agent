# Traceability: 072-agent-swarm

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:961b777580de33b899705559b35076358690b23c3dfd949cb85b532ac12014ed
statements: 18
automated: 18
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 40 | - **FR-001**: The system MUST satisfy this requirement: Value objects (spec 066 house pattern): `SwarmTask` | U1 | automated |
| FR-002 | 46 | - **FR-002**: The system MUST satisfy this requirement: Concurrent fan-out: every task's dispatch starts EAGERLY | U2 | automated |
| FR-003 | 51 | - **FR-003**: The system MUST satisfy this requirement: `allCompleted` (default): await every member; `status == | U3 | automated |
| FR-004 | 55 | - **FR-004**: The system MUST satisfy this requirement: `firstCompleted`: the first member to finish with dispatch | U4 | automated |
| FR-005 | 61 | - **FR-005**: The system MUST satisfy this requirement: `quorum`: `quorum` (k) is REQUIRED for this strategy and | U5 | automated |
| FR-006 | 68 | - **FR-006**: The system MUST satisfy this requirement: Pass-through wiring: `onEvent`, `clock`, `adminGranted` | U6 | automated |
| FR-007 | 71 | - **FR-007**: The system MUST satisfy this requirement: Empty swarm is a caller bug: `run(tasks: [])` throws | U7 | automated |
| FR-008 | 73 | - **FR-008**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` green | U8 | automated |
| AC-1 | 98 | 1. **Given** the feature implementation under its clean-architecture seams **When** members dispatch concurrently (overlap provable) **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A1 | automated |
| AC-2 | 99 | 2. **Given** the feature implementation under its clean-architecture seams **When** allCompleted returns a barrier over task-ordered results **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A2 | automated |
| AC-3 | 100 | 3. **Given** the feature implementation under its clean-architecture seams **When** allCompleted reports partialFailure when a member fails **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A3 | automated |
| AC-4 | 101 | 4. **Given** the feature implementation under its clean-architecture seams **When** firstCompleted wins on completion order, not submission order **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A4 | automated |
| AC-5 | 102 | 5. **Given** the feature implementation under its clean-architecture seams **When** firstCompleted without any success degrades to partialFailure **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A5 | automated |
| AC-6 | 103 | 6. **Given** the feature implementation under its clean-architecture seams **When** quorum reached on the k-th success **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A6 | automated |
| AC-7 | 104 | 7. **Given** the feature implementation under its clean-architecture seams **When** quorum unmet fails with the true success count **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A7 | automated |
| AC-8 | 105 | 8. **Given** the feature implementation under its clean-architecture seams **When** validation rejects empty, duplicate-id, and bad-quorum runs **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A8 | automated |
| AC-9 | 106 | 9. **Given** the feature implementation under its clean-architecture seams **When** single-task swarm runs a real child mission end-to-end **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A9 | automated |
| AC-10 | 107 | 10. **Given** the feature implementation under its clean-architecture seams **When** value objects carry house semantics **Then** the pinned regression test passes (`test/engine/agent_swarm_test.dart`). | A10 | automated |

