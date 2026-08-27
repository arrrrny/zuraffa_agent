# Feature Specification: Context Compression (LLM-based)

**Feature Branch**: `009-context-compression-llm`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has HeuristicSummarizer but no LLM-based compression; dart_agent_core uses LLM to generate XML state snapshots.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic context compression (Priority: P1)

As the engine, when conversation history exceeds a token threshold, I compress older messages into a structured XML snapshot using an LLM call, preserving recent messages verbatim.

**Why this priority**: Long conversations hit provider context windows; compression enables extended missions.

**Independent Test**: A 100-message conversation compresses to a ~2000-token snapshot + 10 recent messages, preserving key decisions, file state, and plan progress.

**Acceptance Scenarios**:

1. **Given** history exceeding tokenThreshold, **When** compression triggers, **Then** an LLM generates an `<state_snapshot>` with sections: overall_goal, key_knowledge, file_system_state, recent_actions, current_plan.
2. **Given** compressed history, **When** the agent continues, **Then** the snapshot is prepended as an episodic memory entry, and recent messages are preserved.
3. **Given** a compression failure, **When** it occurs, **Then** the engine falls back to the heuristic summarizer.

### User Story 2 - Episodic memory from compression (Priority: P1)

As the engine, compressed messages become EpisodicMemory entries that can be retrieved later via a `retrieve_memory` tool.

**Why this priority**: Compressed history must be accessible, not lost.

**Independent Test**: After compression, the agent can retrieve and reference earlier decisions via the memory tool.

**Acceptance Scenarios**:

1. **Given** a compressed conversation, **When** `retrieve_memory` is called, **Then** the snapshot is returned with its original messages.

### User Story 3 - Configurable thresholds (Priority: P2)

As an operator, I configure when compression triggers (token threshold, message count) and what the snapshot includes.

**Why this priority**: Different use cases have different compression needs.

**Independent Test**: Changing the threshold from 64000 to 32000 tokens triggers compression earlier.

**Acceptance Scenarios**:

1. **Given** a custom tokenThreshold, **When** history exceeds it, **Then** compression triggers at the configured point.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST compress conversation history when token threshold is exceeded.
- **FR-002**: Compression MUST use an LLM to generate a structured XML snapshot.
- **FR-003**: Compressed messages MUST become EpisodicMemory entries.
- **FR-004**: Recent messages MUST be preserved verbatim after compression.
- **FR-005**: The engine MUST fall back to heuristic summarization on LLM failure.

### Key Entities

- **ContextCompressor** (interface): compress(AgentState) → CompressedState
- **LLMBasedContextCompressor**: LLM-powered implementation
- **EpisodicMemory**: id, summary (XML), messages (original)
- **CompressionResult**: snapshot, preservedMessages, compressedMessages

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A 100-message conversation compresses to <3000 tokens total.
- **SC-002**: Key decisions and file state are preserved in the snapshot.
- **SC-003**: Fallback to heuristic summarizer works on LLM failure.

## Dependencies

- After: spec 001 (session management), spec 007 (LLM clients for compression call)
- Feeds: spec 002 (engine loop triggers compression)
