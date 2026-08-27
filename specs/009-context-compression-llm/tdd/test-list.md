# Test List: Context Compression (LLM-based)

---
feature: 009-context-compression-llm
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 5 # acceptance criteria AC-1..AC-5 in spec.md
planned_at: 878fe98
updated_at: d660dca
suite_baseline: red # 6 pre-existing loading failures (unrelated features); green criterion = feature tests pass AND failure delta vs the spec-008 baseline (6 loading failures) is zero new
---

## Outer loop: acceptance behaviors

One per acceptance criterion, through the feature's real entry point — `LLMBasedContextCompressor.compress()` and `EpisodicMemoryStore` retrieval.

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| A1  | History exceeding tokenThreshold compresses to a five-section `<state_snapshot>` XML | AC-1   | example | DONE | `context_compressor_test.dart::U4`+`U6` |
| A2  | The snapshot is stored as an episodic memory entry and recent messages are preserved | AC-2   | example | DONE | `context_compressor_test.dart::U8`+`U11` |
| A3  | A compression failure falls back to the heuristic summarizer | AC-3   | example | DONE | `context_compressor_test.dart::U6`+`U7` |
| A4  | retrieve_memory returns the snapshot with its original messages | AC-4   | example | DONE | `episodic_memory_store_test.dart::U2` |
| A5  | A custom tokenThreshold triggers compression earlier | AC-5   | example | DONE | `context_compressor_test.dart::U10` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/episodic_memory/episodic_memory.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U1  | EpisodicMemory carries id, XML summary, and original messages with JSON round-trip | FR-003, AC-4 | example | DONE | `episodic_memory_test.dart::U1` |

### `lib/src/llm/episodic_memory_store.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U2  | The store adds, retrieves by id, and searches entries — returning the snapshot with its original messages | AC-4, FR-003 | example | DONE | `episodic_memory_store_test.dart::U2` |

### `lib/src/llm/context_compressor.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U3  | Below tokenThreshold compress() returns an identity result (strategy none, no LLM call, no memory entry) | FR-001 | example | DONE | `context_compressor_test.dart::U3` |
| U4  | Above threshold the LLM is called once; the last keepRecentMessages stay verbatim; older messages are compressed | FR-001, FR-002, FR-004 | example | DONE | `context_compressor_test.dart::U4` |
| U5  | The compression prompt names the five XML sections and carries the older messages | FR-002, SC-002 | example | DONE | `context_compressor_test.dart::U5` |
| U6  | An invalid XML snapshot (missing sections) falls back to the heuristic summarizer | FR-005, SC-003 | example | DONE | `context_compressor_test.dart::U6` |
| U7  | An LLM error falls back to the heuristic summarizer | FR-005, SC-003 | example | DONE | `context_compressor_test.dart::U7` |
| U8  | Compression creates an EpisodicMemory entry (snapshot + originals) retrievable from the store | FR-003, AC-2 | example | DONE | `context_compressor_test.dart::U8` |
| U9  | A 100-message conversation compresses to <3000 total tokens (snapshot + preserved) | SC-001 | example | DONE | `context_compressor_test.dart::U9` |
| U10 | tokenThreshold 32000 triggers where 64000 does not; messageCountThreshold honored | AC-5 | example | DONE | `context_compressor_test.dart::U10` |
| U11 | The heuristic fallback also creates a memory entry and preserves recent messages | FR-005, AC-2 | example | DONE | `context_compressor_test.dart::U11` |

## Invariants and edge cases still to place

- The store returns entries in insertion order — placed inside U2.
- Repeated compression below threshold never grows the store — placed inside U3.

## Out of scope

- Engine-loop trigger wiring (spec 002) and tool-registry integration of retrieve_memory (spec 003).
- Persistence of episodic memories across restarts (session-store specs).
- Prompt-engineering quality of the snapshot content beyond the section contract (no criterion).

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test {file} --name "{name}" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage`
- Mutation: none installed — deliberate mutants per rubric
