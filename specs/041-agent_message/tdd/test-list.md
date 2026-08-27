---
feature: 041-agent_message
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 8
planned_at: 27e62e4
updated_at: 8b11a86
suite_baseline: green
---

# Test List: AgentMessage (multimodal parts) + history

## Outer loop: acceptance behaviors

Value objects — the public API is the entry point; `loop: inside-out`.

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| A1  | Empty id/role construction throws ArgumentError naming the field                | AC US1-1 | example         | DONE    | `agent_message_test.dart` (red @ `8e3faee`) |
| A2  | Distinct-instance equal-parts messages are == and hash equally                  | AC US1-2 | example         | DONE    | `agent_message_test.dart` (red @ `8e3faee` — the live bug) |
| A3  | Single-field differences (id/role/parts) break equality                         | AC US1-3 | example         | DONE    | `agent_message_test.dart` (red @ `8e3faee`) |
| A4  | truncate keeps the LAST N messages; memories + summaries unchanged              | AC US2-1 | example         | DONE    | `agent_message_history_041_test.dart` (red @ `8b11a86`, M2/M3 killed) |
| A5  | truncate(0) empties messages, memories survive; negative throws; n >= length content-equal | AC US2-2/3 | example | DONE | `agent_message_history_041_test.dart` (red @ `8b11a86`) |
| A6  | appendMessages appends oldest-first, memories unchanged (pin)                   | AC US2-4 | characterization | DONE (BASELINE + pin) | `agent_message_history_041_test.dart` |
| A7  | Sealed-hierarchy role/part dispatch stays green (pin)                           | AC US3-1 | characterization | DONE (BASELINE) | `test/types_test.dart` (40+ assertions) |
| A8  | Clean-arch stubs stay green (pin)                                               | FR-007   | characterization | DONE (BASELINE) | `agent_message_provider_test.dart` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/agent_message/agent_message.dart`

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U1  | Empty id throws naming 'id'; empty role throws naming 'role'; empty parts stay valid | FR-001   | example    | DONE    | `agent_message_test.dart` (red @ `8e3faee`, M1 killed) |
| U2  | parts equality is element-wise: ['hi'] built twice compares equal (distinct instances), hashCode equal | FR-002   | example | DONE    | `agent_message_test.dart` (red @ `8e3faee` — live bug) |
| U3  | Inequality axes: id differs, role differs, parts content differs                 | FR-002   | example         | DONE    | `agent_message_test.dart` (red @ `8e3faee`) |

### `lib/src/llm/agent_message_history.dart`

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U4  | truncate(2) on 3 messages keeps the last 2; episodicMemories + memorySummaries byte-stable | FR-004 | example | DONE    | `agent_message_history_041_test.dart` (red @ `8b11a86`, M2/M3 killed) |
| U5  | truncate(0) -> empty messages; truncate(-1) -> ArgumentError; truncate(999) content-equal | FR-004   | example | DONE    | `agent_message_history_041_test.dart` (red @ `8b11a86`) |
| U6  | truncate does not mutate the receiver (immutable copy semantics)                 | FR-004   | example         | DONE    | `agent_message_history_041_test.dart` (red @ `8b11a86`) |
| U7  | appendMessages grows messages at the end; episodicMemories unchanged (pin)       | FR-003   | characterization | DONE (BASELINE + pin) | `agent_message_history_041_test.dart` |
| U8  | addMemory appends in insertion order (pin)                                      | FR-005   | characterization | DONE (BASELINE + pin) | `agent_message_history_041_test.dart` |

### Pinned, untouched surfaces (FR-006/007)

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U9  | types.dart sealed hierarchy: role dispatch, part round-trips, unknown-role rejection (pin) | FR-006 | characterization | BASELINE | `test/types_test.dart` |
| U10 | The 5 pre-existing entity + clean-arch stub tests keep passing unchanged         | FR-007   | characterization | BASELINE | `test/data/providers/agent_message/agent_message_provider_test.dart` |

## Invariants and edge cases still to place

- ==/hashCode consistency after the equality fix: equal messages (any parts
  instance shape) hash equally — U2 asserts both directions.
- Truncate + append commutation on memories: memories ride along every
  messages-only operation (asserted inside U4/U7 fixtures).

## Out of scope

- Parts types gaining value equality (ContentBlocks already have it; foreign
  objects compare by identity — documented assumption).
- Wiring AgentMessageProvider to a store; FR-007 pins stubs.
- Compaction/summarization before truncation: spec 009's concern.
- The sealed hierarchy in types.dart: byte-identical (FR-006).

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: raw VM-format only; converter absent — corroboration only, never a gate
- Mutation: no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
