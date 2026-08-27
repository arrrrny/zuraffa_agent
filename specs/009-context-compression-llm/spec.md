# Feature Specification: Context Compression (LLM-based)

**Feature Branch**: `009-context-compression-llm`

**Created**: 2026-08-27

**Status**: Approved *(refined by /speckit.specify — added acceptance-criterion ids AC-1..AC-5, measurable SCs, and assumptions mapping AgentState→the engine's AgentMessage model, pinning the XML section contract, and scoping the retrieve_memory surface)*

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has HeuristicSummarizer but no LLM-based compression; dart_agent_core uses LLM to generate XML state snapshots.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic context compression (Priority: P1)

As the engine, when conversation history exceeds a token threshold, I compress older messages into a structured XML snapshot using an LLM call, preserving recent messages verbatim.

**Why this priority**: Long conversations hit provider context windows; compression enables extended missions.

**Independent Test**: A 100-message conversation compresses to a ~2000-token snapshot + 10 recent messages, preserving key decisions, file state, and plan progress.

**Acceptance Scenarios**:

1. **Given** history exceeding tokenThreshold, **When** compression triggers, **Then** an LLM generates a `<state_snapshot>` with sections: overall_goal, key_knowledge, file_system_state, recent_actions, current_plan. **[AC-1]**
2. **Given** compressed history, **When** the agent continues, **Then** the snapshot is prepended as an episodic memory entry, and recent messages are preserved. **[AC-2]**
3. **Given** a compression failure, **When** it occurs, **Then** the engine falls back to the heuristic summarizer. **[AC-3]**

### User Story 2 - Episodic memory from compression (Priority: P1)

As the engine, compressed messages become EpisodicMemory entries that can be retrieved later via a `retrieve_memory` tool.

**Why this priority**: Compressed history must be accessible, not lost.

**Independent Test**: After compression, the agent can retrieve and reference earlier decisions via the memory tool.

**Acceptance Scenarios**:

1. **Given** a compressed conversation, **When** `retrieve_memory` is called, **Then** the snapshot is returned with its original messages. **[AC-4]**

### User Story 3 - Configurable thresholds (Priority: P2)

As an operator, I configure when compression triggers (token threshold, message count) and what the snapshot includes.

**Why this priority**: Different use cases have different compression needs.

**Independent Test**: Changing the threshold from 64000 to 32000 tokens triggers compression earlier.

**Acceptance Scenarios**:

1. **Given** a custom tokenThreshold, **When** history exceeds it, **Then** compression triggers at the configured point. **[AC-5]**

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST compress conversation history when token threshold is exceeded.
- **FR-002**: Compression MUST use an LLM to generate a structured XML snapshot.
- **FR-003**: Compressed messages MUST become EpisodicMemory entries.
- **FR-004**: Recent messages MUST be preserved verbatim after compression.
- **FR-005**: The engine MUST fall back to heuristic summarization on LLM failure.

### Key Entities

- **ContextCompressor** (interface): compress(messages) → CompressionResult *(the spec draft's AgentState/CompressedState shapes map onto this engine's List<AgentMessage> model — see Assumptions)*
- **LLMBasedContextCompressor**: LLM-powered implementation
- **EpisodicMemory** (domain entity): id, summary (XML), messages (original)
- **EpisodicMemoryStore**: in-memory store + retrieval (the `retrieve_memory` surface)
- **CompressionResult**: snapshot, preservedMessages, compressedMessages, memory, strategy
- **ContextCompressionSettings**: tokenThreshold (default 64000), keepRecentMessages (default 10), messageCountThreshold (optional)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A 100-message conversation compresses to <3000 tokens total (snapshot + preserved messages, measured with the engine's token estimator).
- **SC-002**: Key decisions and file state are preserved in the snapshot — the snapshot XML carries the five contract sections and the compression prompt explicitly asks for decisions and file state.
- **SC-003**: Fallback to heuristic summarizer works on LLM failure (and on an invalid XML snapshot).
- **SC-004**: `dart analyze` pristine for all files added by this feature; zero new full-suite failures vs. the spec-008 baseline (6 unrelated pre-existing failures).

## Assumptions

- dart_agent_core's `AgentState` does not exist in this engine; the compressor operates on `List<AgentMessage>` (the engine's conversation model from `lib/src/types.dart`). Token estimation reuses `estimateContextTokens` from `lib/src/compaction.dart` (4 chars/token heuristic) so thresholds are measurable in tests.
- The XML snapshot contract is exactly: `<state_snapshot>` root with child sections `overall_goal`, `key_knowledge`, `file_system_state`, `recent_actions`, `current_plan` (US1). Validation = presence of the root tag and all five section tags; an invalid snapshot is treated as an LLM failure and falls back (FR-005).
- The LLM call goes through spec 007's `LlmClient.generate()` with a system prompt that names the five sections; the older (compressed) messages are the conversation payload.
- The heuristic fallback wraps the existing `HeuristicSummarizer` (from `lib/src/compaction.dart`): compressed messages are adapted to `MessageEntry` inputs, and the resulting `CompactionSummary` is rendered into the same five-section XML shape so downstream consumers see one snapshot format (strategy records which path produced it).
- `EpisodicMemory` is a Zorphy-generated domain entity (constitution IX) at the repo's standard entity path; the runtime pieces (compressor, store) live in `lib/src/llm/` per spec 007/008 layering.
- The `retrieve_memory` tool surface for US2 is the `EpisodicMemoryStore` retrieval API (by id and by query); wiring it into the engine's tool registry belongs to spec 002/003 and is explicitly out of scope here.
- Compression happens eagerly when `compress()` is called and the threshold is exceeded; below threshold it returns an identity result (strategy `none`, no memory entry).
- The compressor stores the created `EpisodicMemory` in the injected `EpisodicMemoryStore` (default: an in-memory instance) so entries are retrievable immediately after compression.

## Dependencies

- After: spec 001 (session management), spec 007 (LLM clients for compression call)
- Feeds: spec 002 (engine loop triggers compression), spec 010 (episodic memory system builds on the entity + store)
