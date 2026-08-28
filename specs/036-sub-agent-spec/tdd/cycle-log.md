# Cycle Log: SubAgentSpec value object (validation + pinned semantics)

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 695 passed, 0 failed (2026-08-27, pre-feature)
- analyze: `dart analyze` -> 5 issues (all pre-existing: 4 x
  unnecessary_non_null_assertion in test/domain/entities/golden_mission_test.dart,
  1 x depend_on_referenced_packages in lib/src/artifact/in_memory_artifact_store.dart)
- commit: `7da6902`
- recorded: cycle 0, before any spec-036 change

## Cycle 1 — U1/U2/U3 identity validation (FR-001)

Honest granularity: one cycle per FR group, with per-behavior single-test reds
recorded individually (031 precedent — the reds here are assertion failures, so
they COULD have been staged one commit at a time; grouped deliberately, each
red line captured verbatim below).

- test: `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart`
  (group `spec 036 — SubAgentSpec identity validation (FR-001)`, 4 tests:
  U1/U2/U3 reds + the non-empty boundary pin)
- red (single-test runs, verbatim decisive lines):
  - U1 `dart test ... --plain-name "U1: empty name"` ->
    `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'name'`
    / `Actual: <Closure: () => SubAgentSpec>` -> `Some tests failed.`
  - U2 `dart test ... --plain-name "U2: empty description"` ->
    `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'description'`
    / `Actual: <Closure: () => SubAgentSpec>` -> `Some tests failed.`
  - U3 `dart test ... --plain-name "U3: empty systemPrompt"` ->
    `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'systemPrompt'`
    / `Actual: <Closure: () => SubAgentSpec>` -> `Some tests failed.`
- green: constructor validation on `name`/`description`/`systemPrompt`
  (`ArgumentError.value(v, field, 'must not be empty')`); constructor became
  non-const (no const call sites existed — analyzer verified). Full suite ->
  699 passed, 0 failed (+4). `dart analyze` -> 5 issues, unchanged baseline.
- refactor: none — validation mirrors the UiTreePayload body-check pattern.
- commit: `1eb07a2`

## Cycle 2 — U4/U5 allowlist validation (FR-002)

- test: same file, group `spec 036 — SubAgentSpec allowlist validation (FR-002)`
  (3 tests: U4, U5, boundary pin)
- red:
  - U4 `--plain-name "U4: blank tool id"` ->
    `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'tools'`
    / `Actual: <Closure: () => SubAgentSpec>` -> `Some tests failed.`
  - U5 `--plain-name "U5: blank sub-agent name"` ->
    `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'subAgents'`
    / `Actual: <Closure: () => SubAgentSpec>` -> `Some tests failed.`
- green: `tools.any((id) => id.isEmpty)` / `subAgents.any(...)` checks added.
  Suite -> 702 passed (+3). `dart analyze` -> 5 issues, unchanged.
- refactor: none.
- commit: `9391515`

## Cycle 3 — U6/U7/U8 budget validation (FR-003)

- test: same file, group `spec 036 — SubAgentSpec budget validation (FR-003)`
  (3 tests, each asserting both sides of its boundary)
- red:
  - U6 `--plain-name "U6: maxTurns 0"` ->
    `Expected: throws ... contains 'maxTurns'` / `Actual: <Closure: () => SubAgentSpec>`
  - U7 `--plain-name "U7: contextWindowTokens 0"` ->
    `Expected: throws ... contains 'contextWindowTokens'` / `Actual: <Closure: () => SubAgentSpec>`
  - U8 `--plain-name "U8: negative wallClockTimeout"` ->
    `Expected: throws ... contains 'wallClockTimeout'` / `Actual: <Closure: () => SubAgentSpec>`
- green: `< 1` checks on maxTurns/contextWindowTokens (null-aware), negative
  check on wallClockTimeout; Duration.zero and null pinned valid. Suite ->
  705 passed (+3). `dart analyze` -> 5 issues, unchanged.
- refactor: none.
- commit: `d6062c0`

## Cycle 4 — U9 self-extends 1-cycle (FR-004)

- test: same file, group `spec 036 — SubAgentSpec inheritance 1-cycle check (FR-004)`
- red: `--plain-name "U9: extendsSpec == name"` ->
  `Expected: throws ... contains 'extendsSpec'` /
  `Actual: <Closure: () => SubAgentSpec>` -> `Some tests failed.`
- green: `extendsSpec == name` check added; distinct-parent boundary pinned.
  Suite -> 707 passed (+2). `dart analyze` -> 5 issues, unchanged.
- refactor: none.
- commit: `953a0cd`

## Cycle 5 — U10/U12 characterization pins (FR-005/FR-006)

Brownfield pins, expected pass-first; strength proven by deliberate mutants.

- test: same file, group `spec 036 — characterization pins` (2 tests: four
  canonical shapes incl. the previously-untested child+branch; equality with
  non-const independently built lists, distinct-instance precondition asserted)
- pass-first: both pins green immediately (shipped behavior) — per playbook
  brownfield path, mutants applied next.
- mutants (each applied alone, run, restored exactly, suite re-run green):
  - MUTANT-A `isRoot => extendsSpec != null` (inverted) -> U10 pin:
    `Expected: true` / `Actual: <false>` -> KILLED. Restore verified
    (`git diff --stat lib/` empty).
  - MUTANT-B `_listEq(tools, other.tools)` -> `identical(tools, other.tools)`
    -> U12 pin: equality failure (Expected/Actual SubAgentSpec pair) -> KILLED.
    First application attempt appended a comment that swallowed the `&&` —
    compile error, INVALID red, discarded and re-applied cleanly before this
    evidence was recorded.
- incident: during MUTANT-A restore a blanket `git stash` briefly stashed the
  uncommitted pin tests; recovered via `git stash pop`, verified by re-grepping
  the test file and re-running (14/14 green). Same failure class as 031's
  "lost implementation" incident; later restores used file-scoped
  `git checkout -- <file>` only.
- green: suite stays 707 passed (pins +2, mutants restored). `dart analyze`
  unchanged.
- commit: `ca10fd6`

## Notes and deviations

- Suite arithmetic: 695 (baseline) + 4 + 3 + 3 + 2 + 2 = 709 expected at final
  gate; intermediate counts recorded per cycle above reflect +4/+3/+3/+2 pins
  landing with their cycles (the last +2 pins are the cycle-5 tests).
- One cycle per FR group with per-behavior reds recorded individually —
  honest granularity (assertion-level reds, individually runnable via
  --plain-name, as captured above).
- U11/U13/U14 credit pre-existing provider-suite coverage (11 tests) — no new
  tests written for them; verified green in every full-suite run.
