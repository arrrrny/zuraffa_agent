# Traceability: 009-context-compression-llm

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:817d552a05a7a926e0a5516ec7c0b4252726476c90c5184596dc2020b5a22984
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** history exceeding tokenThreshold, **When** compression triggers, **Then** an LLM generates a `<state_snapshot>` with sections: overall_goal, key_knowledge, file_system_state, recent_actions, current_plan. **[AC-1]** | A1 | automated |
| AC-2 | 27 | 2. **Given** compressed history, **When** the agent continues, **Then** the snapshot is prepended as an episodic memory entry, and recent messages are preserved. **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** a compression failure, **When** it occurs, **Then** the engine falls back to the heuristic summarizer. **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** a compressed conversation, **When** `retrieve_memory` is called, **Then** the snapshot is returned with its original messages. **[AC-4]** | A4 | automated |
| AC-5 | 55 | 5. **Given** a custom tokenThreshold, **When** history exceeds it, **Then** compression triggers at the configured point. **[AC-5]** | A5 | automated |
| FR-001 | 62 | - **FR-001**: The engine MUST compress conversation history when token threshold is exceeded. | U1 | automated |
| FR-002 | 63 | - **FR-002**: Compression MUST use an LLM to generate a structured XML snapshot. | U2 | automated |
| FR-003 | 64 | - **FR-003**: Compressed messages MUST become EpisodicMemory entries. | U3 | automated |
| FR-004 | 65 | - **FR-004**: Recent messages MUST be preserved verbatim after compression. | U4 | automated |
| FR-005 | 66 | - **FR-005**: The engine MUST fall back to heuristic summarization on LLM failure. | U5 | automated |

