# Feature Specification: Agent Message History

**Feature Branch**: `080-agent-message-history`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for the Agent Message History value object — active messages plus episodic memories with pure append/truncate/add-memory operations — that is not yet covered by an existing spec (R1/R2)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build and grow the model context (Priority: P1)

The engine assembles the model prompt from an ordered list of active conversation messages plus the episodic memories produced by earlier compressions. As the turn loop runs, messages are appended and the window is truncated to keep the active context within budget.

**Why this priority**: This is the core value object the engine loop consumes when building each model call; correctness here bounds context size and memory retention.

**Independent Test**: Can be fully tested by constructing a history, calling `appendMessages`/`truncate`/`addMemory`, and asserting the resulting message/memory lists and purity.

**Acceptance Scenarios**:

1. **Given** a history with messages `[m1, m2]`, **When** `appendMessages([m3])` is called, **Then** the result has `[m1, m2, m3]` and the original history is unchanged.
2. **Given** a history with 5 active messages, **When** `truncate(2)` is called, **Then** the result has the LAST 2 messages `[m4, m5]` and episodic memories are preserved.

---

### User Story 2 - Truncate without losing memory (Priority: P2)

Long conversations hit the context window. Truncation evicts oldest active messages but must never drop an episodic memory summary, since those are the only record of compressed history.

**Why this priority**: Memory loss on truncation would silently erase long-term context.

**Independent Test**: Can be fully tested by truncating to 0 with memories present and asserting memories survive while active window empties.

**Acceptance Scenarios**:

1. **Given** a history with 3 messages and 2 memories, **When** `truncate(0)` is called, **Then** the result has 0 active messages but still 2 memories.
2. **Given** any history, **When** `truncate(-1)` is called, **Then** an `ArgumentError` is thrown.

---

### Edge Cases

- `truncate(keep)` where `keep >= messages.length` returns the history unchanged (no eviction, no copy churn beyond the value object).
- `truncate(0)` yields an empty active window but preserves all memories.
- Negative `keep` throws `ArgumentError` (contract, not silent clamp).
- `addMemory` appends in insertion order; `memorySummaries` reflects insertion order.
- All operations are pure: the receiver is never mutated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The history MUST hold an ordered list of active messages (oldest first) and an ordered list of episodic memories (insertion order).
- **FR-002**: `appendMessages` MUST return a new history with the appended messages, leaving the receiver unchanged (pure).
- **FR-003**: `truncate(keep)` MUST retain the LAST `keep` active messages (oldest evicted first) and MUST preserve all episodic memories.
- **FR-004**: `truncate` MUST throw `ArgumentError` when `keep` is negative, and MUST return an empty active window when `keep == 0`.
- **FR-005**: `addMemory` MUST append an episodic memory in insertion order and MUST be pure.
- **FR-006**: `memorySummaries` MUST return the per-memory summary list in insertion order.

### Key Entities

- **AgentMessageHistory**: `{ messages: List<AgentMessage>, episodicMemories: List<EpisodicMemory> }` — the model-facing context view.
- **EpisodicMemory**: a compressed summary from an earlier compaction (referenced, not redefined here).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Truncation never reduces the memory count (memories ride along untouched across all `keep` values).
- **SC-002**: A negative `keep` always throws `ArgumentError`; a `keep >= length` always returns the receiver's content unchanged.
- **SC-003**: Every mutating operation is pure — the receiver's message/memory lists are byte-identical before and after the call.

## Assumptions

- `AgentMessage` and `EpisodicMemory` are provided by sibling modules (specs 002 / 010); this spec owns only the composition + pure transforms.
- "Insertion order" for memories means the order in which `addMemory` was called / memories were originally produced.
- This feature maps to **R1 (engine core, issue #2)** for context assembly and **R2 (state & sessions, issue #3)** for memory retention.
