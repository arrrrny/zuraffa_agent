# Feature Specification: Episodic Memory

**Feature Branch**: `010-episodic-memory`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has compaction but no episodic memory concept; dart_agent_core preserves compressed history as retrievable memory entries.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Memory from compression (Priority: P1)

As the engine, when context is compressed, the compressed messages become EpisodicMemory entries with a summary and the original messages, stored alongside the active conversation.

**Why this priority**: Compressed history must be preserved and retrievable, not lost.

**Independent Test**: After 3 compressions, the agent has 3 episodic memory entries covering the full conversation history.

**Acceptance Scenarios**:

1. **Given** a compression event, **When** it completes, **Then** an EpisodicMemory entry is created with the XML snapshot and original messages.
2. **Given** episodic memories exist, **When** the agent builds context, **Then** memory summaries are available for retrieval.

### User Story 2 - Memory retrieval tool (Priority: P1)

As the model, I can call `retrieve_memory` to access earlier conversation history that was compressed, with pagination support.

**Why this priority**: The agent needs to reference earlier decisions and context.

**Independent Test**: A mission that compresses early context can still retrieve specific decisions via the memory tool.

**Acceptance Scenarios**:

1. **Given** episodic memories exist, **When** `retrieve_memory` is called with snapshot_id, **Then** the specific memory is returned.
2. **Given** episodic memories exist, **When** `retrieve_memory` is called with limit/offset, **Then** paginated results are returned.

### User Story 3 - Memory persistence (Priority: P2)

As the engine, episodic memories persist across sessions via the session storage backend.

**Why this priority**: Long-running agents need memory across restarts.

**Independent Test**: After engine restart, episodic memories are loaded from storage.

**Acceptance Scenarios**:

1. **Given** persisted episodic memories, **When** the session loads, **Then** memories are restored.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Compression events MUST create EpisodicMemory entries.
- **FR-002**: A `retrieve_memory` tool MUST expose episodic memories to the model.
- **FR-003**: EpisodicMemory MUST store both the summary (XML) and original messages.
- **FR-004**: Retrieval MUST support snapshot_id lookup and limit/offset pagination.
- **FR-005**: EpisodicMemory MUST persist via the session storage backend.

### Key Entities

- **EpisodicMemory**: id, summary (XML string), messages (List<AgentMessage>)
- **AgentMessageHistory**: messages + episodicMemories
- **retrieve_memory** tool: snapshot_id, limit, offset parameters

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After 3 compressions, 3 memory entries exist and are retrievable.
- **SC-002**: Memory retrieval returns original messages, not just summaries.
- **SC-003**: Memories persist across session reloads.

## Dependencies

- After: spec 009 (context compression creates memories)
- Feeds: spec 002 (engine loop uses memories in context)
