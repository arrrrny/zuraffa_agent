---
feature: 25-repetition_tracker-datasource-pair
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 7
planned_at: ccca224
updated_at: 25c0285
suite_baseline: green
---

# Test List: RepetitionTracker datasource + mock pair

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`. Each stays red until the feature works
end to end through its real entry point — the datasource public API (the surface
an engine or replacing backend would call).

| id  | behavior                                                                                  | traces    | kind    | state   | test                                                                                          |
| --- | ----------------------------------------------------------------------------------------- | --------- | ------- | ------- | --------------------------------------------------------------------------------------------- |
| A1  | Recording maxCalls-1 times keeps isLooping false and count tracks occurrences             | AC US1-1  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |
| A2  | The maxCalls-th in-window occurrence trips isLooping (inclusive threshold)                | AC US1-2  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |
| A3  | Two signatures loop independently — counts are keyed per signature, never shared          | AC US1-3  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |
| A4  | After the window passes, count is 0 and isLooping reverts to false                        | AC US2-1  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |
| A5  | Boundary: a record exactly window-old is expired; one strictly inside is alive            | AC US2-2  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |
| A6  | reset() zeroes all counts, clears every loop signal, preserves current() configuration    | AC US3-1  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |
| A7  | record() returns the post-record in-window count (single round-trip read-after-write)     | AC US3-2  | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`      |

## Inner loop: unit behaviors

Grouped by the component from `plan.md` that owns them. Each line names one
observable result.

### `lib/src/domain/entities/repetition_tracker/repetition_tracker.dart`

| id  | behavior                                                                  | traces           | kind    | state   | test                                                                        |
| --- | ------------------------------------------------------------------------- | ---------------- | ------- | ------- | --------------------------------------------------------------------------- |
| U1  | Value equality across id, maxCalls and window                             | FR-001, SC-004   | example | DONE    | `test/domain/entities/repetition_tracker/repetition_tracker_test.dart`     |
| U2  | Equal instances have equal hashCodes                                      | FR-001, SC-004   | example | DONE    | `test/domain/entities/repetition_tracker/repetition_tracker_test.dart`     |
| U3  | Differing id, maxCalls or window makes instances unequal                  | FR-001, SC-004   | example | DONE    | `test/domain/entities/repetition_tracker/repetition_tracker_test.dart`     |
| U4  | isRepetition is false at maxCalls-1 and true at maxCalls                  | FR-002, SC-001   | example | DONE    | `test/domain/entities/repetition_tracker/repetition_tracker_test.dart`     |
| U5  | Defaults: maxCalls=5 and window=60s when omitted                          | FR-008           | example | DONE    | `test/domain/entities/repetition_tracker/repetition_tracker_test.dart`     |
| U6  | Constructor rejects maxCalls < 1                                          | FR edge-1        | example | DONE    | `test/domain/entities/repetition_tracker/repetition_tracker_test.dart`     |

### `lib/src/data/datasources/repetition_tracker/` (interface + mock)

| id  | behavior                                                                  | traces           | kind    | state   | test                                                                        |
| --- | ------------------------------------------------------------------------- | ---------------- | ------- | ------- | --------------------------------------------------------------------------- |
| U7  | Mock implements the datasource interface (compile parity, issues #25/#26) | FR-003           | example | BASELINE | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` |
| U8  | Injectable clock drives evaluation when no explicit now is passed         | FR-004           | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` |
| U9  | isLooping equals current().isRepetition(count) for every signature        | FR-006           | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` |
| U10 | record with an explicit at-timestamp is respected for window pruning      | FR-004           | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` |
| U11 | A late record older than the window is pruned on first evaluation         | edge-2           | example | DONE    | `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` |

## Invariants and edge cases still to place

- The loop signal must never be sticky: it is always derived from the live
  window count (FR-006) — covered by A4 (signal reverts after expiry) and U9.
- Pruning happens on BOTH the write path (record) and the read path
  (count/isLooping) — covered by U10/U11 (write path) and A4/A5 (read path).

## Out of scope

- A Hive- or remote-backed datasource implementation: interface contract only;
  the mock is the reference implementation (spec Assumptions).
- ToolCallSignature integration (producing the signature string): spec 29 owns
  the key format; this pair consumes an opaque String.
- LLM-call repetition beyond the shared signature mechanism: same record()
  path, no distinct behavior.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time, so this
file is readable on its own:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: not configured (see profile — corroboration only, never a gate)
- Mutation (changed files): no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4 (one small change, run the behavior's test,
  expect failure, restore exactly, re-run suite)
