# Cycle Log: Playbook-as-spec behavior steering (R5#4)

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 1163 passed, 2 skipped, 0 failed (2026-08-29,
  pre-feature, ~49s)
- analyze: `dart analyze --fatal-infos` -> 3 issues, all pre-existing in files
  this feature does not touch (warning
  `test/engine/mission_runner_002_a2_test.dart:91` unused field `_count`; info
  `lib/src/eval/cassette_replay_llm_client.dart:68` prefer_final_fields; info
  `test/engine/mission_runner_002_a3_test.dart:122`
  prefer_function_declarations_over_variables)
- commit: `9d0b341`
- recorded: cycle 0, before any spec-104 change

## Cycle 1 — U1/U2/U9 schema construction, equality, toString (FR-001)

Honest granularity: one cycle per FR group, per-behavior single-test reds
recorded individually (036 precedent).

- test: `test/domain/entities/playbook/playbook_test.dart` (group
  `spec 104 — Playbook schema`, 3 tests)
- red: first run was the compile error the playbook demands for a new Dart
  symbol (`Error: Type 'Playbook' not found`), then a minimal stub (types
  declared, constructor/`==`/`toString` inert) drove the real reds:
  - U1 `dart test test/domain/entities/playbook/playbook_test.dart --plain-name "U1: construction preserves every field"`
    -> `UnimplementedError` / `Some tests failed.`
  - U2 `--plain-name "U2: value equality spans every field"`
    -> `UnimplementedError` / `Some tests failed.`
  - U9 `--plain-name "U9: toString names the type and identity"`
    -> `UnimplementedError` / `Some tests failed.`
- green: full value object (fields, unmodifiable steering copy, `==`/
  `hashCode` across all fields incl. sub-values, house-style `toString`).
  One iteration in between: a broken `_listEq` scope (compile error) was
  fixed by hoisting it to a top-level helper — a green-phase correction,
  not a red. Suite `dart test` -> 1166 passed, 2 skipped (+3).
  `dart analyze --fatal-infos` on the changed files -> No issues found.
- refactor: the `_listEq` hoist WAS the refactor; suite re-run green.
- commit: `6970007`

## Cycle 2 — U3/U4 identity + steering validation (FR-001/FR-002)

- test: same file, group `spec 104 — Playbook schema validation` (2 tests)
- red:
  - U3 `--plain-name "U3: blank identity fields are rejected"`
    -> `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'id'`
       / `Actual: <Closure: () => Playbook>` -> `Some tests failed.`
  - U4 `--plain-name "U4: blank steering content is rejected"`
    -> `Expected: throws ... contains 'content'` / `Actual: <Closure: () => Playbook>`
- green: constructor validation on identity fields (incl. blank-when-present
  `domain`/`country`) and steering entry content; `ArgumentError.value`
  naming each field. Suite -> 1168 passed (+2). Analyze -> No issues.
- refactor: none — mirrors the SubAgentSpec body-check pattern (036).
- commit: `012027d`

## Cycle 3 — U5/U6/U7/U8 gate + response validation (FR-001/FR-002)

- test: same file (4 tests, each covering both sides of its boundary)
- red:
  - U5 `--plain-name "U5: blank tool ids in a gate list are rejected"`
    -> `Expected: throws ... contains 'allowed'` / `Actual: <Closure: () => Playbook>`
  - U6 `--plain-name "U6: non-empty irrelevant gate lists are rejected"`
    -> `Expected: throws ... contains 'blocked'` / `Actual: <Closure: () => Playbook>`
  - U8 `--plain-name "U8: response constraint boundaries (maxChars 0/1, blank language)"`
    -> `Expected: throws ... contains 'maxChars'` / `Actual: <Closure: () => Playbook>`
  - U7 `--plain-name "U7: legal gate boundaries construct (lock-down, empty, off)"`
    -> PASSED on first run — expected: the legal boundary already constructs
    (U7 is the boundary pin against U6's rule over-reaching). Deliberate
    mutant applied (reject empty `allowed` on an allowlist gate): U7 failed
    with `threw ArgumentError:<Invalid argument (allowed): MUTANT: empty
    allowlist rejected>`; code restored exactly; whole file re-run green.
- green: blank-free gate lists, mode/list consistency (incl. off), positive
  `maxChars`, non-empty `language`. One legitimate test-fixture adjustment:
  U2's blocklist-mutant kept the reference's non-empty `allowed` list, which
  U6's new rule rejects — the fixture was legalized (blocklist with empty
  `allowed` + non-empty `blocked`); U2's equality semantics unchanged.
  Suite -> 1172 passed (+4). Analyze -> No issues.
- refactor: none.
- commit: `41f859c`

## Cycle 4 — U10/U11/U16 loader happy paths (FR-002)

- test: `test/domain/entities/playbook/playbook_loader_test.dart` (group
  `spec 104 — PlaybookLoader::loads`, 3 tests)
- red: minimal stub loader (`loadYaml`/`loadJson` throw):
  - U10 `--plain-name "U10: full YAML document preserves every field"`
    -> `UnimplementedError` / `Some tests failed.`
  - U11 `--plain-name "U11: JSON path equals YAML path; unknown keys ignored"`
    -> `UnimplementedError`
  - U16 `--plain-name "U16: identity-only document loads as the no-op playbook"`
    -> `UnimplementedError`
- green: loader implemented — and OVER-reached: the full FR-002 diagnostic
  matrix (U12-U17 territory) was written speculatively in the same change.
  Per Hard Rule 2 (no implementation before its failing test) the
  diagnostics were REVERTED to a minimal cast-based loader in `0986295`
  (cycle-4 tests stayed green through the revert; 12/12). Suite after
  cycle 4 -> 1175 passed (+3). Analyze -> No issues.
- refactor: the speculative-validation revert (0986295) — recorded as a
  process correction, not a refactor.
- commits: `eac91c9` (behavior), `0986295` (Hard-Rule-2 correction)

## Cycle 5 — U12/U13 loader identity + steering diagnostics (FR-002)

- test: same file, group `spec 104 — PlaybookLoader::rejects` (2 tests)
- red (against the minimal loader):
  - U12 `--plain-name "U12: non-map top level and bad identity are rejected"`
    -> `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'document'`
       / `Actual: <Closure: () => Playbook>` / `which is not an instance of 'ArgumentError'`
       (the minimal loader threw the cast TypeError instead)
  - U13 `--plain-name "U13: malformed steering section is rejected"`
    -> same shape, naming `steering`
- green: document-shape diagnostics for identity (non-map top level names
  `document`; missing/wrong-typed identity names the key) and steering
  (non-list names `steering`; non-map entry names `steering`; missing/blank
  content names `content`). U13's blank-content case passes via the
  aggregate constructor — pinned end-to-end (cycle 2's U4 red proved that
  rule). Suite -> 1177 passed (+2). Analyze -> No issues.
- refactor: none.
- commit: `dbcc33e`

## Cycle 6 — U14/U15/U17 loader gate + response diagnostics (FR-002)

- test: same file (3 tests)
- red (against the minimal `_gate`/`_response`):
  - U14 `--plain-name "U14: malformed toolGating section is rejected"`
    -> `Expected: throws ... contains 'mode'` / `Actual: <Closure: () => Playbook>`
    (`PlaybookGateMode.values.byName` threw an ArgumentError with no `.name`)
  - U15 `--plain-name "U15: malformed response section is rejected"`
    -> `Expected: throws ... contains 'maxChars'` / `Actual: <Closure: () => Playbook>`
  - U17 `--plain-name "U17: inconsistent gate documents are rejected at load"`
    -> PASSED on first run — expected: mode/list inconsistency is validated
    by the aggregate constructor (cycle 3's U6 red proved that rule); U17
    pins it end-to-end through the document path. Deliberate mutant applied
    (dropped the allowlist/blocked rule from the aggregate): U17 failed with
    `Expected: throws ... contains 'blocked'` / `Actual: <Closure: () => Playbook>`;
    restored exactly.
- green: `_gate`/`_response` diagnostics (closed mode vocabulary naming
  `mode`; non-list/non-string/blank gate lists naming the list; non-int or
  non-positive `maxChars` naming `maxChars`; bad `language` naming
  `language`). Suite -> 1180 passed (+3). Analyze -> No issues. Outer loop
  [A1] and [A2] close here: every loader path (happy + malformed matrix) is
  pinned.
- refactor: none.
- commit: `420b5c9`

## Cycle 7 — outer loop opens: A3/A4/A5/A6 staged red (FR-003..FR-006)

- test: `test/engine/playbook_runtime_test.dart` (group
  `spec 104 — R5#4 acceptance`, 4 tests) written against a minimal
  `lib/src/engine/playbook_runtime.dart` stub whose methods throw
  `UnimplementedError` (the compile-symbols-only stub; the language
  requires the types to exist before the tests can run — playbook Step 3).
  One compile fix during staging: `ToolCall` requires `executionMode`
  (house constructor), added to the fixtures — a test fixture fix before
  any red, not after.
- red (single-test runs, verbatim):
  - A3 `--plain-name "A3: playbook steering drains through the mission loop"`
    -> `UnimplementedError` / `Some tests failed.`
  - A4 `--plain-name "A4: playbook tool gating refuses the blocked tool in a mission"`
    -> `UnimplementedError` / `Some tests failed.`
  - A5 `--plain-name "A5: response constraints shape the mission response"`
    -> `UnimplementedError` / `Some tests failed.`
  - A6 `--plain-name "A6: three documents, one code path — behavior follows the document (R5#4)"`
    -> `UnimplementedError` / `Some tests failed.`
- green: NOT yet — the outer loop stays red while the inner-loop units
  (U18–U30) are built (double-loop playbook: the acceptance red is expected
  and is not a failure of the loop). Because every commit must leave the
  suite green, the staged acceptance file is parked outside the tree
  (`/tmp/staged_acceptance_playbook_runtime_test.dart`) while cycles 8–12
  run; it returns unchanged at the outer close (cycle 13). No commit for
  this cycle — the stub lands with cycle 8's first green.

## Cycle 8 — U18/U19/U20 steeringMessages (FR-003/FR-005)

- test: `test/engine/playbook_runtime_test.dart` (group
  `spec 104 — PlaybookRuntime steering`, 3 tests) against the
  compile-symbols stub from cycle 7
- red:
  - U18 `--plain-name "U18: entries become steering messages in document order"`
    -> `UnimplementedError` / `Some tests failed.`
  - U19 `--plain-name "U19: language constraint appends the pinned directive message"`
    -> `UnimplementedError`
  - U20 `--plain-name "U20: empty steering yields no messages"`
    -> `UnimplementedError`
- green: `steeringMessages()` — entries in document order (content verbatim,
  derived id `pb-<playbookId>-steer-<index>`, entry id override), plus the
  pinned language directive appended. One test-fixture correction during
  green: the fixture playbook id `pb-x` made the documented
  `pb-<playbookId>-...` format read as a double prefix (`pb-pb-x-steer-1`)
  — per the playbook's "the specification decides" rule the FIXTURE was
  wrong (spec/plan/test-list all pin `pb-<playbookId>-steer-<i>`); fixture
  id changed to `de-001`. Process correction: the initial commit was made
  before the fixture fix (an accidental red commit); amended pre-push to
  the green state — recorded here as the deviation it was. Suite -> 1183
  passed (+3). Analyze -> No issues.
- refactor: none.
- commit: `2772fa9` (amended)

## Cycle 9 — U21/U22 seedSteering (FR-003/FR-007)

- test: same file (2 tests)
- red:
  - U21 `--plain-name "U21: seedSteering returns a new FIFO-seeded queue"`
    -> `UnimplementedError` / `Some tests failed.`
  - U22 `--plain-name "U22: seeding nothing is a no-op"`
    -> `UnimplementedError`
- green: `seedSteering` folds `queue.enqueue` over `steeringMessages()` —
  FIFO after pre-existing pending, input unmutated, processedCount
  preserved; no-op returns the queue unchanged. Suite -> 1185 (+2).
  Analyze -> No issues.
- refactor: none — pure value composition.
- commit: `91c8360`

## Cycle 10 — U23/U24/U25 tool gate: off + allowlist (FR-004)

- test: same file, group `spec 104 — PlaybookRuntime tool gate` (3 tests),
  with the 069-exemplar `FakeToolDispatcher` appended to the file
- red:
  - U23 `--plain-name "U23: off gate delegates everything"`
    -> `UnimplementedError` / `Some tests failed.`
  - U24 `--plain-name "U24: allowlist gate refuses unlisted tools"`
    -> `UnimplementedError`
  - U25 `--plain-name "U25: empty allowlist locks down all tools"`
    -> `UnimplementedError`
- green: `PlaybookToolGateDispatcher` (070 `AllowlistToolDispatcher`
  contract: typed `tool not allowed: <name>` refusal, inner never invoked;
  allowlist/off semantics; batch delegates per call; schema/risk delegate)
  + `PlaybookRuntime.gateDispatcher()`. Suite -> 1188 (+3). Analyze -> No
  issues.
- refactor: none — mirrors the 070 decorator.
- commit: `b94be29`

## Cycle 11 — U26/U27 blocklist + batch/delegation pins (FR-004)

- test: same file (2 tests, plus the `DelegationSpy` fake for U27's
  delegation counts)
- red: none — both PASSED on first run: cycle 10's green implemented the
  exhaustive mode switch (Dart requires all three enum cases) and the full
  `ToolDispatcher` interface, which carried blocklist and batch/delegation
  behavior with it. Per the playbook's pass-first rule, deliberate mutants
  prove both pins can fail:
  - U26 mutant (blocklist refuses nothing): U26 failed
    `Expected: false / Actual: <true>` — killed; restored.
  - U27 mutant (dispatchBatch bypasses the gate, calls `_inner` directly):
    U27 failed `Expected: [true, false, true] / Actual: [true, true, true]`
    — killed; restored.
  Restore verified: whole file 10/10 green.
- green: already green (no implementation change this cycle — pins only).
  Suite -> 1190 (+2). Analyze -> No issues.
- commit: `845e2de`

## Cycle 12 — U28/U29/U30 response constraints + clock pin (FR-005)

- test: same file, group `spec 104 — PlaybookRuntime response` (3 tests)
- red: one broken-test compile error first (helper return type `Playbook`
  instead of `PlaybookRuntime` — test fixed before any red, per playbook
  Step 3's broken-test row), then the real reds:
  - U28 `--plain-name "U28: maxChars truncation boundaries"`
    -> `UnimplementedError` / `Some tests failed.`
  - U29 `--plain-name "U29: no constraints means no change"`
    -> `UnimplementedError`
  - U30 `--plain-name "U30: steering timestamps come from the injected clock"`
    -> PASSED on first run — expected: clock-reading landed with cycle 8's
    `steeringMessages`. Deliberate mutant (clock captured once at
    construction instead of read per call): U30 failed — killed; restored.
- green: `constrainResponse` — null/at-limit pass-through, over-limit
  truncated to exactly the first `maxChars` characters + the pinned
  playbook-attributed marker. Suite -> 1193 (+3). Analyze -> No issues.
- refactor: none.
- commit: `6cf2472`

## Cycle 13 — outer loop closes: A3/A4/A5/A6 green (FR-003..FR-006)

- test: the staged acceptance group (cycle 7, red before ANY runtime
  implementation existed) restored unchanged into
  `test/engine/playbook_runtime_test.dart` (mission fakes + the three
  playbook documents + the single `runUnderPlaybook` composition merged
  around the unit groups).
- red: none at this cycle — the reds were staged and recorded at cycle 7
  (UnimplementedError x4, verbatim above). This cycle is the close.
- green: all four acceptance tests pass with zero further implementation —
  the units built in cycles 8-12 close them:
  - A3 (steering drains through a real `MissionRunner` mission) — green
  - A4 (gating observable in a mission: `ToolCallCompleted(ok: false)`,
    typed error in the transcript, inner dispatcher untouched) — green
  - A5 (language directive injected + 500-char response capped at 120) —
    green
  - A6 (Germany/Japan/France through the IDENTICAL code path: per-document
    steering, opposite tool refusals, per-document caps) — green. This is
    the R5#4 acceptance: three documents, one code path, behavior follows
    the document, zero code change.
  Suite `dart test` -> 1197 passed, 2 skipped (+34 over baseline 1163).
  Analyze `--fatal-infos` on all changed files -> No issues.
- refactor: none.
- commit: `ff0fc90`

## Remediation cycles — T019 (red-first evidence for U17/U26/U27/U30)

From the audit at `ff0fc90` (verification.md verdict FAIL, finding 1): the
four pass-first pins get genuine red-first evidence — behavior reverted,
existing test observed failing (verbatim red), behavior restored exactly,
green re-verified. The write-order history cannot change; the red evidence
can.

- U17: allowlist/blocked inconsistency rule removed from the aggregate ->
  `dart test ... --plain-name "U17: inconsistent gate documents are rejected at load"`
  -> `Expected: throws <Instance of 'ArgumentError'> with `name`: contains 'blocked'`
     / `Actual: <Closure: () => Playbook>` -> restored -> `All tests passed.`
- U26: blocklist case returns false (refuses nothing) ->
  `--plain-name "U26: blocklist gate refuses only listed tools"`
  -> `Expected: false` / `Actual: <true>` -> restored -> green.
- U27: `dispatchBatch` bypasses the gate (calls `_inner` directly) ->
  `--plain-name "U27: batch dispatch gates per call; schema/risk delegate"`
  -> `Expected: [true, false, true]` / `Actual: [true, true, true]`
  -> restored -> green.
- U30: clock captured once at construction (compiling revert) ->
  `--plain-name "U30: steering timestamps come from the injected clock"`
  -> `Expected: DateTime:<2026-01-02 00:00:00.000Z>` / `Actual: DateTime:<2026-01-01 00:00:00.000Z>`
  -> restored -> green. (A first attempt with a non-compiling revert was
  discarded — a loading error is not a red; redone with a compiling one.)
- Full file 17/17 green after all restores; full suite 1197 passed / 2
  skipped.

## Remediation — T020 (at-limit boundary pinned at acceptance level)

A5 extended: a mission whose final response is exactly `maxChars` (120)
characters passes through unconstrained. Pass-first expected (the boundary
behavior exists; the PIN was missing — finding 2). Mutant check: the
off-by-one `<=`->`<` mutant now fails A5 (`Some tests failed.`) — killed at
the acceptance level as well as U28's unit level. Restored; file green.
