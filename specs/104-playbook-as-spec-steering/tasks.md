# Tasks: Playbook-as-spec behavior steering (R5#4)

**Input**: Design documents from `/specs/104-playbook-as-spec-steering/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required) — both present.

**Tests**: The TDD extension drives this feature: every behavior on
`tdd/test-list.md` (A1–A7, U1–U30) gets a test observed failing before its
implementation (`/speckit.tdd.plan` has made the test tasks below **mandatory**
and ordered before the implementation tasks; behavior ids in brackets are the
load-bearing link `/speckit.tdd.run` ticks against).

**Organization**: Tasks are grouped by user story (US1..US5 from spec.md) so
each story is independently implementable and testable; US1 is the
foundational schema everything else consumes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1..US5)

## Path Conventions

- Single project: `lib/src/...` sources, `test/...` mirrored tests
  (house layout; see plan.md Project Structure).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Feature scaffolding the pipeline creates.

- [x] T001 Create `specs/104-playbook-as-spec-steering/` with spec.md seeded
  from issue #104 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, this tasks.md scaffold

---

## Phase 2: Foundational — US1 Playbook schema + loader (Priority: P1) 🎯 blocks all stories

**Goal**: The playbook-as-spec schema as a typed value object, loadable from
YAML/JSON with actionable diagnostics.

**Independent Test**: a valid document loads with every field preserved;
every malformed variant is rejected naming the offending field.

### Tests for US1 (written FIRST, observed failing)

- [x] T003 [P] [US1] Test `test/domain/entities/playbook/playbook_test.dart`
  — schema value object behaviors: [U1] construction preserves all fields
  (incl. duplicate steering entries, verbatim, in order), [U2] value equality
  across all fields (identity, steering order, gate, response), [U3] blank
  identity fields rejected, [U4] blank steering content rejected, [U5] blank
  tool ids rejected, [U6] non-empty irrelevant gate lists rejected (on
  allowlist/blocklist/off gates), [U7] legal gate boundaries construct
  (lock-down allowlist, empty blocklist, off with empty lists), [U8]
  `maxChars < 1` rejected / `maxChars == 1` legal / blank language rejected /
  both-null legal, [U9] toString pin.
- [x] T004 [P] [US1] Test
  `test/domain/entities/playbook/playbook_loader_test.dart` — loader
  behaviors: [U10] full YAML document preserves every field (round-trip
  identity, steering order and duplicates, gate lists, response constraints,
  optional domain/country metadata), [U11] JSON path equals the YAML path +
  unknown top-level keys ignored, [U12] missing identity / wrong-typed
  identity / non-map top level rejected naming the key, [U13] malformed
  steering section rejected (non-list, non-map entry, missing/blank
  content), [U14] malformed toolGating rejected (unknown mode, non-string
  lists, blank ids), [U15] malformed response rejected (non-int or < 1
  maxChars, blank/non-string language), [U16] identity-only document loads
  as the no-op playbook, [U17] inconsistent gate documents rejected at
  load.

### Implementation for US1

- [x] T005 [US1] Implement
  `lib/src/domain/entities/playbook/playbook.dart` — `Playbook`,
  `PlaybookSteering`, `PlaybookToolGate`, `PlaybookResponse`,
  `PlaybookGateMode` with constructor validation and value semantics
  (plan.md Component 1) — makes [U1]–[U9] green.
- [x] T006 [US1] Implement
  `lib/src/domain/entities/playbook/playbook_loader.dart` —
  `PlaybookLoader.loadYaml` / `loadJson` with the typed diagnostics
  contract (plan.md Component 2) — makes [U10]–[U17] green, closing the
  outer loop [A1] and [A2].

**Checkpoint**: US1 independently functional — documents load or fail with
actionable diagnostics.

---

## Phase 3: US2 Playbook steering drives the engine (Priority: P1)

**Goal**: A loaded playbook's steering entries become the active steering
context through the existing SteeringQueue.

**Independent Test**: a mission under a playbook emits one
`SteeringInjected` event per steering entry in document order.

### Tests for US2 (written FIRST, observed failing)

- [x] T007 [US2] Test `test/engine/playbook_runtime_test.dart` (steering
  group) — [U18] `steeringMessages()` maps entries to `SteeringMessage`s in
  document order with deterministic playbook-attributable ids (entry id
  override respected), [U19] language constraint appends the pinned
  directive message, [U20] empty steering yields no messages, [U21]
  `seedSteering(queue)` returns a NEW queue with the messages enqueued
  FIFO (input queue unmutated, processedCount preserved), [U22] seeding
  nothing is a no-op; plus the acceptance test [A3] — a mission run through
  `MissionRunner` with a seeded queue drains them: one `SteeringInjected`
  event per entry, each content in the transcript as a user message.

### Implementation for US2

- [x] T008 [US2] Implement `lib/src/engine/playbook_runtime.dart` —
  `PlaybookRuntime.steeringMessages()` + `seedSteering()` (plan.md
  Component 3, steering part) — makes [U18]–[U22] green and closes [A3].

**Checkpoint**: US1 + US2 functional and independently testable.

---

## Phase 4: US3 Playbook tool gating drives the engine (Priority: P1)

**Goal**: The playbook's tool gate wraps the mission's ToolDispatcher with
typed refusals.

**Independent Test**: an allowlist gate refuses unlisted tools with
`tool not allowed: <name>` and the inner dispatcher never sees them.

### Tests for US3 (written FIRST, observed failing)

- [x] T009 [US3] Test `test/engine/playbook_runtime_test.dart` (gating
  group) — [U23] off gate delegates everything (toolName, arguments,
  isInternalMission preserved), [U24] allowlist gate refuses unlisted tools
  (typed failure `tool not allowed: <name>`, inner dispatcher never
  invoked, listed tool delegates with arguments preserved), [U25] empty
  allowlist locks down all tools, [U26] blocklist gate refuses only listed
  tools (empty blocked list delegates everything), [U27] dispatchBatch gates
  per call + validateSchema/checkRiskTier delegate; plus the acceptance test
  [A4] — a refused tool in a running mission yields `ToolCallCompleted(ok:
  false)` and the typed error in the transcript.

### Implementation for US3

- [x] T010 [US3] Implement `PlaybookToolGateDispatcher` +
  `PlaybookRuntime.gateDispatcher()` in
  `lib/src/engine/playbook_runtime.dart` (plan.md Component 3, gate part) —
  makes [U23]–[U27] green and closes [A4].

**Checkpoint**: US1–US3 functional and independently testable.

---

## Phase 5: US4 Playbook response constraints (Priority: P2)

**Goal**: Response shape follows the document: language directive via
steering + mechanical maxChars cap.

**Independent Test**: a `de`/`120` playbook injects the language directive
and truncates long responses to 120 chars + marker.

### Tests for US4 (written FIRST, observed failing)

- [x] T011 [US4] Test `test/engine/playbook_runtime_test.dart` (response
  group) — [U28] `constrainResponse` truncation boundaries (null maxChars →
  unchanged; length == maxChars → unchanged; length == maxChars + 1 →
  truncated; long → exactly the first `maxChars` characters plus the pinned
  marker naming the playbook), [U29] no constraints means no change, [U30]
  steering timestamps come from the injected clock; plus the acceptance test
  [A5] — the language directive is injected as playbook steering and an
  over-long final response is capped to its first `maxChars` characters plus
  the truncation marker.

### Implementation for US4

- [x] T012 [US4] Implement the response-constraint half of
  `PlaybookRuntime` (language directive in `steeringMessages()`,
  `constrainResponse()`) (plan.md Component 3, response part) — makes
  [U28]–[U30] green and closes [A5].

**Checkpoint**: US1–US4 functional and independently testable.

---

## Phase 6: US5 The R5#4 acceptance — zero code change (Priority: P1)

**Goal**: Three different playbook documents through one identical code path
produce document-specific observable behavior.

**Independent Test**: the acceptance test itself (SC-005).

### Tests for US5

- [x] T013 [US5] Acceptance test
  `test/engine/playbook_runtime_test.dart` (R5#4 group) — [A6] load Germany,
  Japan, and a third novel inline document; run each through the SAME
  composition (loader → runtime → seeded queue + gated dispatcher →
  `MissionRunner.run` with scripted LLM + fixed clock); assert per
  document: steering events match that document's entries, tool refusals
  match that document's gate, constrained response matches that
  document's `maxChars`; assert the observable behavior differs between
  documents (the point of R5#4); no engine code differs between runs.

### Implementation for US5

- [x] T014 [US5] No new implementation expected — the acceptance test
  drives only existing surfaces (FR-006, [A6]). If the test forces a fix,
  that fix is a behavior change with its own cycle.

**Checkpoint**: All stories independently functional; R5#4 proven.

---

## Phase 7: Gates & Polish

- [ ] T015 Run `/speckit.tdd.verify` → `tdd/verification.md` committed
  (audits all behaviors incl. [A1]–[A7] coverage; deliberate mutants on the
  highest-risk behaviors).
- [ ] T016 Gate [A7]: `dart analyze --fatal-infos` — zero findings on changed
  files (constitution X); pre-existing baseline findings (3, unrelated
  files) flagged, not touched.
- [ ] T017 Gate [A7]: full `dart test` green — baseline 1163 passed + new
  tests; purity gate: no `dart:io` imports in new files.
- [ ] T018 Commit spec-kit artifacts (spec.md, plan.md, tasks.md,
  tdd/test-list.md, tdd/verification.md) per the repo's `spec(104):` /
  `feat(104):` / `test(104):` convention; push branch; open PR to
  `master` closing #104.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: complete (specify + plan ran).
- **Phase 2 (US1 schema + loader)**: BLOCKS US2–US5 — every story
  consumes the loaded `Playbook`.
- **Phases 3–5 (US2/US3/US4)**: depend on US1; independent of each other
  at the file level (all land in `playbook_runtime.dart`, so implemented
  sequentially in priority order US2 → US3 → US4; the runtime file is the
  serialization point, tests are parallelizable).
- **Phase 6 (US5)**: depends on US1–US4 (composes all of them).
- **Phase 7 (gates)**: depends on everything.

### Within Each User Story

- Tests MUST be written and observed failing before implementation
  (TDD extension discipline; `/speckit.tdd.run` drives this).
- Value object before loader (US1); runtime surfaces in steering →
  gating → response order (runtime single file).

### Parallel Opportunities

- T003 ∥ T004 (different test files); T015–T017 gates run after all
  stories; document artifacts (Phase 7 commit) are serial.

---

## Implementation Strategy

### MVP First (US1 only)

US1 alone is a viable MVP: the schema + loader with diagnostics is the
contract the ecosystem (zik_zak country playbooks, raptorr playbook_get)
loads against, even before the engine applies it.

### Incremental Delivery

1. US1 → schema + loader (testable, shippable)
2. US2 → steering applied (the primary behavior lever)
3. US3 → tool gating (the second named observable)
4. US4 → response constraints
5. US5 → the R5#4 acceptance proof composing 1–4
6. Gates + PR

---

## Notes

- Commit cadence: one commit per green TDD cycle (test + implementation
  together), message convention `test(104):`/`feat(104):` per `git log`.
- `/speckit.tdd.plan` will annotate these tasks with behavior ids
  (`[U1]`…, `[A1]`…) and remove test optionality; that command owns the
  marker insertion, this file's checkbox states are its to tick.

---

## Phase 8: TDD remediation (from tdd/verification.md audit @ ff0fc90)

*Verdict was FAIL — the feature is not done until finding 1 is cleared.*

- [ ] T019 [P] Re-establish red-first evidence for [U17]/[U26]/[U27]/[U30]
  (HIGH finding 1): for each behavior, revert the behavior in the
  implementation, run the existing test and record the verbatim red, restore
  exactly, re-run green — recorded as remediation cycles in
  `tdd/cycle-log.md`. Proves each test fails against absent behavior (the
  write-order history cannot change; the red evidence can).
- [ ] T020 [P] Pin the at-limit truncation boundary at the acceptance level
  (MED finding 2): extend A5 with a mission whose final response is exactly
  `maxChars` characters and assert it passes through unconstrained — the
  audit's off-by-one mutant escaped A5 (U28 caught it).
- [ ] T021 Re-run `/speckit.tdd.verify` after T019/T020 — the final audit
  must show zero TEST_AFTER classifications and zero HIGH findings before
  the PR.
