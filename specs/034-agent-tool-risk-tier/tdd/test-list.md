---
feature: 034-agent-tool-risk-tier
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 9 # acceptance criteria AC US1-1..3, US2-1..3, US3-1..3 in spec.md
planned_at: 34b47f8
updated_at: 22a4d7b
suite_baseline: green # 626 passed, 0 failed (post spec-033)
---

# Test List: AgentTool entity + RiskTier enum — classification, registry persistence, hash contract

## Outer loop: acceptance behaviors

The feature is a pure value-object layer with no user-visible surface of its
own, so the loop runs inside-out: acceptance behaviors are exercised through
the declaration value object's public API (parsers, serialization, hashing)
— the entry points the registry and the dispatch/approval layer consume.

| id  | behavior                                                                       | traces     | kind    | state   | test                                                          |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | -------------------------------------------------------------- |
| A1  | Equal tools with distinct-but-equal paramsSchema instances share hashCode      | AC US3-1   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A2  | Equal schemas built in different insertion orders hash equally                 | AC US3-2   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A3  | Tools differing on any of the five fields are unequal                          | AC US3-3   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A4  | RiskTier.fromString parses safe/confirm/admin exactly and round-trips via name | AC US1-1   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A5  | RiskTier.fromString rejects unknown strings (incl. case mismatches) typed      | AC US1-2   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A6  | Each tier's dispatch policy reads correctly (confirm pauses, admin gates)      | AC US1-3   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A7  | A fully-declared tool round-trips JSON with tier, mode and deep schema         | AC US2-1   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A8  | A schema-less tool serializes paramsSchema absent                              | AC US2-2   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| A9  | Malformed declaration JSON throws ArgumentError naming the field               | AC US2-3   | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them.

### `lib/src/domain/entities/agent_tool/agent_tool.dart` (enums)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                          |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | -------------------------------------------------------------- |
| U1  | ExecutionMode.fromString parses sequential/parallel; unknown rejects typed     | FR-003     | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| U2  | fromString's ArgumentError carries the offending input as its value            | FR-002     | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |

### `lib/src/domain/entities/agent_tool/agent_tool.dart` (hash fold)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                          |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | -------------------------------------------------------------- |
| U3  | The hash fold recurses into nested maps (a one-level fold would re-violate)    | FR-006     | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| U4  | Schema array order matters for equality/hashing (required lists are ordered)   | FR-006     | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |

### `lib/src/domain/entities/agent_tool/agent_tool.dart` (persistence)

| id  | behavior                                                                       | traces     | kind    | state   | test                                                          |
| --- | ------------------------------------------------------------------------------ | ---------- | ------- | ------- | -------------------------------------------------------------- |
| U5  | fromJson routes tier/mode through fromString — unknown tier in JSON fails like a declaration | FR-004 | example | DONE    | `test/domain/entities/agent_tool/agent_tool_test.dart`        |
| U6  | The 10 pre-existing provider/compile-parity tests keep passing unchanged       | FR-001, FR-005, FR-007 | BASELINE | BASELINE | `test/data/providers/agent_tool/agent_tool_provider_test.dart` |

## Invariants and edge cases still to place

- The `==`/`hashCode` contract: A1 is the LIVE red (probe-verified: equal pair hashed 518580394 vs 128524753 on the scaffold); A2/U3 pin the fold's order-independence and depth.
- Absent-never-fabricated serialization: A8 — the house discipline from 031/032/033.
- Under-classification safety: A5/U2 — an unknown tier never becomes a silent `safe`.

## Out of scope

- Datasource interface + mock datasource pair: belongs to the datasource-pair spec family (025/027/029 precedent); the repo's spec.md pins the provider-stub contract (FR-007).
- Wiring `AgentToolProvider` to a real registry store: separate feature.
- Dispatch-time params validation against `paramsSchema` (R3.1): the dispatcher's spec; the declaration ships the schema.
- Approval-callback wiring for `confirm` tools: downstream feature building on this surface.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test test/domain/entities/agent_tool/agent_tool_test.dart -n "<name>"` (mind regex-special characters — 033 cycle-log lesson)
- File: `dart test test/domain/entities/agent_tool/agent_tool_test.dart`
- Full suite: `dart test`
- Mutation (changed files): no tool wired — deliberate hand-mutants per the profile

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| identity hash | hashCode passes the schema Map through Object.hash (the scaffold's bug) | A1 |
| nested fold | fold stops at depth 1 (nested maps hashed by identity) | U3 |
| parse guard | fromString silently returns safe on unknown input | A5 |
| round-trip guard | fromJson ignores an unknown tier string and defaults to safe | A9/U5 |
