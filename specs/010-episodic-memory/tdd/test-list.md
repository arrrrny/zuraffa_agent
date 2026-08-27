# Test List: Episodic Memory

---
feature: 010-episodic-memory
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 5 # acceptance criteria AC-1..AC-5 in spec.md
planned_at: 26b289c
updated_at: 26b289c
suite_baseline: red # 6 pre-existing loading failures (unrelated features); green criterion = feature tests pass AND failure delta vs the spec-009 baseline (6 loading failures) is zero new
---

## Outer loop: acceptance behaviors

One per acceptance criterion, through the feature's real entry points — `LLMBasedContextCompressor.compress()` (spec 009), `PersistentEpisodicMemoryStore.restore()`, and `RetrieveMemoryTool.execute()`.

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| A1  | Three successive compressions on a growing conversation leave exactly 3 episodic memory entries whose combined originals cover the full history | AC-1, AC-3, SC-001 | example | DONE | `episodic_memory_acceptance_test.dart::A1` |
| A2  | Retrieval returns the original messages, not just the summary | AC-1, AC-4, SC-002 | example | DONE | `episodic_memory_acceptance_test.dart::A2` |
| A3  | Memories persist across a session reload (add → new store on same storage → restore → retrieve) | AC-3, SC-003 | example | DONE | `episodic_memory_acceptance_test.dart::A3` |
| A4  | retrieve_memory with snapshot_id returns that memory with its original messages (end-to-end through the tool) | AC-4 | example | DONE | `episodic_memory_acceptance_test.dart::A4` |
| A5  | retrieve_memory with limit/offset returns paginated results (end-to-end through the tool) | AC-5 | example | DONE | `episodic_memory_acceptance_test.dart::A5` |

## Inner loop: unit behaviors

### `lib/src/llm/agent_message_history.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U1  | AgentMessageHistory carries messages + episodicMemories and exposes memorySummaries (ordered, summary-only) for context building | AC-2 | example | DONE | `agent_message_history_test.dart::U1` |

### `lib/src/llm/episodic_memory_store.dart` (pagination extension)

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U2  | list() with no args returns all entries in insertion order (oldest first) | FR-004 | example | DONE | `episodic_memory_store_test.dart::U2` |
| U3  | list(limit: n) caps the page at n; list(offset: k) skips the first k; combined limit+offset slices the window | FR-004 | example | DONE | `episodic_memory_store_test.dart::U3` |
| U4  | Edge cases: offset beyond the end → empty page; limit <= 0 → empty page; an empty store lists empty at any offset | FR-004 | example | DONE | `episodic_memory_store_test.dart::U4` |

### `lib/src/llm/retrieve_memory_tool.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U5  | The tool advertises an LlmToolSpec named `retrieve_memory` with snapshot_id/limit/offset parameters in its schema | FR-002 | example | DONE | `retrieve_memory_tool_test.dart::U5` |
| U6  | execute({snapshot_id}) returns that memory with id, summary, and the full original messages | FR-002, FR-004, SC-002 | example | DONE | `retrieve_memory_tool_test.dart::U6` |
| U7  | execute({limit, offset}) returns a paginated listing (summaries + message counts) without dumping every original message | FR-004 | example | DONE | `retrieve_memory_tool_test.dart::U7` |
| U8  | execute({snapshot_id: unknown}) returns a typed not-found error result (not an exception) | FR-002 | example | DONE | `retrieve_memory_tool_test.dart::U8` |

### `lib/src/llm/persistent_episodic_memory_store.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U9  | add() mirrors the memory into SessionStorage as a CustomEntry with customType 'episodic_memory' and the memory JSON as payload | FR-005 | example | DONE | `persistent_episodic_memory_store_test.dart::U9` |
| U10 | restore() rebuilds store entries from the storage backend (decode payload → EpisodicMemory, insertion order preserved) | FR-005, SC-003 | example | DONE | `persistent_episodic_memory_store_test.dart::U10` |
| U11 | A restored store serves retrieve-by-id and pagination like an in-memory store (pass-through semantics) | FR-005, FR-004 | example | DONE | `persistent_episodic_memory_store_test.dart::U11` |

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| store.list slicing | slice window off-by-one (skip offset+1) | U3 (expects exact window) |
| tool.execute snapshot branch | drop snapshot_id branch → always list | U6 (expects single memory payload) |
| restore filter | invert customType filter → restore nothing | U10 (expects rebuilt entries) |
