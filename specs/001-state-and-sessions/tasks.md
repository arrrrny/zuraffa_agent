---
description: "Task list for state and sessions implementation"
---

# Tasks: State & Sessions

**Input**: Design documents from `/specs/001-state-and-sessions/` (`plan.md`, `spec.md`, `data-model.md`, `research.md`, `quickstart.md`, `contracts/`)

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `data-model.md`, `research.md`, `contracts/`

**Tests**: Unit and integration test tasks are explicitly included per specification acceptance requirements and TDD workflow.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Exact file paths are specified in every task description

## Path Conventions

- **Engine package**: Pure Dart library at repository root (`package:zuraffa_agent`)
- **Source files**: `lib/zuraffa_agent.dart`, `lib/src/*.dart`
- **Test files**: `test/*.dart`, `test/fixtures/*.jsonl`
- **Example files**: `example/*.dart`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, licensing, and strict linting configuration

- [x] T001 Configure root package dependencies (`hive_ce`, `test`, `lints`) in `pubspec.yaml`
- [x] T002 [P] Setup project license and attribution records in `LICENSE` and `NOTICE`
- [x] T003 [P] Configure strict static analysis and purity lint rules in `analysis_options.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure and base contracts that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create public barrel exports for engine state API in `lib/zuraffa_agent.dart`
- [x] T005 [P] Implement monotonic entry identifier generator (base36 timestamp + sequence) in `lib/src/types.dart`
- [x] T006 [P] Implement core abstract storage contract and diagnostic types (`SessionStorage`, `StoreOpenResult`, `JsonlTear`) in `lib/src/session_storage.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Granular typed state (Priority: P1) 🎯 MVP

**Goal**: Persist agent state as granular typed entities (`SessionTreeEntry`, `AgentMessage`, `TurnRecord`, `ToolInvocationRecord`, `UsageLedgerEntry`) generated via Zorphy, eliminating monolithic blobs and untyped `Map<String, dynamic>` escapes.

**Independent Test**: A mission's full state round-trips through the typed entity model across storage backends with zero untyped map escapes (`dart test test/roundtrip_test.dart test/types_test.dart`).

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T007 [P] [US1] Unit tests for sealed `SessionTreeEntry`, `AgentMessage`, and `ContentBlock` hierarchy deserialization in `test/types_test.dart`
- [ ] T008 [P] [US1] Unit tests for `TurnRecord`, `ToolInvocationRecord`, and `UsageLedgerEntry` typed properties and validation in `test/types_test.dart`
- [ ] T009 [P] [US1] Unit tests for `UsageLedger` metrics aggregation and projections (`byTurn`, `byModel`) in `test/usage_ledger_test.dart`
- [ ] T010 [P] [US1] Cross-store round-trip equivalence and typed identity retrieval tests in `test/roundtrip_test.dart`

### Implementation for User Story 1

- [ ] T011 [P] [US1] Implement sealed `AgentMessage` and `ContentBlock` hierarchy (`TextBlock`, `ImageBlock`, `AudioBlock`, `DocumentBlock`, `ToolCallBlock`, `ThinkingBlock`) in `lib/src/types.dart`
- [ ] T012 [P] [US1] Implement sealed `SessionTreeEntry` hierarchy (`MessageEntry`, `TurnRecord`, `ToolInvocationRecord`, `UsageLedgerEntry`, `CompactionEntry`, `ThinkingLevelChangeEntry`, `ModelChangeEntry`, `BranchSummaryEntry`, `LabelEntry`, `CustomEntry`) in `lib/src/types.dart`
- [ ] T013 [P] [US1] Implement typed serialization/deserialization methods with Zorphy annotations on all state entities in `lib/src/types.dart`
- [ ] T014 [US1] Implement `UsageLedger` read projection for token accounting and budget tracking in `lib/src/usage_ledger.dart`

**Checkpoint**: At this point, User Story 1 is fully functional and all typed entities round-trip with zero map escapes.

---

## Phase 4: User Story 2 - Branching session tree with fork/resume (Priority: P1)

**Goal**: Provide a tree-of-entries session model with first-class fork, switch, resume, and ancestry sharing over dual storage backends (`HiveSessionStorage` and `JsonlSessionStorage`) behind the unified `SessionStorage` interface.

**Independent Test**: Branch at entry N → diverge 2 turns → resume original branch → `buildContext()` reconstructs pre-fork history exactly with zero sibling leakage (`dart test test/session_test.dart test/session_storage_test.dart`).

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T015 [P] [US2] Unit tests for `InMemorySessionStorage` and `JsonlSessionStorage` basic CRUD operations in `test/session_storage_test.dart`
- [ ] T016 [P] [US2] Unit tests for corrupt JSONL tail detection and `JsonlTear` recovery in `test/session_storage_test.dart`
- [ ] T017 [P] [US2] Unit tests for `HiveSessionStorage` binary serialization and box operations in `test/hive_store_test.dart`
- [ ] T018 [P] [US2] Unit tests for session tree branching, fork at entry N, ancestry sharing, and clean divergence in `test/session_test.dart`
- [ ] T019 [P] [US2] Unit tests for `buildContext()` context reconstruction and leaf resumption on engine restart in `test/session_test.dart`
- [ ] T020 [P] [US2] Unit tests for `deleteBranch` refcounted ancestry preservation and leaf pruning in `test/session_test.dart`

### Implementation for User Story 2

- [ ] T021 [P] [US2] Implement `InMemorySessionStorage` in `lib/src/session_storage_impl.dart`
- [ ] T022 [P] [US2] Implement `JsonlSessionStorage` with streaming parse and corrupt tail tear recovery in `lib/src/session_storage_impl.dart`
- [ ] T023 [P] [US2] Implement binary TypeAdapters for Hive storage in `lib/src/hive_adapters.dart`
- [ ] T024 [US2] Implement `HiveSessionStorage` using `hive_ce` boxes in `lib/src/hive_session_store.dart`
- [ ] T025 [US2] Implement `AgentSession` tree operations (`appendMessage`, `appendTurn`, `appendToolInvocation`, `appendUsage`, `appendCompaction`) in `lib/src/session.dart`
- [ ] T026 [US2] Implement branching navigation (`fork`, `switchTo`, `listBranchHeads`, `getBranch`) in `lib/src/session.dart`
- [ ] T027 [US2] Implement conversation context reconstruction (`buildContext`) in `lib/src/session.dart`
- [ ] T028 [US2] Implement branch deletion with ancestry reference counting and leaf pruning (`deleteBranch`) in `lib/src/session.dart`

**Checkpoint**: At this point, User Stories 1 AND 2 work independently, supporting full session branching, resumption, and dual-backend persistence.

---

## Phase 5: User Story 3 - Selective compaction (Priority: P1)

**Goal**: Compact long-running session context at turn boundaries by retaining decisions, tool names, key results, and plan state while replacing verbose outputs with structured summaries and `ArtifactRef` pointers, extending trajectories to 50+ tool calls within context budgets.

**Independent Test**: A 50+ tool-call deterministic fixture mission stays under its configured token budget with no outcome regression versus uncompacted baseline (`dart test test/compaction_test.dart`).

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T029 [P] [US3] Unit tests for token estimation and threshold checking (`estimateContextTokens`, `shouldCompact`, `findCutPoint`) in `test/compaction_test.dart`
- [ ] T030 [P] [US3] Unit tests for `HeuristicSummarizer` extracting decisions, tools, key results, and plan state in `test/compaction_test.dart`
- [ ] T031 [P] [US3] Integration test verifying compaction executes strictly at turn boundaries without mid-batch interruption in `test/compaction_test.dart`
- [ ] T032 [P] [US3] Integration test verifying branch isolation during compaction in `test/compaction_test.dart`
- [ ] T033 [US3] Acceptance test with 50+ tool-call fixture mission (`test/fixtures/mission_50.jsonl`) verifying context budget adherence and outcome parity in `test/compaction_test.dart`

### Implementation for User Story 3

- [ ] T034 [P] [US3] Create deterministic 50+ tool-call fixture mission dataset in `test/fixtures/mission_50.jsonl`
- [ ] T035 [P] [US3] Implement `CompactionSettings`, `CompactionSummary`, `ArtifactRef`, `ArtifactResolver`, and `CompactionSummarizer` contracts in `lib/src/compaction.dart`
- [ ] T036 [US3] Implement token estimation and split logic (`estimateContextTokens`, `estimateEntriesTokens`, `shouldCompact`, `findCutPoint`, `prepareCompaction`) in `lib/src/compaction.dart`
- [ ] T037 [US3] Implement `HeuristicSummarizer` for structured rule-based summarization in `lib/src/compaction.dart`
- [ ] T038 [US3] Implement core `compact` pipeline function appending `CompactionEntry` with preserved artifact pointers in `lib/src/compaction.dart`
- [ ] T039 [US3] Integrate compaction summary handling and context boundary slicing into `AgentSession.buildContext()` in `lib/src/session.dart`

**Checkpoint**: At this point, User Stories 1, 2, and 3 work together, enabling long-running trajectories to compact cleanly without losing decisions or branch integrity.

---

## Phase 6: User Story 4 - pi_agent seed merge (Priority: P1)

**Goal**: Merge production-grade support assets from `pi_agent` (branch `001-dart-agent-package`) into the engine repo with full MIT attribution headers, zero unwired stub code, and comprehensive test coverage.

**Independent Test**: All ported support modules compile cleanly, carry attribution headers, and pass the unit test suite (`dart test test/skills_test.dart test/prompt_templates_test.dart test/execution_env_test.dart test/sse_parser_test.dart test/tools_test.dart`).

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T040 [P] [US4] Unit tests for tool parameter schema validation in `test/tools_test.dart`
- [ ] T041 [P] [US4] Unit tests for skill discovery, `SKILL.md` parsing, and prompt formatting in `test/skills_test.dart`
- [ ] T042 [P] [US4] Unit tests for prompt template argument substitution (`$1..$N`, `$@`, `$ARGUMENTS`) in `test/prompt_templates_test.dart`
- [ ] T043 [P] [US4] Unit tests for `LocalExecutionEnv` safe file operations, truncation, and subprocess execution in `test/execution_env_test.dart`
- [ ] T044 [P] [US4] Unit tests for Server-Sent Events parser chunk decoding in `test/sse_parser_test.dart`

### Implementation for User Story 4

- [ ] T045 [P] [US4] Port and adapt tool schema validation engine (`AgentTool`, `validateParameters`) with MIT attribution header in `lib/src/tools.dart`
- [ ] T046 [P] [US4] Port and adapt skill discovery and system prompt formatting (`loadSkills`, `formatSkillsForSystemPrompt`) with MIT attribution header in `lib/src/skills.dart`
- [ ] T047 [P] [US4] Port and adapt prompt template engine (`loadPromptTemplates`, `substituteArgs`) with MIT attribution header in `lib/src/prompt_templates.dart`
- [ ] T048 [P] [US4] Port and adapt execution environment abstraction (`ExecutionEnv`, `LocalExecutionEnv`) with MIT attribution header in `lib/src/execution_env.dart`
- [ ] T049 [P] [US4] Port and adapt Server-Sent Events byte stream parser (`parseSSE`) with MIT attribution header in `lib/src/sse_parser.dart`
- [ ] T050 [US4] Audit and eliminate all unwired stub code, placeholder loops, and dummy implementations across `lib/`

**Checkpoint**: All ported seed assets are fully integrated, attributed, and tested with zero placeholder stubs.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end integration validation, static analysis cleanliness, engine purity audit, and documentation demo

- [ ] T051 [P] Create interactive branching smoke demo script in `example/session_demo.dart`
- [ ] T052 Run Dart analyzer with fatal infos verification (`dart analyze --fatal-infos`)
- [ ] T053 Run engine purity audit ensuring zero `dart:io` imports outside allowlisted storage and loader adapters
- [ ] T054 Run full test suite validation per `quickstart.md` (`dart test`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User Story 1 (P1) and User Story 4 (P1) can proceed in parallel once Foundation is complete
  - User Story 2 (P1) depends on User Story 1 entity definitions (`types.dart`)
  - User Story 3 (P1) depends on User Story 1 entity types and User Story 2 `AgentSession` implementation
- **Polish (Phase 7)**: Depends on all user stories (US1–US4) being complete

### User Story Dependencies

```text
Foundational (Phase 2)
  ├── US1: Granular Typed State (Types & Models) ──> US2: Branching Session Tree (Storage & Session) ──> US3: Selective Compaction
  └── US4: Ported Support Assets (Tools, Skills, Templates, Env, SSE) ──────────────────────────────────┘
```

- **User Story 1 (P1)**: Starts immediately after Foundational (Phase 2)
- **User Story 4 (P1)**: Starts immediately after Foundational (Phase 2) in parallel with US1
- **User Story 2 (P1)**: Starts after US1 entities (`types.dart`, `session_storage.dart`) are available
- **User Story 3 (P1)**: Starts after US1 entity types and US2 `AgentSession` context integration are available

### Within Each User Story

- Tests MUST be written and fail before implementation
- Entity models and contracts before storage adapters and services
- Storage adapters before high-level session managers
- Core algorithms before context reconstruction integration
- User story verification complete before advancing

### Parallel Opportunities

- **Phase 1**: T002 and T003 can run in parallel
- **Phase 2**: T005 and T006 can run in parallel
- **Phase 3 (US1)**: Test tasks T007, T008, T009, T010 can run in parallel; implementation tasks T011, T012, T013 can run in parallel
- **Phase 4 (US2)**: Storage adapters T021, T022, T023 and test tasks T015, T016, T017, T018, T019, T020 can run in parallel
- **Phase 5 (US3)**: Test tasks T029, T030, T031, T032 and fixture generation T034, contract definitions T035 can run in parallel
- **Phase 6 (US4)**: All tests T040, T041, T042, T043, T044 and port implementations T045, T046, T047, T048, T049 can run in parallel
- **User Stories**: US1 and US4 can execute completely concurrently by separate developers

---

## Parallel Execution Examples

### Parallel Example: User Story 1

```bash
# Launch all test authoring for User Story 1 together:
Task: "Unit tests for sealed SessionTreeEntry, AgentMessage, and ContentBlock hierarchy deserialization in test/types_test.dart"
Task: "Unit tests for TurnRecord, ToolInvocationRecord, and UsageLedgerEntry typed properties and validation in test/types_test.dart"
Task: "Unit tests for UsageLedger metrics aggregation and projections (byTurn, byModel) in test/usage_ledger_test.dart"
Task: "Cross-store round-trip equivalence and typed identity retrieval tests in test/roundtrip_test.dart"

# Launch model entity implementations together:
Task: "Implement sealed AgentMessage and ContentBlock hierarchy in lib/src/types.dart"
Task: "Implement sealed SessionTreeEntry hierarchy in lib/src/types.dart"
Task: "Implement typed serialization/deserialization methods with Zorphy annotations on all state entities in lib/src/types.dart"
```

### Parallel Example: User Story 4

```bash
# Launch all ported asset tasks together:
Task: "Port and adapt tool schema validation engine (AgentTool, validateParameters) with MIT attribution header in lib/src/tools.dart"
Task: "Port and adapt skill discovery and system prompt formatting (loadSkills, formatSkillsForSystemPrompt) with MIT attribution header in lib/src/skills.dart"
Task: "Port and adapt prompt template engine (loadPromptTemplates, substituteArgs) with MIT attribution header in lib/src/prompt_templates.dart"
Task: "Port and adapt execution environment abstraction (ExecutionEnv, LocalExecutionEnv) with MIT attribution header in lib/src/execution_env.dart"
Task: "Port and adapt Server-Sent Events byte stream parser (parseSSE) with MIT attribution header in lib/src/sse_parser.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006)
3. Complete Phase 3: User Story 1 (T007–T014)
4. **STOP and VALIDATE**: Verify granular typed state round-trips via `dart test test/roundtrip_test.dart test/types_test.dart`
5. Release/tag initial MVP entity substrate

### Incremental Delivery

1. **Increment 1 (MVP)**: Setup + Foundational + User Story 1 → Granular typed entities and usage ledger
2. **Increment 2**: User Story 4 → Attributed support assets (tools, skills, templates, env, SSE)
3. **Increment 3**: User Story 2 → Dual storage backends (Hive + JSONL), tree branching, fork/resume/prune
4. **Increment 4**: User Story 3 → Selective compaction engine, turn-boundary summarizer, 50+ tool-call verification
5. **Increment 5**: Polish & Validation → Pure Dart analyzer check, purity check, and interactive smoke demo

### Parallel Team Strategy

With multiple developers:
1. Team completes Setup + Foundational together (T001–T006)
2. Once Foundational is done:
   - Developer A: User Story 1 (Granular typed state: T007–T014)
   - Developer B: User Story 4 (Ported support assets: T040–T050)
3. Once US1 completes:
   - Developer A: User Story 2 (Branching session tree: T015–T028)
4. Once US2 completes:
   - Developer A: User Story 3 (Selective compaction: T029–T039)
5. Team executes Polish (T051–T054)

---

## Notes

- `[P]` tasks = different files, no dependencies
- `[Story]` label maps task to specific user story (`[US1]`, `[US2]`, `[US3]`, `[US4]`) for end-to-end traceability
- Every task includes an explicit file path
- Verify unit tests fail before implementing the corresponding modules
- All ported assets carry the MIT attribution header per Constitution VIII
- Runtime stays 100% Flutter-free per Constitution VII with `dart:io` quarantined to storage and loader adapters
- Commit after each task or logical group
