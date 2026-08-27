---
feature: 032-agent-session-root
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 9 # acceptance criteria AC US1-1..3, US2-1..3, US3-1..3 in spec.md
planned_at: 9d8b5bd
updated_at: 8b08456
suite_baseline: green # 597 passed, 0 failed (post 9d8b5bd analyze fix)
---

# Test List: AgentSession root entity — aggregate transitions + persistence contract

## Outer loop: acceptance behaviors

The feature is a pure value object with no user-visible surface of its own, so
the loop runs inside-out: acceptance behaviors are exercised through the root
entity's public API (transitions + serialization) — the entry point the engine
loop, the fork coordinator, and the persistence layer each consume.

| id  | behavior                                                                       | traces     | kind    | state   | test                                                              |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| A1  | appendEntry on a fresh session initialises the cursor and stamps updatedAt     | AC US1-1   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A2  | appendEntry on a headed session advances the cursor; isHead stays true         | AC US1-2   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A3  | appendEntry rejects an empty entry id with ArgumentError                       | AC US1-3   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A4  | fork links the child via parentSessionId with the cursor at the current head   | AC US2-1   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A5  | fork of a fresh session falls back to the root anchor as the fork point        | AC US2-2   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A6  | fork inherits the parent's missionId                                           | AC US2-3   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A7  | A fully-populated session round-trips JSON field-exactly                       | AC US3-1   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A8  | A minimal session serializes null optionals absent and restores them null      | AC US3-2   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| A9  | Malformed JSON (missing/ill-typed required key) throws ArgumentError           | AC US3-3   | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/agent_session/agent_session.dart` (transitions)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                              |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| U1  | appendEntry never mutates the source snapshot (cursor + updatedAt unchanged)   | FR-006     | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| U2  | fork never mutates the source session (still a non-branch, cursor unchanged)   | FR-006     | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| U3  | fork preserves rootEntryId — the branch grows inside the same entry tree       | FR-003     | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |

### `lib/src/domain/entities/agent_session/agent_session.dart` (persistence)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                              |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | ---------------------------------------------------------------- |
| U4  | fromJson restores UTC timestamps exactly (instant + zone preserved)            | FR-004     | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| U5  | fromJson rejects an ill-typed id (non-string) with ArgumentError naming it     | edge-4     | example | DONE    | `test/domain/entities/agent_session/agent_session_test.dart`     |
| U6  | The 8 pre-existing provider/compile-parity tests keep passing unchanged        | FR-001, FR-005 | BASELINE | BASELINE | `test/data/providers/agent_session/agent_session_provider_test.dart` |

## Invariants and edge cases still to place

- Immutability of transitions: covered as first-class unit behaviors (U1, U2) — the aggregate never mutates in place.
- Absent-never-fabricated serialization: covered by A8 (optionals) — the same discipline 031 established for ToolResult.

## Out of scope

- Wiring `AgentSessionProvider` to a real store: separate feature (FR-005 keeps the stubs).
- Tree-validity enforcement in `appendEntry` (entry ordering, parent/child consistency): the engine owns ordering — documented assumption, no test.
- Rewiring `jsonl_session_storage` / `hive_session_store` to the new JSON shape: their own specs.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test test/domain/entities/agent_session/agent_session_test.dart -n "<name>"`
- File: `dart test test/domain/entities/agent_session/agent_session_test.dart`
- Full suite: `dart test`
- Mutation (changed files): no tool wired — deliberate hand-mutants per the profile

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| updatedAt stamp | appendEntry keeps the old updatedAt | A1 |
| fork point | fork always uses rootEntryId (ignores current head) | A4 |
| branch link | toJson omits parentSessionId | A7 |
| parse guard | fromJson fabricates a default for a missing key instead of throwing | A9 |
