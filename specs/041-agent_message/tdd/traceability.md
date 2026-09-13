# Traceability: 041-agent_message

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:93e7a3963c1c5a555b7dc15e02c587abc1f2b5a91c755872ac1af6b57b1256fa
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a message with empty `id` or empty `role`, **When** constructed, **Then** `ArgumentError` is thrown naming the field. | A1 | automated |
| AC-2 | 27 | 2. **Given** two messages equal in id/role with distinct-but-equal `parts` list instances, **When** compared, **Then** they are `==` and share `hashCode` (the bug the shipped `parts == other.parts` identity comparison causes). | A2 | automated |
| AC-3 | 29 | 3. **Given** two messages differing in id, role, or parts content, **Then** they are unequal. | A3 | automated |
| AC-4 | 44 | 4. **Given** a history of 3 messages, **When** `truncate(2)`, **Then** the result keeps messages 2..3 (the most recent), `episodicMemories` is unchanged, and `memorySummaries` is unchanged. | A4 | automated |
| AC-5 | 46 | 5. **Given** `truncate(0)`, **Then** messages is empty and memories survive; **given** `truncate(-1)`, **Then** `ArgumentError`. | A5 | automated |
| AC-6 | 48 | 6. **Given** `truncate(n)` with n >= length, **Then** the result equals a history with the same messages/memories (content-equal, not necessarily identical). | A6 | automated |
| AC-7 | 50 | 7. **Given** a history, **When** `appendMessages([m])`, **Then** messages grow oldest-first at the end and memories are unchanged (pin of shipped behavior). | A7 | automated |
| AC-8 | 65 | 8. **Given** the untouched sealed hierarchy, **When** the suite runs, **Then** all pre-existing types tests pass (pinned; no new code). | A8 | automated |
| FR-001 | 80 | - **FR-001**: `AgentMessage` MUST reject with `ArgumentError` an empty `id` or empty `role` (message naming the field); `parts` may be any (including empty) list. | U1 | automated |
| FR-002 | 81 | - **FR-002**: `AgentMessage` equality MUST compare `id`, `role`, and `parts` with ELEMENT-WISE list equality (distinct-but-equal instances compare equal); `hashCode` MUST fold `parts` content (e.g. `Object.hashAll`) so equal messages hash equally. | U2 | automated |
| FR-003 | 82 | - **FR-003**: The system MUST satisfy this requirement: `AgentMessageHistory.appendMessages` keeps its shipped semantics (new messages appended oldest-first; memories untouched) — pinned, not changed. | U3 | automated |
| FR-004 | 83 | - **FR-004**: `AgentMessageHistory.truncate(int keep)` MUST return a new history whose `messages` are the LAST `keep` messages (`0` → empty), with `episodicMemories` unchanged; `keep < 0` MUST throw `ArgumentError`; `keep >= length` MUST return a content-equal history. | U4 | automated |
| FR-005 | 84 | - **FR-005**: The system MUST satisfy this requirement: `addMemory` keeps its shipped semantics (insertion-order append of an episodic memory) — pinned, not changed. | U5 | automated |
| FR-006 | 85 | - **FR-006**: The sealed `AgentMessage` hierarchy in `lib/src/types.dart` (roles, content parts, JSON round-trips) MUST remain byte-identical — its coverage stays in `types_test.dart` (pinned). | U6 | automated |
| FR-007 | 86 | - **FR-007**: The clean-arch layers (`AgentMessageService.current/count`, `AgentMessageProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature. | U7 | automated |

