# Feature Specification: Episodic Memory

**Feature Branch**: `010-episodic-memory`

**Created**: 2026-08-27

**Status**: Approved *(refined by /speckit.specify — added acceptance-criterion ids AC-1..AC-5, numbered FRs kept verbatim from the draft, pinned the persistence encoding (CustomEntry escape hatch), the pagination contract (insertion order, limit/offset), and the retrieve_memory tool surface; the EpisodicMemory entity and in-memory EpisodicMemoryStore already exist from spec 009 and are extended, not replaced)*

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has compaction but no episodic memory concept; dart_agent_core preserves compressed history as retrievable memory entries.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Memory from compression (Priority: P1)

As the engine, when context is compressed, the compressed messages become EpisodicMemory entries with a summary and the original messages, stored alongside the active conversation.

**Why this priority**: Compressed history must be preserved and retrievable, not lost.

**Independent Test**: After 3 compressions, the agent has 3 episodic memory entries covering the full conversation history.

**Acceptance Scenarios**:

1. **Given** a compression event, **When** it completes, **Then** an EpisodicMemory entry is created with the XML snapshot and original messages. **[AC-1]**
2. **Given** episodic memories exist, **When** the agent builds context, **Then** memory summaries are available for retrieval (AgentMessageHistory carries messages + episodicMemories). **[AC-2]**
3. **Given** three successive compression events on a growing conversation, **When** all three complete, **Then** the store holds exactly 3 entries whose combined original messages cover the full compressed history. **[AC-3]**

### User Story 2 - Memory retrieval tool (Priority: P1)

As the model, I can call `retrieve_memory` to access earlier conversation history that was compressed, with pagination support.

**Why this priority**: The agent needs to reference earlier decisions and context.

**Independent Test**: A mission that compresses early context can still retrieve specific decisions via the memory tool.

**Acceptance Scenarios**:

1. **Given** episodic memories exist, **When** `retrieve_memory` is called with snapshot_id, **Then** the specific memory is returned — with its original messages, not just the summary. **[AC-4]**
2. **Given** episodic memories exist, **When** `retrieve_memory` is called with limit/offset, **Then** paginated results are returned. **[AC-5]**

### User Story 3 - Memory persistence (Priority: P2)

As the engine, episodic memories persist across sessions via the session storage backend.

**Why this priority**: Long-running agents need memory across restarts.

**Independent Test**: After engine restart, episodic memories are loaded from storage.

**Acceptance Scenarios**:

1. **Given** persisted episodic memories, **When** the session loads, **Then** memories are restored. **[AC-3 — the persistence half]**

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Compression events MUST create EpisodicMemory entries. *(already green from spec 009's U8/U11 — this spec pins it with a multi-compression acceptance test rather than re-implementing)*
- **FR-002**: A `retrieve_memory` tool MUST expose episodic memories to the model.
- **FR-003**: EpisodicMemory MUST store both the summary (XML) and original messages. *(entity exists from spec 009; unchanged)*
- **FR-004**: Retrieval MUST support snapshot_id lookup and limit/offset pagination.
- **FR-005**: EpisodicMemory MUST persist via the session storage backend.

### Key Entities

- **EpisodicMemory** *(exists, spec 009)*: id, summary (XML string), messages (List<AgentMessage>) — unchanged.
- **EpisodicMemoryStore** *(exists, spec 009 — extended here)*: add/retrieve/search plus a new `list({int? limit, int? offset})` pagination surface (FR-004).
- **AgentMessageHistory** *(new)*: messages + episodicMemories — the context-assembly value object; exposes `memorySummaries` so the engine can surface memory summaries when building context (US1 AC2).
- **RetrieveMemoryTool** *(new)*: model-facing tool; parameters `snapshot_id?`, `limit?`, `offset?`; returns the specific memory (with original messages) or a paginated summary listing.
- **PersistentEpisodicMemoryStore** *(new)*: an EpisodicMemoryStore that mirrors every `add` into the SessionStorage backend as a CustomEntry (`customType: 'episodic_memory'`, payload = memory JSON) and rebuilds entries on `restore()` (FR-005).
- **retrieve_memory** tool: snapshot_id, limit, offset parameters *(the LlmToolSpec surface of RetrieveMemoryTool)*.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After 3 compressions, 3 memory entries exist and are retrievable (combined originals cover the full history).
- **SC-002**: Memory retrieval returns original messages, not just summaries.
- **SC-003**: Memories persist across session reloads (restore() rebuilds the store from the storage backend).
- **SC-004**: `dart analyze` reports zero issues in files added by this feature; the full suite adds no new failures vs. the spec-009 baseline (+453 passed / 6 unrelated pre-existing loading failures).

## Dependencies

- After: spec 009 (context compression creates memories)
- Feeds: spec 002 (engine loop uses memories in context)

## Assumptions

- The EpisodicMemory entity and in-memory EpisodicMemoryStore from spec 009 are the foundation; this spec extends the store with pagination, adds the tool + history + persistence layers, and does not duplicate the entity.
- Persistence uses the existing `CustomEntry` tree-entry escape hatch (`customType: 'episodic_memory'`, `payload: jsonEncode(memory.toJson())`) rather than adding a new SessionTreeEntry subclass to the pi_agent-ported `types.dart` — CustomEntry exists precisely for consumer-defined record kinds.
- `SessionStorage` (lib/src/session_storage.dart) is the persistence port; tests use an in-memory fake (the concrete backends are hive/jsonl IO adapters gated by the purity allowlist).
- The model-facing tool surface follows the LlmToolSpec shape from spec 007 (name + description + JSON-Schema parameters); tool *execution* is engine-side and returns a structured result object the engine renders for the model.
- Pagination semantics: insertion order (oldest first, matching how entries were created), `offset` skips entries, `limit` caps the page; `limit <= 0` yields an empty page (not an exception) so a misbehaving model call degrades gracefully.
