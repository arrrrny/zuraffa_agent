# Traceability: 073-agent-memory

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:4ea7bb22214104cc25cc6754c61d5f6a88f0a73f48a2cc8b8c31236120b21922
statements: 21
automated: 21
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 53 | - **FR-001**: The system MUST satisfy this requirement: `MemoryRecord` (house value semantics): `id`, `content` | U1 | automated |
| FR-002 | 59 | - **FR-002**: The system MUST satisfy this requirement: Long-term store: `remember(MemoryRecord)` (same-id | U2 | automated |
| FR-003 | 65 | - **FR-003**: The system MUST satisfy this requirement: Session store: `remember(sessionId, record)` (a record | U3 | automated |
| FR-004 | 70 | - **FR-004**: The system MUST satisfy this requirement: `MemoryLinkType`: `supports`, `contradicts`, | U4 | automated |
| FR-005 | 75 | - **FR-005**: The system MUST satisfy this requirement: Memory graph: `link(fromId, toId, type)` rejects | U5 | automated |
| FR-006 | 83 | - **FR-006**: The system MUST satisfy this requirement: `AgentMemorySystem.remember`: with `sessionId: null` | U6 | automated |
| FR-007 | 86 | - **FR-007**: The system MUST satisfy this requirement: `AgentMemorySystem.recall(String query, {int? limit})`: | U7 | automated |
| FR-008 | 92 | - **FR-008**: The system MUST satisfy this requirement: `AgentMemorySystem.link` validates BOTH endpoints | U8 | automated |
| FR-009 | 97 | - **FR-009**: The system MUST satisfy this requirement: `promote(sessionRecordId)`: moves a record from session | U9 | automated |
| FR-010 | 103 | - **FR-010**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` | U10 | automated |
| AC-1 | 129 | 1. **Given** the feature implementation under its clean-architecture seams **When** value objects carry house semantics and validation **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A1 | automated |
| AC-2 | 130 | 2. **Given** the feature implementation under its clean-architecture seams **When** LongTermMemoryStore replaces, ranks, and filters **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A2 | automated |
| AC-3 | 131 | 3. **Given** the feature implementation under its clean-architecture seams **When** SessionMemoryStore scopes by session with global id uniqueness **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A3 | automated |
| AC-4 | 132 | 4. **Given** the feature implementation under its clean-architecture seams **When** MemoryGraph traverses both directions and filters by type **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A4 | automated |
| AC-5 | 133 | 5. **Given** the feature implementation under its clean-architecture seams **When** three-layer story: remember, link, recall, promote **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A5 | automated |
| AC-6 | 134 | 6. **Given** the feature implementation under its clean-architecture seams **When** recall ranks by salience then recency across both layers **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A6 | automated |
| AC-7 | 135 | 7. **Given** the feature implementation under its clean-architecture seams **When** recall honors the limit and rejects empty queries **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A7 | automated |
| AC-8 | 136 | 8. **Given** the feature implementation under its clean-architecture seams **When** link validates endpoints and stays idempotent **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A8 | automated |
| AC-9 | 137 | 9. **Given** the feature implementation under its clean-architecture seams **When** promote moves a session memory into long-term **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A9 | automated |
| AC-10 | 138 | 10. **Given** the feature implementation under its clean-architecture seams **When** forgetSession evaporates session memory and leaves honest dangling links **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A10 | automated |
| AC-11 | 139 | 11. **Given** the feature implementation under its clean-architecture seams **When** remember rejects an id already used in the opposite layer **Then** the pinned regression test passes (`test/engine/agent_memory_test.dart`). | A11 | automated |

