# Tasks: Tools & MCP Client

**Input**: Design documents from `/specs/003-tools-and-mcp/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create feature directory structure per implementation plan (lib/src/mcp/, lib/src/artifact/, lib/src/engine/)
- [ ] T002 Add MCP client dependencies to pubspec.yaml (zuraffa from git, hive_ce)
- [ ] T003 [P] Configure build_runner for Zorphy code generation
- [ ] T004 [P] Add test dependencies (test, mocktail) to pubspec.yaml

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Create Zorphy entity: RiskTier enum (safe, confirm, admin) in lib/src/domain/entities/risk_tier/risk_tier.dart
- [ ] T006 Create Zorphy entity: ExecutionMode enum (sequential, parallel) in lib/src/domain/entities/execution_mode/execution_mode.dart
- [ ] T007 Create Zorphy entity: ToolSource enum (dda, generated, mcp) in lib/src/domain/entities/tool_source/tool_source.dart
- [ ] T008 Create Zorphy entity: AgentTool in lib/src/domain/entities/agent_tool/agent_tool.dart (name, description, inputSchema, riskTier, executionMode, source, transportBinding)
- [ ] T009 Create Zorphy entity: ArtifactRef in lib/src/domain/entities/artifact_ref/artifact_ref.dart (id: ZorphyId, mimeType, sizeBytes, createdAt)
- [ ] T010 Create Zorphy entity: Artifact in lib/src/domain/entities/artifact/artifact.dart (ref: ArtifactRef, data: Uint8List)
- [ ] T011 Create Zorphy entity: ApprovalRequest in lib/src/domain/entities/approval_request/approval_request.dart (toolName, arguments, requestedAt, timeoutMs)
- [ ] T012 Create Zorphy entity: ToolDispatchResult in lib/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart (success, result, error, artifactRefs)
- [ ] T013 Create Zorphy entity: McpTransport sealed class in lib/src/mcp/transport/transport.dart with subclasses InProc, Sse, Stdio
- [ ] T014 Create Zorphy entity: SseTransportConfig in lib/src/mcp/transport/sse_transport_config.dart (endpoint, bearerToken, authCallback, reconnectPolicy)
- [ ] T015 Create Zorphy entity: StdioTransportConfig in lib/src/mcp/transport/stdio_transport_config.dart (command, args, env, restartPolicy)
- [ ] T016 Create Zorphy entity: InProcTransportConfig in lib/src/mcp/transport/inproc_transport_config.dart (toolRegistry reference)
- [ ] T017 Create Zorphy entity: ReconnectPolicy in lib/src/mcp/transport/reconnect_policy.dart (baseDelay, maxDelay, multiplier, jitter, maxRetries)
- [ ] T018 Create Zorphy entity: RestartPolicy in lib/src/mcp/transport/restart_policy.dart (maxRetries, backoffDelays)
- [ ] T019 [P] Run build_runner to generate Zorphy part files (.zorphy.dart, .g.dart)
- [ ] T020 Create ArtifactService interface in lib/src/artifact/artifact_service.dart (store, fetch, delete, list, thresholdBytes config)
- [ ] T021 Create InMemoryArtifactStore implementation in lib/src/artifact/in_memory_artifact_store.dart
- [ ] T022 Create ToolRegistry interface in lib/src/engine/tool_registry.dart (register, unregister, resolve, list, onCollision stream)
- [ ] T023 Create AgentToolRegistry implementation in lib/src/engine/agent_tool_registry.dart with namespace collision handling (dda:, gen:, mcp:<server_id>:)
- [ ] T024 Create ToolDispatcher interface in lib/src/engine/tool_dispatcher.dart (dispatch, dispatchBatch, validateSchema, checkRiskTier)
- [ ] T025 Create ToolDispatcherImpl in lib/src/engine/tool_dispatcher_impl.dart with sequential/parallel execution, JSON Schema validation, risk tier enforcement
- [ ] T026 Create ApprovalCallback typedef and default implementation in lib/src/engine/approval_callback.dart
- [ ] T027 Create AuthCallback typedef in lib/src/mcp/auth_callback.dart
- [ ] T028 [P] Run build_runner to generate any new Zorphy part files

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Registry-backed Tool Model (Priority: P1) 🎯 MVP

**Goal**: Single tool registry serving DDA-registered tools, AgentPlugin-generated usecase tools, and remote MCP tools with JSON-Schema validation and sequential/parallel execution modes.

**Independent Test**: A mission calls one in-proc tool, one generated-usecase tool, and one remote-MCP tool in a single turn — dispatched correctly from one namespace.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T029 [P] [US1] Unit test: AgentToolRegistry registers tools from all three sources in lib/src/engine/agent_tool_registry_test.dart
- [ ] T030 [P] [US1] Unit test: AgentToolRegistry resolves tools regardless of origin in lib/src/engine/agent_tool_registry_test.dart
- [ ] T031 [P] [US1] Unit test: AgentToolRegistry handles namespace collision with deterministic prefixing in lib/src/engine/agent_tool_registry_test.dart
- [ ] T032 [P] [US1] Unit test: ToolDispatcher validates arguments against JSON Schema in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T033 [P] [US1] Unit test: ToolDispatcher dispatches parallel batch with results in call order in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T034 [P] [US1] Integration test: Mission calls DDA + generated + MCP tools in single turn in test/integration/registry_integration_test.dart

### Implementation for User Story 1

- [ ] T035 [P] [US1] Implement DDA tool registration API in lib/src/engine/agent_tool_registry.dart (registerDdaTool)
- [ ] T036 [P] [US1] Implement generated tool registration API in lib/src/engine/agent_tool_registry.dart (registerGeneratedTool)
- [ ] T037 [P] [US1] Implement MCP tool registration API in lib/src/engine/agent_tool_registry.dart (registerMcpTool)
- [ ] T038 [US1] Implement namespace collision detection and prefixing in lib/src/engine/agent_tool_registry.dart (dda: native, gen:, mcp:<server_id>:)
- [ ] T039 [US1] Implement onCollision event stream emission in lib/src/engine/agent_tool_registry.dart
- [ ] T040 [US1] Implement JSON Schema validation in ToolDispatcherImpl in lib/src/engine/tool_dispatcher_impl.dart (using json_schema package)
- [ ] T041 [US1] Implement sequential execution mode in ToolDispatcherImpl in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T042 [US1] Implement parallel execution mode with semaphore (max 10 concurrent) in ToolDispatcherImpl in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T043 [US1] Implement mixed batch execution (sequential → parallel → sequential) preserving call order in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T044 [US1] Wire ToolDispatcher to use AgentToolRegistry in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T045 [US1] Export public API from lib/src/engine/tools.dart (re-export registry, dispatcher, entities)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Risk Tiers First-Class (Priority: P1)

**Goal**: First-class `safe | confirm | admin` risk metadata on tools; dispatch enforces approval callbacks for `confirm` and gates `admin` tools to internal missions only.

**Independent Test**: A `confirm` tool is not executed until the approval future resolves; timeout denies; `admin` tool denied on a user mission.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T046 [P] [US2] Unit test: confirm tool awaits approval callback in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T047 [P] [US2] Unit test: confirm tool timeout yields denied result in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T048 [P] [US2] Unit test: admin tool denied on non-internal mission in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T049 [P] [US2] Unit test: admin tool allowed on internal mission in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T050 [P] [US2] Unit test: safe tool executes immediately without callback in lib/src/engine/tool_dispatcher_impl_test.dart
- [ ] T051 [P] [US2] Integration test: Risk tier flow through dispatch in test/integration/risk_tier_integration_test.dart

### Implementation for User Story 2

- [ ] T052 [US2] Add riskTier field validation to AgentTool entity in lib/src/domain/entities/agent_tool/agent_tool.dart
- [ ] T053 [US2] Implement risk tier check in ToolDispatcherImpl.dispatch in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T054 [US2] Implement confirm risk handling: pause dispatch, call approvalCallback with ApprovalRequest in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T055 [US2] Implement confirm timeout (30s default, configurable per-tool) in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T056 [US2] Implement admin risk handling: check mission type, deny if not internal in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T057 [US2] Implement safe risk handling: immediate execution in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T058 [US2] Add mission context (isInternal) to ToolDispatcher interface and implementation in lib/src/engine/tool_dispatcher.dart, tool_dispatcher_impl.dart
- [ ] T059 [US2] Wire approvalCallback into ToolDispatcherImpl constructor/injection in lib/src/engine/tool_dispatcher_impl.dart

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Native MCP Client, Three Transports (Priority: P1)

**Goal**: MCP client over in-proc (registry-direct, zero IPC), SSE + Bearer with reconnect and auth callback, and stdio for dev tooling — achieving full client/server symmetry with zuraffa's McpSseServer.

**Independent Test**: Round-trip list + call against zuraffa's `McpSseServer` with Bearer auth, plus an in-proc host, plus a stdio server.

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T060 [P] [US3] Unit test: InProcTransport lists/calls tools without serialization in lib/src/mcp/transport/inproc_transport_test.dart
- [ ] T061 [P] [US3] Unit test: SseTransport connects, lists tools, calls tool in lib/src/mcp/transport/sse_transport_test.dart
- [ ] T062 [P] [US3] Unit test: SseTransport reconnects with exponential backoff on drop in lib/src/mcp/transport/sse_transport_test.dart
- [ ] T063 [P] [US3] Unit test: SseTransport rotates token via authCallback on 401 in lib/src/mcp/transport/sse_transport_test.dart
- [ ] T064 [P] [US3] Unit test: StdioTransport spawns process, calls tool, restarts on crash in lib/src/mcp/transport/stdio_transport_test.dart
- [ ] T065 [P] [US3] Integration test: Full SSE round-trip against zuraffa McpSseServer in test/integration/mcp_sse_integration_test.dart
- [ ] T066 [P] [US3] Integration test: In-proc transport round-trip in test/integration/mcp_inproc_integration_test.dart
- [ ] T067 [P] [US3] Integration test: Stdio transport round-trip in test/integration/mcp_stdio_integration_test.dart

### Implementation for User Story 3

- [ ] T068 [P] [US3] Implement McpTransport sealed class interface in lib/src/mcp/transport/transport.dart (connect, disconnect, listTools, callTool, onToolsChanged)
- [ ] T069 [P] [US3] Implement InProcTransport in lib/src/mcp/transport/inproc_transport.dart (direct registry calls, pass-by-reference with defensive copy)
- [ ] T070 [P] [US3] Implement SseTransport in lib/src/mcp/transport/sse_transport.dart (EventSource, JSON-RPC over SSE, reconnect state machine)
- [ ] T071 [P] [US3] Implement SseTransport reconnect logic with exponential backoff + jitter in lib/src/mcp/transport/sse_transport.dart
- [ ] T072 [P] [US3] Implement SseTransport auth callback integration (401 → callback → retry) in lib/src/mcp/transport/sse_transport.dart
- [ ] T073 [P] [US3] Implement StdioTransport in lib/src/mcp/transport/stdio_transport.dart (Process, stdin/stdout JSON-RPC, ping health check)
- [ ] T074 [P] [US3] Implement StdioTransport restart policy (max 3 retries, 1s/2s/4s backoff) in lib/src/mcp/transport/stdio_transport.dart
- [ ] T075 [P] [US3] Implement request queue for StdioTransport during restart in lib/src/mcp/transport/stdio_transport.dart
- [ ] T076 [US3] Implement McpClient facade in lib/src/mcp/mcp_client.dart (transport abstraction, auto-reconnect, tool listing cache)
- [ ] T077 [US3] Implement MCP protocol methods: initialize, tools/list, tools/call, ping, shutdown in lib/src/mcp/mcp_client.dart
- [ ] T078 [US3] Register MCP tools into AgentToolRegistry via McpClient in lib/src/mcp/mcp_client.dart
- [ ] T079 [US3] Export public MCP API from lib/src/mcp.dart (re-export client, transports, configs)

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Tool-Result Size Discipline (Priority: P2)

**Goal**: Oversized results (> 256 KB threshold) summarized with `artifactRef`; full body retrievable by artifact ID, never enters model context.

**Independent Test**: A tool returning 2 MB yields a structured summary + artifactRef in the model-facing result; the full body is retrievable by artifact id.

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T080 [P] [US4] Unit test: Result > 256KB produces summary + artifactRef in lib/src/artifact/artifact_service_test.dart
- [ ] T081 [P] [US4] Unit test: Result ≤ 256KB returns full content without artifactRef in lib/src/artifact/artifact_service_test.dart
- [ ] T082 [P] [US4] Unit test: ArtifactRef can fetch full body by ID in lib/src/artifact/in_memory_artifact_store_test.dart
- [ ] T083 [P] [US4] Integration test: Large tool result flows through dispatcher → artifactRef in test/integration/artifact_integration_test.dart

### Implementation for User Story 4

- [ ] T084 [US4] Implement size check in ToolDispatcherImpl after tool execution in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T085 [US4] Implement result summarization (truncate + metadata) in lib/src/artifact/artifact_service.dart
- [ ] T086 [US4] Implement ArtifactService.store with threshold check returning ArtifactRef in lib/src/artifact/artifact_service.dart
- [ ] T087 [US4] Implement ArtifactService.fetch by ArtifactRef in lib/src/artifact/artifact_service.dart
- [ ] T088 [US4] Wire ArtifactService into ToolDispatcherImpl in lib/src/engine/tool_dispatcher_impl.dart
- [ ] T089 [US4] Add thresholdBytes configuration to ArtifactService (default 256 KB) in lib/src/artifact/artifact_service.dart
- [ ] T090 [US4] Update ToolResult entity to include optional artifactRef in lib/src/domain/entities/tool_result/tool_result.dart
- [ ] T091 [US4] Run build_runner to generate updated Zorphy part files

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T092 [P] Documentation updates in docs/tools_and_mcp.md
- [ ] T093 Code cleanup and refactoring (remove dead code, improve naming)
- [ ] T094 Performance optimization: benchmark in-proc dispatch (< 1ms), SSE reconnect (< 500ms), 2MB summarization (< 10ms)
- [ ] T095 [P] Additional unit tests for edge cases in tests/unit/
- [ ] T096 Security hardening: validate all JSON-RPC inputs, sanitize tool arguments
- [ ] T097 Run quickstart.md validation scenarios (all 7 scenarios)
- [ ] T098 [P] Run dart analyze --fatal-infos and fix all warnings
- [ ] T099 [P] Run dart format --set-exit-if-changed .
- [ ] T100 Run full test suite: dart test

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 (dispatcher) and US2 (risk tiers) for full integration

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all P1 user stories can start in parallel
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test: AgentToolRegistry registers tools from all three sources in lib/src/engine/agent_tool_registry_test.dart"
Task: "Unit test: AgentToolRegistry resolves tools regardless of origin in lib/src/engine/agent_tool_registry_test.dart"
Task: "Unit test: AgentToolRegistry handles namespace collision with deterministic prefixing in lib/src/engine/agent_tool_registry_test.dart"
Task: "Unit test: ToolDispatcher validates arguments against JSON Schema in lib/src/engine/tool_dispatcher_impl_test.dart"
Task: "Unit test: ToolDispatcher dispatches parallel batch with results in call order in lib/src/engine/tool_dispatcher_impl_test.dart"
Task: "Integration test: Mission calls DDA + generated + MCP tools in single turn in test/integration/registry_integration_test.dart"

# Launch all implementation tasks for User Story 1 together:
Task: "Implement DDA tool registration API in lib/src/engine/agent_tool_registry.dart"
Task: "Implement generated tool registration API in lib/src/engine/agent_tool_registry.dart"
Task: "Implement MCP tool registration API in lib/src/engine/agent_tool_registry.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
3. Add User Story 3 → Test independently → Deploy/Demo
4. Add User Story 4 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently