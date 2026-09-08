# Traceability: 074-memory-tools

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:a476b6c718cc17ae77e1e9c8b11c8533d5c3a575854a3904f25f6304e4a997e3
statements: 23
automated: 23
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 43 | - **FR-001**: The system MUST satisfy this requirement: Declarations: `memory_remember` (params: `content` | U1 | automated |
| FR-002 | 53 | - **FR-002**: The system MUST satisfy this requirement: `memory_remember` dispatch: builds a `MemoryRecord` | U2 | automated |
| FR-003 | 61 | - **FR-003**: The system MUST satisfy this requirement: Model-shaped failures return `ToolDispatchResult(success: | U3 | automated |
| FR-004 | 67 | - **FR-004**: The system MUST satisfy this requirement: `memory_recall` dispatch: returns success with one line | U4 | automated |
| FR-005 | 72 | - **FR-005**: The system MUST satisfy this requirement: `memory_link` dispatch: validates `type` against | U5 | automated |
| FR-006 | 78 | - **FR-006**: The system MUST satisfy this requirement: `dispatchBatch` dispatches every call sequentially and | U6 | automated |
| FR-007 | 81 | - **FR-007**: The system MUST satisfy this requirement: `validateSchema` checks the required keys per tool | U7 | automated |
| FR-008 | 86 | - **FR-008**: The system MUST satisfy this requirement: `MemoryPromptProjection.render({int limit = 10})`: the | U8 | automated |
| FR-009 | 94 | - **FR-009**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` | U9 | automated |
| AC-1 | 118 | 1. **Given** the feature implementation under its clean-architecture seams **When** declarations are safe-tier typed tools **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A1 | automated |
| AC-2 | 119 | 2. **Given** the feature implementation under its clean-architecture seams **When** remember generates ids and flows arguments **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A2 | automated |
| AC-3 | 120 | 3. **Given** the feature implementation under its clean-architecture seams **When** remember routes by session_id argument **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A3 | automated |
| AC-4 | 121 | 4. **Given** the feature implementation under its clean-architecture seams **When** recall renders ranked layer-attributed lines **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A4 | automated |
| AC-5 | 122 | 5. **Given** the feature implementation under its clean-architecture seams **When** link validates and delegates to the system **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A5 | automated |
| AC-6 | 123 | 6. **Given** the feature implementation under its clean-architecture seams **When** model-shaped failures come back as failure results **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A6 | automated |
| AC-7 | 124 | 7. **Given** the feature implementation under its clean-architecture seams **When** dispatchBatch maps every call in order **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A7 | automated |
| AC-8 | 125 | 8. **Given** the feature implementation under its clean-architecture seams **When** schema validation and risk tier **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A8 | automated |
| AC-9 | 126 | 9. **Given** the feature implementation under its clean-architecture seams **When** projection ranks by salience and marks session notes **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A9 | automated |
| AC-10 | 127 | 10. **Given** the feature implementation under its clean-architecture seams **When** agent story: remember, link, recall, project **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A10 | automated |
| AC-11 | 128 | 11. **Given** the feature implementation under its clean-architecture seams **When** an auto id never overwrites a memory stored under that id **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A11 | automated |
| AC-12 | 129 | 12. **Given** the feature implementation under its clean-architecture seams **When** a NaN salience is rejected as out of range **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A12 | automated |
| AC-13 | 130 | 13. **Given** the feature implementation under its clean-architecture seams **When** validateSchema rejects an explicit null for a required argument **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A13 | automated |
| AC-14 | 131 | 14. **Given** the feature implementation under its clean-architecture seams **When** renderWithSession applies limit per layer **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`). | A14 | automated |

