# Traceability: 080-agent-message-history

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:46bdc95b2c6a76343860a6e7afd9c4696a72f8c5c4e1449a82f4b29e039a5810
statements: 27
automated: 27
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 135 | - **FR-001**: `AgentMessageHistory.==` MUST return `true` iff both | U1 | automated |
| FR-002 | 140 | - **FR-002**: `AgentMessageHistory.hashCode` MUST agree with `==` — | U2 | automated |
| FR-003 | 143 | - **FR-003**: `AgentMessageHistory.toJson()` MUST return a | U3, U10 | automated |
| FR-004 | 146 | - **FR-004**: The system MUST satisfy this requirement: `AgentMessageHistory.fromJson(Map<String, dynamic> json)` | U4 | automated |
| FR-005 | 149 | - **FR-005**: `AgentMessageHistory.fromJson` MUST throw `ArgumentError` | U5 | automated |
| FR-006 | 161 | - **FR-006**: `truncate(int keep)` MUST return a new | U6 | automated |
| FR-007 | 166 | - **FR-007**: The system MUST satisfy this requirement: existing pure transforms (`appendMessages`, `addMemory`, | U7 | automated |
| FR-008 | 169 | - **FR-008**: existing constructor + `memorySummaries` MUST remain | U8 | automated |
| FR-009 | 171 | - **FR-009**: The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the | U9 | automated |
| FR-003 | 196 | - **FR-003**: The system MUST satisfy this requirement: / FR-004). | U3, U10 | automated |
| AC-1 | 228 | 1. **Given** the feature implementation under its clean-architecture seams **When** U1: equal histories (same message instances + same memory instances) are == **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A1 | automated |
| AC-2 | 229 | 2. **Given** the feature implementation under its clean-architecture seams **When** U2: appending a message breaks == **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A2 | automated |
| AC-3 | 230 | 3. **Given** the feature implementation under its clean-architecture seams **When** U3: appending a memory breaks == **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A3 | automated |
| AC-4 | 231 | 4. **Given** the feature implementation under its clean-architecture seams **When** U4: hashCode agrees with == **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A4 | automated |
| AC-5 | 232 | 5. **Given** the feature implementation under its clean-architecture seams **When** U5: toJson → fromJson preserves structural shape (lossless round-trip) **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A5 | automated |
| AC-6 | 233 | 6. **Given** the feature implementation under its clean-architecture seams **When** U6: empty history round-trips **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A6 | automated |
| AC-7 | 234 | 7. **Given** the feature implementation under its clean-architecture seams **When** U7: toJson shape has exactly two keys **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A7 | automated |
| AC-8 | 235 | 8. **Given** the feature implementation under its clean-architecture seams **When** U8: truncate(N).episodicMemories == receiver.episodicMemories **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A8 | automated |
| AC-9 | 236 | 9. **Given** the feature implementation under its clean-architecture seams **When** U9: truncate(0).episodicMemories == receiver.episodicMemories **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A9 | automated |
| AC-10 | 237 | 10. **Given** the feature implementation under its clean-architecture seams **When** U10: missing messages throws ArgumentError naming messages **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A10 | automated |
| AC-11 | 238 | 11. **Given** the feature implementation under its clean-architecture seams **When** U11: messages not a list throws ArgumentError naming messages **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A11 | automated |
| AC-12 | 239 | 12. **Given** the feature implementation under its clean-architecture seams **When** U12: missing episodicMemories throws ArgumentError naming episodicMemories **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A12 | automated |
| AC-13 | 240 | 13. **Given** the feature implementation under its clean-architecture seams **When** U13: malformed inner message (not a Map) throws ArgumentError naming messages[0] **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A13 | automated |
| AC-14 | 241 | 14. **Given** the feature implementation under its clean-architecture seams **When** U14: malformed inner memory (missing id) throws ArgumentError naming episodicMemories[0] **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A14 | automated |
| AC-15 | 242 | 15. **Given** the feature implementation under its clean-architecture seams **When** U15: appendMessages returns a new value; receiver unchanged **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A15 | automated |
| AC-16 | 243 | 16. **Given** the feature implementation under its clean-architecture seams **When** U16: addMemory returns a new value; receiver unchanged **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A16 | automated |
| AC-17 | 244 | 17. **Given** the feature implementation under its clean-architecture seams **When** U17: truncate returns a new value; receiver unchanged **Then** the pinned regression test passes (`test/llm/agent_message_history_080_test.dart`). | A17 | automated |

