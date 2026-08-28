# Cycle Log: AgentMessage (multimodal parts) + history

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 727 passed, 0 failed (2026-08-27, post-spec-038)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged list)
- commit: `27e62e4`
- recorded: cycle 0, before any spec-041 change

## Cycle 1 — U1/U2/U3 entity validation + parts value equality (FR-001/002)

- test: `test/domain/entities/agent_message/agent_message_test.dart`
  (2 groups, 6 tests)
- red (single-test runs, verbatim decisive lines):
  - U1 id `--plain-name "U1: empty id"` ->
    `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'id'`
    / `Actual: <Closure: () => AgentMessage>`
  - U1 role `--plain-name "U1: empty role"` -> same shape, `contains 'role'`
  - U2 `--plain-name "U2: distinct-instance"` -> equality FAILURE on two
    field-identical messages (the shipped bug observed live):
    `Expected: AgentMessage:<AgentMessage(id: id-a, role: assistant, ...)>` /
    `Actual: AgentMessage:<...same rendering...>` — unequal despite identical
    fields because the shipped `parts == other.parts` is List identity.
- green, three increments (each driven by a red):
  1. constructor validation (id/role non-empty) + `_partsEq` element-wise
     comparison -> U2 single-part test green;
  2. the multi-part test (map part) exposed `Map ==` is identity too ->
     `_deepEq` deep Map/List walk added (UiTreePayload._deepEq discipline),
     spec edge-case amended in the same commit (drift remediation);
  3. `hashCode` contract test then caught equal messages hashing differently
     (`Expected: <372114693> / Actual: <65029858>`) — `Object.hashAll` uses
     identity-based map hashCodes -> `_deepHash` added (content-consistent
     hash: sorted-key fold for maps, deep hashAll for lists).
  Suite -> 733 green (`All tests passed!`); analyze 5 pre-existing.
- refactor: none.
- commit: `8e3faee`

## Cycle 2 — U4/U5/U6 truncate (FR-004) + U7/U8 pins (FR-003/005)

- test: `test/llm/agent_message_history_041_test.dart` (new file so spec-010's
  history test stays byte-identical; 7 tests: 5 truncate + 2 pins)
- red: compile error —
  `Error: The method 'truncate' isn't defined for the type 'AgentMessageHistory'.`
- green: `truncate(keep)` — negative throws ArgumentError; 0 -> empty active
  window; keep >= length -> content-equal copy; else `sublist(length - keep)`
  (LAST keep, oldest evicted); episodicMemories ride along every path.
  Pins (appendMessages/addMemory) passed on first run as expected —
  characterization, mutants below prove their strength.
  Suite -> 740 green; analyze 5 pre-existing.
- refactor: none.
- commit: `8b11a86`

## Verification experiments (verify-phase mutants, before verification.md)

All applied alone, run, restored exactly (`git diff --stat lib/` = 0), files
re-run green (13/13 across both suites) after each.

- M1 `if (id.isEmpty)` -> `if (false)` -> U1 id test:
  `Expected: throws ... contains 'id' / Actual: <Closure: () => AgentMessage>`
  -> KILLED.
- M2 truncate keeps FIRST N (`sublist(0, keep)`) -> U4:
  `Expected: 'second' / Actual: 'first'` -> KILLED.
- M3 truncate drops memories (`episodicMemories: const []` on the sublist
  path) -> U4: `Expected: an object with length of <1> / Actual: []` ->
  KILLED.

## Notes and deviations

- Suite arithmetic: 727 (baseline) + 6 + 7 = 740.
- U9/U10 credit pre-existing coverage: `test/types_test.dart` (sealed
  hierarchy role/part dispatch — untouched, green throughout) and the 5-test
  provider suite (byte-identical to `27e62e4`).
- The shipped-equality bug fix is behavior-changing BY DESIGN (FR-002); the
  2 pre-existing equality tests pass unchanged because their const list
  literals canonicalize to identical instances — the new tests cover the
  distinct-instance case the old ones could not see.
