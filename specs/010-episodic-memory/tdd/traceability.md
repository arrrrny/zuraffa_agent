# Traceability: 010-episodic-memory

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:179b362ed545ba430939c53d0d969bb296eb9f8769c14289801f2f8aaf87e2a1
statements: 11
automated: 11
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a compression event, **When** it completes, **Then** an EpisodicMemory entry is created with the XML snapshot and original messages. **[AC-1]** | A1 | automated |
| AC-2 | 27 | 2. **Given** episodic memories exist, **When** the agent builds context, **Then** memory summaries are available for retrieval (AgentMessageHistory carries messages + episodicMemories). **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** three successive compression events on a growing conversation, **When** all three complete, **Then** the store holds exactly 3 entries whose combined original messages cover the full compressed history. **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** episodic memories exist, **When** `retrieve_memory` is called with snapshot_id, **Then** the specific memory is returned — with its original messages, not just the summary. **[AC-4]** | A4 | automated |
| AC-5 | 44 | 5. **Given** episodic memories exist, **When** `retrieve_memory` is called with limit/offset, **Then** paginated results are returned. **[AC-5]** | A5 | automated |
| AC-6 | 57 | 6. **Given** persisted episodic memories, **When** the session loads, **Then** memories are restored. **[AC-3 — the persistence half]** | A6 | automated |
| FR-001 | 64 | - **FR-001**: Compression events MUST create EpisodicMemory entries. *(already green from spec 009's U8/U11 — this spec pins it with a multi-compression acceptance test rather than re-implementing)* | U1 | automated |
| FR-002 | 65 | - **FR-002**: A `retrieve_memory` tool MUST expose episodic memories to the model. | U2 | automated |
| FR-003 | 66 | - **FR-003**: EpisodicMemory MUST store both the summary (XML) and original messages. *(entity exists from spec 009; unchanged)* | U3 | automated |
| FR-004 | 67 | - **FR-004**: Retrieval MUST support snapshot_id lookup and limit/offset pagination. | U4 | automated |
| FR-005 | 68 | - **FR-005**: EpisodicMemory MUST persist via the session storage backend. | U5 | automated |

