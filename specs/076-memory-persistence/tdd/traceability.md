# Traceability: 076-memory-persistence

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:5b205bb5a331c9d1298f150158bb0f4b8cde876d18cb10f1e7f5af2d931fcdb7
statements: 25
automated: 25
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 82 | - **FR-001**: `MemoryJsonCodec` MUST losslessly round-trip `MemoryRecord` | U1 | automated |
| FR-002 | 85 | - **FR-002**: `PersistentLongTermMemoryStore` MUST mirror every `remember` | U2 | automated |
| FR-003 | 88 | - **FR-003**: `restore()` MUST rebuild the store from the file; a missing | U3 | automated |
| FR-004 | 90 | - **FR-004**: During restore, malformed individual entries MUST be skipped; | U4 | automated |
| FR-005 | 92 | - **FR-005**: Same-id replace MUST write through without duplicating the | U5 | automated |
| FR-006 | 94 | - **FR-006**: `PersistentMemoryGraph` MUST mirror every `link` (including | U6 | automated |
| FR-007 | 97 | - **FR-007**: Writes MUST be atomic — content lands in a `*.tmp` sibling | U7 | automated |
| FR-008 | 99 | - **FR-008**: The facade MUST compose with persistent stores such that | U8 | automated |
| FR-009 | 102 | - **FR-009**: `SessionMemoryStore` MUST NOT be persisted (evaporating layer; | U9 | automated |
| FR-010 | 104 | - **FR-010**: The system MUST satisfy this requirement: Gates — `dart analyze --fatal-infos` exit 0; full `dart test` | U10 | automated |
| AC-1 | 137 | 1. **Given** the feature implementation under its clean-architecture seams **When** MemoryJsonCodec round-trips records and links **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A1 | automated |
| AC-2 | 139 | 2. **Given** the feature implementation under its clean-architecture seams **When** PersistentLongTermMemoryStore write-through persists to disk **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A2 | automated |
| AC-3 | 141 | 3. **Given** the feature implementation under its clean-architecture seams **When** restore round-trips records and links with full fidelity **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A3 | automated |
| AC-4 | 143 | 4. **Given** the feature implementation under its clean-architecture seams **When** same-id replace writes through without duplication **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A4 | automated |
| AC-5 | 145 | 5. **Given** the feature implementation under its clean-architecture seams **When** restore skips malformed entries and fails loud on a corrupt file **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A5 | automated |
| AC-6 | 147 | 6. **Given** the feature implementation under its clean-architecture seams **When** graph restore skips malformed links and fails loud on a corrupt file **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A6 | automated |
| AC-7 | 149 | 7. **Given** the feature implementation under its clean-architecture seams **When** restore on a missing file starts empty **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A7 | automated |
| AC-8 | 151 | 8. **Given** the feature implementation under its clean-architecture seams **When** PersistentMemoryGraph round-trips links and replaces idempotently **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A8 | automated |
| AC-9 | 153 | 9. **Given** the feature implementation under its clean-architecture seams **When** atomic writes leave no temp files and always-valid JSON **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A9 | automated |
| AC-10 | 155 | 10. **Given** the feature implementation under its clean-architecture seams **When** full system persistence — promote survives a restart **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A10 | automated |
| AC-11 | 157 | 11. **Given** the feature implementation under its clean-architecture seams **When** write-through works for records created with default salience **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A11 | automated |
| AC-12 | 159 | 12. **Given** the feature implementation under its clean-architecture seams **When** write-through creates missing parent directories **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A12 | automated |
| AC-13 | 161 | 13. **Given** the feature implementation under its clean-architecture seams **When** restore fails loud on a JSON document of the wrong shape **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A13 | automated |
| AC-14 | 163 | 14. **Given** the feature implementation under its clean-architecture seams **When** restore fails loud on an unsupported snapshot version **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A14 | automated |
| AC-15 | 165 | 15. **Given** the feature implementation under its clean-architecture seams **When** restore skips a record whose tags are not a list **Then** the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | A15 | automated |

