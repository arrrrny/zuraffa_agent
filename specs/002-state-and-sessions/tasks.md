# Tasks: State & Sessions

**Input**: Design documents from `/specs/002-state-and-sessions/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/ (session-api.md, compaction-api.md, support-assets.md), quickstart.md

**Tests**: Requested — unit/acceptance tests are included as tasks, written FIRST (they must fail before implementation) for new code. Ported modules (US4) port their existing pi_agent tests alongside the source.

**Organization**: Tasks grouped by user story. All four stories are P1; the spec's listing order (US1 → US2 → US3 → US4) is the implementation order.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Exact file paths in every description; repo root is the Dart package (`lib/`, `test/`, `example/`)

## Path Conventions

Single pure-Dart package at repo root: sources in `lib/src/`, public barrel `lib/zuraffa_agent.dart`, tests in `test/`, fixtures in `test/fixtures/`. No Flutter dependency at any layer (constitution VII).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Package scaffolding the whole feature seeds (research R2, R3)

- [x] T001 Create `pubspec.yaml` at repo root: package `zuraffa_agent`, SDK `^3.6`, environment pure Dart, single runtime dep `hive_ce: ^2.19.0`, dev deps `test: ^1.25` and `lints: ^6`; no Flutter deps (constitution VII)
- [x] T002 [P] Create `analysis_options.yaml` at repo root including `package:lints/recommended.yaml`
- [x] T003 [P] Create `LICENSE` at repo root (MIT, per research R11)
- [x] T004 [P] Create `NOTICE` at repo root recording pi_agent port provenance (`~/Developer/pi/pi_agent`, branch `001-dart-agent-package`, MIT) per contracts/support-assets.md — **NOTE**: upstream LICENSE is actually BSD-3-Clause (ZikZak AI, same holder); recorded accurately in NOTICE with MIT relicense rationale

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core ported type system + storage contract that EVERY user story depends on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Resolve Constitution IX vs plan R4 BEFORE writing entity code: constitution v1.1.0 mandates Zorphy for all entities; plan/research R4 chose hand-written classes (single runtime dep, no codegen). Either apply Zorphy annotations in T006/T017, or amend the constitution via `/skill:speckit-constitution` (PATCH/MINOR) to exempt this ported entity layer; record the decision as an addendum in `specs/002-state-and-sessions/research.md` — **DONE**: constitution amended to v1.2.0 (MINOR, scoped exemption clause under Art. IX); decision recorded as research R13
- [x] T006 Port the core type system to `lib/src/types.dart` with attribution header (contracts/support-assets.md): sealed `SessionTreeEntry` base (`id`, `parentId`, `timestamp`); entry subclasses `MessageEntry`, `ThinkingLevelChangeEntry`, `ModelChangeEntry`, `CompactionEntry`, `BranchSummaryEntry`, `LabelEntry`, `CustomEntry`; sealed `AgentMessage` (`UserMessage`, `AssistantMessage`, `ToolResultMessage`, `CustomMessage`) with content blocks `TextBlock`, `ImageBlock`, `ToolCallBlock`, `ThinkingBlock` plus NEW `AudioBlock`, `DocumentBlock`; enums `ThinkingLevel`, `StopReason`; support types `Model`, `Usage`, `Skill`, `SkillDiagnostic`, `PromptTemplate`, `CompactionSettings`, `SessionInfo`, `SessionContext` (data-model.md; pi_agent `typedef AgentTool<T,D> = dynamic` is NOT ported)
- [x] T007 Port `lib/src/tools.dart` with attribution header: real `AgentTool<TParameters, TDetails>` class (`toApiFormat`, `executionMode`, `prepareArguments`) and `validateParameters` JSON-Schema subset validator (type, properties, required, enum, items, additionalProperties, minimum/maximum, minLength/maxLength) per contracts/support-assets.md
- [x] T008 Implement monotonic entry ID generator in `lib/src/types.dart` (microsecond timestamp base36 + per-process sequence suffix, collision-free under single-writer, lexicographically sortable — research R6)
- [x] T009 Create public barrel `lib/zuraffa_agent.dart` exporting `types.dart` + `tools.dart`; extend exports as each phase lands (replaces pi_agent's `pi.dart`)
- [x] T010 Define `SessionStorage` abstract interface plus `StoreOpenResult` and `JsonlTear` (`lineNumber`, `reason`, `salvagedEntryCount`) in `lib/src/session_storage.dart` per contracts/session-api.md (`init()` returns tear report)
- [x] T011 [P] Write unit tests in `test/types_test.dart`: sealed-hierarchy coverage, equality, multimodal content blocks (incl. audio/document), convenience constructors (`UserMessage.text`, `ToolResultMessage.text`), enums, ID generator monotonicity/collision-freedom
- [x] T012 [P] Write unit tests in `test/tools_test.dart`: `validateParameters` across the full schema subset (valid/invalid/required/enum/bounds), `AgentTool.toApiFormat`

**Checkpoint**: Foundation ready — entity types, tools, ID scheme, barrel, and the storage contract exist with green unit tests

---

## Phase 3: User Story 1 — Granular typed state (Priority: P1) 🎯 MVP

**Goal**: Missions persist as granular typed entities (turn/message/invocation/usage) through Hive + JSONL stores behind one `SessionStorage` interface — no monolithic blob, no `Map<String, dynamic>` escapes (FR-001, FR-003, SC-003)

**Independent Test**: A mission's full state round-trips through the entity model with no map escapes (spec US1).

### Tests for User Story 1 (write first; must fail)

- [ ] T013 [P] [US1] Write acceptance test in `test/roundtrip_test.dart` (US1 AC1, quickstart Scenario 1): build a 3-turn mission (user → assistant w/ thinking + tool calls → tool results, closed by `TurnRecord`, `ToolInvocationRecord` per call, `UsageLedgerEntry` per LLM call); persist via `JsonlSessionStorage` AND `HiveSessionStorage`; close/reopen; assert every entry retrievable by ID as its concrete typed subclass, ledger totals match known fixture counts, Hive and JSONL entry sequences are identical (cross-store equivalence)
- [ ] T014 [P] [US1] Write tests in `test/session_storage_test.dart`: shared behavioral contract suite parameterized over all three stores (round-trip, identity, leaf persistence, metadata), plus the corrupt-JSONL-tail edge case — truncated/garbled final line loads the salvaged prefix and returns `JsonlTear` with line number + reason; stop at first bad line (research R7, spec edge case)
- [ ] T015 [P] [US1] Write tests in `test/hive_store_test.dart`: hand-written adapter round-trip for every entity type, typed payload equality after Hive binary round-trip, deterministic type IDs
- [ ] T016 [P] [US1] Write tests in `test/usage_ledger_test.dart`: `UsageLedger.fromEntries` totals, `byTurn()`, `byModel()` (contracts/support-assets.md projection)

### Implementation for User Story 1

- [ ] T017 [US1] Add granular entities to `lib/src/types.dart` as sealed `SessionTreeEntry` subclasses per data-model.md: `TurnRecord` (turnNumber, messageEntryIds, stopReason, startedAt/endedAt, durationMs), `ToolInvocationRecord` (toolCallId, toolName, arguments, resultEntryId nullable in-flight, isError, durationMs, artifactRefs), `UsageLedgerEntry` (callId, turnNumber, model, token counts) — enforce validation rules (non-empty same-branch messageEntryIds, non-negative token counts) per the T005 Zorphy decision
- [ ] T018 [US1] Implement `InMemorySessionStorage` and `JsonlSessionStorage` in `lib/src/session_storage.dart`: JSONL on-disk format per contracts/session-api.md (`_header` first line + typed entry lines incl. `turn`/`toolInvocation`/`usage`/`compaction`), load stops at first undecodable line and reports tears
- [ ] T019 [US1] Implement hand-written Hive `TypeAdapter`s for all sealed entity/message types in `lib/src/hive_adapters.dart` with explicit deterministic type IDs (research R4)
- [ ] T020 [US1] Implement `HiveSessionStorage` in `lib/src/hive_session_store.dart` (`hive_ce` import confined to this file + `hive_adapters.dart`)
- [ ] T021 [US1] Implement `UsageLedger` read-side projection in `lib/src/usage_ledger.dart`: `fromEntries`, `totalInputTokens`, `totalOutputTokens`, `byTurn()`, `byModel()` — the MissionBudgetHook shape

**Checkpoint**: US1 independently testable — `dart test test/roundtrip_test.dart` green; entity API has no map escapes (custom extensibility points excepted)

---

## Phase 4: User Story 2 — Branching session tree with fork/resume (Priority: P1)

**Goal**: `AgentSession` tree-of-entries with fork/switch/resume/deleteBranch over Hive + JSONL stores (FR-002, SC-001)

**Independent Test**: Branch → diverge 2 turns → resume original branch → context reconstruction matches pre-fork history exactly (spec US2).

### Tests for User Story 2 (write first; must fail)

- [ ] T022 [US2] Write acceptance tests in `test/session_test.dart` (US2 AC1–3, quickstart Scenario 2 + edge cases), parameterized over InMemory/JSONL/Hive: fork at entry N shares ancestry and diverges from N+1 (AC1); `switchTo` between diverged branches returns exactly the active branch's conversation — no sibling leakage (AC2, invariant I3); close/reopen store after "restart" resumes from persisted leaf with byte-identical `buildContext()` (AC3, invariant I4); `deleteBranch` on a branch sharing ancestry retains ancestor entries and prunes only leaf-only entries (edge case, research R8)

### Implementation for User Story 2

- [ ] T023 [US2] Port `AgentSession` (renamed from `Session`) to `lib/src/session.dart` with attribution header: append methods incl. NEW `appendTurn`, `appendToolInvocation`, `appendUsage`, `appendCompaction`; reads `buildContext()` (leaf→root walk), `getBranch`, `getEntries`, `getEntry`, `getMetadata`, `moveTo` per contracts/session-api.md
- [ ] T024 [US2] Implement branch management in `lib/src/session.dart`: `fork(atEntryId)`, `switchTo`, `listBranchHeads`, `deleteBranch` pruning upward while derived child count is zero (no persistent refcounts — research R8); reject orphan-parent appends with `SessionTreeException`

**Checkpoint**: US1 + US2 independently functional — fork/resume round-trips on both Hive and JSONL (SC-001)

---

## Phase 5: User Story 3 — Selective compaction (Priority: P1)

**Goal**: Selective structured compaction (retain/summarize/artifact-ref) keeping 50+ tool-call missions under budget with outcome equality (FR-004, SC-002)

**Independent Test**: A 50+ tool-call fixture mission stays under its context budget with no outcome regression vs the uncompacted baseline (spec US3).

### Tests for User Story 3 (write first; must fail)

- [ ] T025 [P] [US3] Create deterministic fixture mission `test/fixtures/mission_50.jsonl`: 50+ tool calls across 3+ turns with recorded uncompacted baseline outcome defined by a deterministic checker (outcome, not transcript — quickstart Scenario 3)
- [ ] T026 [P] [US3] Write acceptance tests in `test/compaction_test.dart` (US3 AC1–2, quickstart Scenario 3 + edge cases): `CompactionSummary` retains decisions/toolNames/keyResults/planState; every `ArtifactRef` resolves via a test `ArtifactResolver`; estimated context after each compaction ≤ window − reserve; compacted final outcome equals the uncompacted baseline; compaction runs only at turn boundaries (never mid-batch, edge case); `CompactionEntry` lands on the active branch only, sibling ancestry untouched (invariant I2, edge case)

### Implementation for User Story 3

- [ ] T027 [US3] Implement structured summary types in `lib/src/compaction.dart`: `CompactionSummary`, `ArtifactRef`, `ArtifactResolver`, injectable `CompactionSummarizer`, and `HeuristicSummarizer` default (extracts decisions/tool names/key results/plan state from typed entries; composes `previousSummary`) — pi_agent's `_generatePlaceholderSummary` is NOT ported (research R9)
- [ ] T028 [US3] Implement compaction core in `lib/src/compaction.dart`: `TokenEstimator` + `estimateContextTokens` (chars/4 default; recorded `UsageLedgerEntry` counts take precedence — research R12), `shouldCompact`, `findCutPoint`, `prepareCompaction`, `compact()` requiring an injected summarizer per contracts/compaction-api.md

**Checkpoint**: US3 independently testable — fixture mission completes 50+ iterations within budget, outcome equal to baseline (SC-002)

---

## Phase 6: User Story 4 — pi_agent seed merge (Priority: P1)

**Goal**: Remaining pi_agent support assets merged with attribution; zero stub code ships (FR-005, SC-004)

**Independent Test**: Seed lands as library code with tests; zero stub code remains (spec US4).

### Implementation for User Story 4 (ports: module + its tests land together)

- [ ] T029 [P] [US4] Port `lib/src/skills.dart` with attribution header + tests in `test/skills_test.dart`: `loadSkills`/`loadSourcedSkills` (SKILL.md / `*.skill.md` discovery, case-insensitive, built-in frontmatter parser — no `yaml` dep), `formatSkillInvocation`, `formatSkillsForSystemPrompt` per contracts/support-assets.md
- [ ] T030 [P] [US4] Port `lib/src/prompt_templates.dart` with attribution header + tests in `test/prompt_templates_test.dart`: `loadPromptTemplates`, `loadSourcedPromptTemplates`, `substituteArgs` ($1..$N, $@, $ARGUMENTS, ${@:N}), `parseCommandArgs` shell-style quoting, `formatPromptTemplateInvocation`
- [ ] T031 [P] [US4] Port `lib/src/execution_env.dart` with attribution header + tests in `test/execution_env_test.dart`: `ExecutionEnv` abstraction, `LocalExecutionEnv`, `FileInfo`/`ShellResult`/`FileError`, `truncateHead`/`truncateTail`, `formatSize`; no exceptions for expected missing files
- [ ] T032 [P] [US4] Port `lib/src/sse_parser.dart` with attribution header + tests in `test/sse_parser_test.dart`: `parseSSE` byte-stream → event maps (multi-line data, `:` comments, chunked input, final unterminated event)
- [ ] T033 [US4] Attribution sweep: every file under `lib/src/` ported from pi_agent opens with the attribution header from contracts/support-assets.md; `LICENSE` + `NOTICE` accurately record provenance (US4 AC1)
- [ ] T034 [US4] Zero-stub package gate (US4 AC1, quickstart Scenario 4): `grep -rn "placeholder\|TODO\|typedef AgentTool.*dynamic" lib/` returns nothing; `dart analyze` clean; `dart test` green; `dart publish --dry-run` succeeds

**Checkpoint**: All stories functional; shipped package contains zero stub code with complete attribution (SC-004)

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T035 Audit `lib/zuraffa_agent.dart` barrel: every public API exported; entity-returning signatures expose no `Map<String, dynamic>` (custom extensibility points excepted — data-model.md)
- [ ] T036 [P] Create `example/session_demo.dart` manual smoke: fork, diverge, resume, print divergent contexts + byte-identical post-restart context (quickstart manual smoke)
- [ ] T037 [P] Dartdoc audit: every public member in `lib/` documented (ported pi_agent style, plan.md library-first constraint)
- [ ] T038 Performance verification per plan.md goals: append O(1), `buildContext()` O(branch length), 200-entry store round-trip < 1s — assert in `test/session_storage_test.dart` (timing test) or a benchmark run recorded in the PR
- [ ] T039 Run full `specs/002-state-and-sessions/quickstart.md` validation end-to-end: all 4 scenarios, edge-case table, optional manual smoke; record results in the feature PR

---

## Requirements → Tasks Traceability

| Spec item | Tasks |
|---|---|
| FR-001 granular typed entities | T006, T008, T017, T011, T013 |
| FR-002 session tree, fork/switch/resume | T023, T024, T022 |
| FR-003 Hive + JSONL behind one interface | T010, T018, T019, T020, T014, T015 |
| FR-004 selective structured compaction | T027, T028, T026 |
| FR-005 attributed merge, stubs replaced | T006, T007, T023, T029–T034 |
| US1 AC1 typed round-trip, no map escapes | T013, T017, T021 |
| US2 AC1 fork shares ancestry, diverges | T024, T022 |
| US2 AC2 switch, no sibling leakage | T024, T023, T022 |
| US2 AC3 restart resumes identical context | T023, T022 |
| US3 AC1 retained categories + artifact refs | T027, T026 |
| US3 AC2 outcome equality vs baseline | T025, T026, T028 |
| US4 AC1 attribution, suite passes, zero stubs | T033, T034 |
| SC-001 branch round-trip on Hive + JSONL | T022 |
| SC-002 50+ calls under budget, no regression | T025, T026 |
| SC-003 granular + typed, no blob escapes | T013, T035 |
| SC-004 merged, attributed, zero stub code | T033, T034 |
| Edge: compaction only at turn boundaries | T026, T028 |
| Edge: branch delete keeps shared ancestry | T024, T022 |
| Edge: compaction isolates to one branch | T026, T027 |
| Edge: corrupt JSONL tail → tear report | T018, T014 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (T005 reconciliation gates T006/T017)
- **Phase 3 (US1)**: Depends on Foundational (types + storage contract)
- **Phase 4 (US2)**: Depends on US1 (fork/resume tests run on the US1 stores)
- **Phase 5 (US3)**: Depends on US1 (entity entries + ledger-aware estimator); independent of US2
- **Phase 6 (US4)**: T029–T032 depend only on Foundational (can run in parallel with US1–US3); T033–T034 require all prior phases green
- **Polish (Phase 7)**: Depends on all user stories

### Within Each User Story

- Test tasks are written FIRST and must fail (TDD); ports (US4) land module + tests together
- Types/entities before stores; stores before cross-store tests; summarizer types before compaction core
- Story fully green before moving to the next

### Parallel Opportunities

- T002/T003/T004 (Phase 1); T011/T012 (Phase 2)
- T013/T014/T015/T016 — all four US1 test files together
- T025/T026 (US3 tests + fixture); T029/T030/T031/T032 — all four US4 module ports together
- T036/T037 (Phase 7)

---

## Parallel Example: User Story 1

```bash
# Launch all US1 test tasks together (different files):
Task: "T013 acceptance round-trip test in test/roundtrip_test.dart"
Task: "T014 contract suite + JSONL tear tests in test/session_storage_test.dart"
Task: "T015 Hive adapter tests in test/hive_store_test.dart"
Task: "T016 usage ledger tests in test/usage_ledger_test.dart"
```

---

## Implementation Strategy

### MVP First (Foundation + User Story 1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (T005 reconciliation FIRST — blocks entity code)
3. Complete Phase 3: US1 (typed entities + three stores + round-trip)
4. **STOP and VALIDATE**: `dart test test/roundtrip_test.dart test/session_storage_test.dart` — US1's independent test passes
5. Deployable increment: typed persistence layer with contract-tested stores

### Incremental Delivery

1. Setup + Foundational → core types, tools, storage contract
2. +US1 → typed persistence, cross-store equivalence (MVP)
3. +US2 → branching sessions, restart identity (SC-001)
4. +US3 → budgeted compaction, outcome equality (SC-002)
5. +US4 → full seed merge, attribution, zero-stub gate (SC-004)
6. Polish → barrel audit, demo, docs, performance, quickstart validation

### Parallel Team Strategy

1. Team completes Setup + Foundational together (resolve T005 as a group decision)
2. Then: Dev A → US1 → US2 → US3 (sequential chain); Dev B → US4 module ports T029–T032 in parallel
3. T033–T034 + Phase 7 integrate once both streams complete

---

## Notes

- **Constitution**: VII (engine purity — no Flutter deps, verified by T034 dry-run; keep `dart:io` imports out of `types.dart`/`session.dart`/`compaction.dart`/`usage_ledger.dart`/`sse_parser.dart` — file-loading assets `skills.dart`/`prompt_templates.dart`/`execution_env.dart` and store impls use it by design), VIII (attributed ports — T004/T033), IX (Zorphy — reconcile in T005 before any entity code; plan.md's constitution check predates ratification v1.1.0)
- [P] tasks = different files, no dependencies
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
- The `hive_ce` import lives ONLY in `hive_session_store.dart` + `hive_adapters.dart` (plan.md quarantine)
- pi_agent's loop stub, agent shell, LLM client, and conversion layer are NOT ported (specs 001/004 own them) — zero stubs by construction (research R10)
