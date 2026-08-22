# Tasks: Engine Core Loop

**Input**: Design documents from `/specs/002-engine-core-loop/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/engine-api.md, constitution.md

**Tests**: This feature specification requires comprehensive unit and integration tests as specified in spec.md user stories and acceptance scenarios.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Domain entities**: `lib/src/domain/entities/` with Zorphy annotations
- **Core logic**: `lib/src/engine/` for engine loop and steering
- **Tests**: `test/engine/` mirroring source structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Verify Dart SDK 3.8.0+ is installed and check dependencies in pubspec.yaml
- [x] T002 Verify Zorphy annotation dependency ^2.0.0 is in pubspec.yaml
- [x] T003 [P] Verify test dependencies: package:test ^1.25.0 and mocktail ^1.0.5 in pubspec.yaml
- [x] T004 [P] Verify build_runner ^2.16.0 dependency for Zorphy code generation in pubspec.yaml
- [x] T005 Create directory structure: lib/src/domain/entities/engine_event/, lib/src/domain/entities/stop_policy/, lib/src/engine/, test/engine/
- [x] T006 [P] Run `dart pub get` to ensure all dependencies are installed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Zorphy Entity Definitions (Core for all stories)

- [ ] T007 [P] Create EngineEvent base class and sealed hierarchy in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T008 [P] Create MissionStarted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T009 [P] Create MissionCompleted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T010 [P] Create TurnStarted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T011 [P] Create TurnCompleted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T012 [P] Create ThinkingDelta entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T013 [P] Create ToolCallStarted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T014 [P] Create ToolCallCompleted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T015 [P] Create ProviderError entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T016 [P] Create SteeringInjected entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
- [ ] T017 [P] Create StopPolicy entity in lib/src/domain/entities/stop_policy/stop_policy.zorphy.dart
- [ ] T018 [P] Create RepetitionTracker entity in lib/src/domain/entities/stop_policy/stop_policy.zorphy.dart
- [ ] T019 [P] Create ToolCallSignature entity in lib/src/domain/entities/tool_call_signature.zorphy.dart
- [ ] T020 [P] Create MissionConfig entity in lib/src/domain/entities/mission_config.zorphy.dart
- [ ] T021 [P] Create TurnContext entity in lib/src/domain/entities/turn_context.zorphy.dart
- [ ] T022 [P] Create EngineLoop entity in lib/src/domain/entities/engine_loop.zorphy.dart

### Public API Interfaces

- [ ] T023 Create EngineLoop public API class in lib/src/engine/engine_loop.dart with executeMission(), injectSteering(), abort() methods
- [ ] T024 [P] Create StopPolicy class in lib/src/engine/stop_policy.dart with defaultPolicy() and copyWith() methods
- [ ] T025 [P] Create steering module in lib/src/engine/steering.dart for queue management

### Code Generation and Validation

- [ ] T026 Run `dart run build_runner build --delete-conflicting-outputs` to generate Zorphy entity code
- [ ] T027 [P] Verify all .zorphy.dart files have corresponding .g.dart files generated
- [ ] T028 [P] Run `dart analyze` to verify zero analyzer errors and warnings (Constitution X compliance)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Agent completes a tool-driven mission (Priority: P1) 🎯 MVP

**Goal**: Implement turn-based while-loop that executes missions by calling LLMs, dispatching tools, and feeding results back until final answer.

**Independent Test**: A 3-tool mission (mock LLM, scriptable tools) completes end-to-end with the correct final message and full event stream.

### Tests for User Story 1

- [ ] T029 [P] [US1] Create test file test/engine/engine_loop_test.dart
- [ ] T030 [P] [US1] Write test "completes 3-tool mission with correct event sequence" in test/engine/engine_loop_test.dart
- [ ] T031 [P] [US1] Write test "handles provider returns both content and tool calls" in test/engine/engine_loop_test.dart
- [ ] T032 [P] [US1] Write test "handles 200-call synthetic mission without state corruption" in test/engine/engine_loop_test.dart
- [ ] T033 [P] [US1] Write test "produces deterministic event streams across 10 runs" in test/engine/engine_loop_test.dart
- [ ] T034 [P] [US1] Write test "handles unknown tool reference gracefully" in test/engine/engine_loop_test.dart

### Implementation for User Story 1

- [ ] T035 [P] [US1] Implement _executeTurn() method in lib/src/engine/engine_loop.dart for single turn execution
- [ ] T036 [P] [US1] Implement _processToolCalls() method in lib/src/engine/engine_loop.dart for tool dispatch
- [ ] T037 [P] [US1] Implement _assembleContext() method in lib/src/engine/engine_loop.dart for message context assembly
- [ ] T038 [US1] Implement executeMission() method in lib/src/engine/engine_loop.dart with while-loop on finish-reason (FR-001)
- [ ] T039 [US1] Add LlmClient integration in lib/src/engine/engine_loop.dart for provider communication
- [ ] T040 [US1] Add ToolDispatcher integration in lib/src/engine/engine_loop.dart for tool execution
- [ ] T041 [US1] Add event emission via StreamController in lib/src/engine/engine_loop.dart for all lifecycle events
- [ ] T042 [US1] Add MIT attribution header for pi_agent/dart_agent_core ported patterns in lib/src/engine/engine_loop.dart
- [ ] T043 [US1] Implement _emitEvent() helper method in lib/src/engine/engine_loop.dart for sequence number management
- [ ] T044 [US1] Add error handling with typed events in lib/src/engine/engine_loop.dart (no exceptions, FR-005)
- [ ] T045 [US1] Implement session storage delegation in lib/src/engine/engine_loop.dart for persistence (spec 002 integration)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Interleaved thinking is preserved (Priority: P1)

**Goal**: Preserve assistant thinking blocks in context alongside tool calls across turns.

**Independent Test**: A mission against a thinking-capable mock provider asserts thinking deltas appear in the session stream and thinking blocks persist into subsequent-turn context.

### Tests for User Story 2

- [ ] T046 [P] [US2] Write test "preserves thinking blocks in assistant messages" in test/engine/engine_loop_test.dart
- [ ] T047 [P] [US2] Write test "thinking deltas appear in event stream during turn" in test/engine/engine_loop_test.dart
- [ ] T048 [P] [US2] Write test "thinking blocks persist into subsequent turn context" in test/engine/engine_loop_test.dart

### Implementation for User Story 2

- [ ] T049 [P] [US2] Implement thinking delta streaming in lib/src/engine/engine_loop.dart for capturing thinking content
- [ ] T050 [US2] Add ThinkingDelta event emission in lib/src/engine/engine_loop.dart for each thinking chunk
- [ ] T051 [US2] Modify _assembleContext() in lib/src/engine/engine_loop.dart to preserve thinking blocks across turns (FR-002)
- [ ] T052 [US2] Ensure thinking blocks are not truncated or stripped in lib/src/engine/engine_loop.dart between turns

**Checkpoint**: At this point, User Story 2 should be fully functional and testable independently

---

## Phase 5: User Story 3 - Mid-mission steering (Priority: P2)

**Goal**: Enable mid-mission steering and follow-up message queues injected between turns.

**Independent Test**: Steering message enqueued during turn 2 of a 4-turn mission alters the tool choices of turn 3+.

### Tests for User Story 3

- [ ] T053 [P] [US3] Create test file test/engine/steering_test.dart
- [ ] T054 [P] [US3] Write test "injects steering message mid-mission" in test/engine/steering_test.dart
- [ ] T055 [P] [US3] Write test "steering queue processes messages in FIFO order" in test/engine/steering_test.dart
- [ ] T056 [P] [US3] Write test "follow-up messages continue mission after normal completion" in test/engine/steering_test.dart
- [ ] T057 [P] [US3] Write test "throws StateError when steering injected after mission completion" in test/engine/steering_test.dart

### Implementation for User Story 3

- [ ] T058 [P] [US3] Implement steering queue management in lib/src/engine/steering.dart (FIFO processing)
- [ ] T059 [US3] Implement injectSteering() method in lib/src/engine/engine_loop.dart for adding messages to queue
- [ ] T060 [US3] Add SteeringInjected event emission in lib/src/engine/engine_loop.dart for each injection
- [ ] T061 [US3] Modify _assembleContext() in lib/src/engine/engine_loop.dart to inject steering before next LLM invocation
- [ ] T062 [US3] Add follow-up message handling in lib/src/engine/engine_loop.dart to continue mission after completion
- [ ] T063 [US3] Add state validation in lib/src/engine/engine_loop.dart to prevent steering after completion

**Checkpoint**: At this point, User Story 3 should be fully functional and testable independently

---

## Phase 6: User Story 4 - Loop safety rails (Priority: P2)

**Goal**: Enforce max-turns, wall-clock timeout, and repetition detection to abort runaway loops.

**Independent Test**: A looping mock (always same tool call) trips the repetition detector within the configured threshold and emits a typed LoopDetected failure.

### Tests for User Story 4

- [ ] T064 [P] [US4] Create test file test/engine/stop_policy_test.dart
- [ ] T065 [P] [US4] Write test "enforces max turns limit and emits MaxTurnsExceeded" in test/engine/stop_policy_test.dart
- [ ] T066 [P] [US4] Write test "enforces wall-clock timeout and emits timeout outcome" in test/engine/stop_policy_test.dart
- [ ] T067 [P] [US4] Write test "detects repetitive tool calls and emits LoopDetected" in test/engine/stop_policy_test.dart
- [ ] T068 [P] [US4] Write test "StopPolicy defaultPolicy() returns correct defaults" in test/engine/stop_policy_test.dart
- [ ] T069 [P] [US4] Write test "StopPolicy copyWith() creates immutable copies" in test/engine/stop_policy_test.dart

### Implementation for User Story 4

- [ ] T070 [P] [US4] Implement max turns enforcement in lib/src/engine/stop_policy.dart with StopPolicy entity
- [ ] T071 [P] [US4] Implement wall-clock timeout tracking in lib/src/engine/stop_policy.dart with StopPolicy entity
- [ ] T072 [P] [US4] Implement repetition detection logic in lib/src/engine/stop_policy.dart with RepetitionTracker entity
- [ ] T073 [US4] Create ToolCallSignature normalization in lib/src/domain/entities/tool_call_signature.dart for repetition detection
- [ ] T074 [US4] Integrate StopPolicy checks in lib/src/engine/engine_loop.dart before each turn execution
- [ ] T075 [US4] Add typed MissionCompleted events for all failure outcomes in lib/src/engine/engine_loop.dart (max_turns_exceeded, timeout, loop_detected)
- [ ] T076 [US4] Implement StopPolicy.defaultPolicy() factory in lib/src/engine/stop_policy.dart
- [ ] T077 [US4] Implement StopPolicy.copyWith() method in lib/src/engine/stop_policy.dart for immutable configuration

**Checkpoint**: At this point, User Story 4 should be fully functional and testable independently

---

## Phase 7: User Story 5 - Typed streaming events (Priority: P1)

**Goal**: Provide typed lifecycle events for UI layer consumption with sequence identifiers.

**Independent Test**: Every acceptance scenario above is verified through the event stream alone.

### Tests for User Story 5

- [ ] T078 [P] [US5] Create test file test/engine/engine_event_test.dart
- [ ] T079 [P] [US5] Write test "events carry monotonically increasing sequence numbers" in test/engine/engine_event_test.dart
- [ ] T080 [P] [US5] Write test "events are emitted in chronological order" in test/engine/engine_event_test.dart
- [ ] T081 [P] [US5] Write test "all event types appear in correct sequence during mission" in test/engine/engine_event_test.dart
- [ ] T082 [P] [US5] Write test "stream completes after MissionCompleted event" in test/engine/engine_event_test.dart
- [ ] T083 [P] [US5] Write test "multiple consumers can subscribe to events stream" in test/engine/engine_event_test.dart

### Implementation for User Story 5

- [ ] T084 [P] [US5] Create public API wrapper for events stream in lib/src/domain/entities/engine_event/engine_event.dart
- [ ] T085 [US5] Implement sequence number management in lib/src/engine/engine_loop.dart for total ordering
- [ ] T086 [US5] Ensure all event types are emitted in correct order in lib/src/engine/engine_loop.dart (FR-005)
- [ ] T087 [US5] Add event stream lifecycle management in lib/src/engine/engine_loop.dart (proper closing on completion)
- [ ] T088 [US5] Implement broadcast capabilities for events stream in lib/src/engine/engine_loop.dart for multiple consumers

**Checkpoint**: At this point, User Story 5 should be fully functional and testable independently

---

## Phase 8: Edge Cases & Error Handling

**Purpose**: Handle edge cases and ensure robust error handling across all user stories.

### Edge Case Tests

- [ ] T089 [P] Write test "handles abort during in-flight LLM stream" in test/engine/engine_loop_test.dart
- [ ] T090 [P] Write test "handles malformed tool arguments gracefully" in test/engine/engine_loop_test.dart
- [ ] T091 [P] Write test "handles provider disconnect mid-stream with clean termination" in test/engine/engine_loop_test.dart
- [ ] T092 [P] Write test "maintains session resumability after errors" in test/engine/engine_loop_test.dart

### Edge Case Implementation

- [ ] T093 Implement abort() method in lib/src/engine/engine_loop.dart with stream cancellation and resource cleanup
- [ ] T094 Add malformed argument validation in lib/src/engine/engine_loop.dart with detailed error messages
- [ ] T095 Implement provider disconnect handling in lib/src/engine/engine_loop.dart with typed ProviderError events
- [ ] T096 Ensure session state consistency after errors in lib/src/engine/engine_loop.dart (last complete turn)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories.

- [ ] T097 [P] Run comprehensive test suite: `dart test test/engine/` and verify all tests pass
- [ ] T098 [P] Run determinism tests 10 times to verify identical event streams (SC-004 validation)
- [ ] T099 [P] Run `dart analyze` and ensure zero analyzer errors and warnings (Constitution X compliance)
- [ ] T100 [P] Verify no Flutter dependencies in pubspec.yaml (Constitution VII compliance)
- [ ] T101 [P] Verify all ported code has MIT attribution headers (Constitution VIII compliance)
- [ ] T102 [P] Verify all entities use Zorphy annotations (Constitution IX compliance)
- [ ] T103 Run quickstart.md validation scenarios to verify all acceptance criteria
- [ ] T104 [P] Check for memory leaks or unbounded growth in long-running missions
- [ ] T105 [P] Verify event stream completeness (no missing events) in 200-call mission test
- [ ] T106 [P] Test integration with spec 002 session storage
- [ ] T107 [P] Test integration with spec 003 tool dispatcher
- [ ] T108 [P] Test integration with spec 004 LlmClient providers

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1 → US2 → US5 → US3 → US4)
- **Edge Cases (Phase 8)**: Depends on US1, US3, US4 completion
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (US1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (US2)**: Can start after Foundational - Extends US1 but independently testable
- **User Story 5 (US5)**: Can start after Foundational - Extends US1 but independently testable
- **User Story 3 (US3)**: Can start after Foundational - Independent, but builds on US1 patterns
- **User Story 4 (US4)**: Can start after Foundational - Independent safety rails

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Entity definitions before API implementation
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational entity creation tasks marked [P] can run in parallel
- Within US1: Test setup (T029-T034) can run in parallel
- Within US2: Tests (T046-T048) can run in parallel
- Within US3: Tests (T054-T057) can run in parallel
- Within US4: Tests (T065-T069) can run in parallel
- Within US5: Tests (T079-T083) can run in parallel
- Within Edge Cases: Tests (T089-T092) can run in parallel
- Within Polish: Validation tasks (T099-T108) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all entity creation tasks together:
Task: T007 Create EngineEvent base class in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
Task: T008 Create MissionStarted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
Task: T009 Create MissionCompleted entity in lib/src/domain/entities/engine_event/engine_event.zorphy.dart
# ... etc for all entity creation

# Launch all test setup tasks together:
Task: T029 Create test file test/engine/engine_loop_test.dart
Task: T030 Write test "completes 3-tool mission" in test/engine/engine_loop_test.dart
Task: T031 Write test "handles content and tool calls together" in test/engine/engine_loop_test.dart
# ... etc for all test tasks

# Launch implementation tasks in sequence:
Task: T035 Implement _executeTurn() in lib/src/engine/engine_loop.dart
Task: T036 Implement _processToolCalls() in lib/src/engine/engine_loop.dart
Task: T037 Implement _assembleContext() in lib/src/engine/engine_loop.dart
# ... then
Task: T038 Implement executeMission() with while-loop in lib/src/engine/engine_loop.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T028) - **CRITICAL - blocks all stories**
3. Complete Phase 3: User Story 1 (T029-T045)
4. **STOP and VALIDATE**: Run 3-tool mission test and verify independent functionality
5. Demo MVP: Basic mission execution with tool dispatch

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Demo MVP
3. Add User Story 2 → Test independently → Extend with thinking preservation
4. Add User Story 5 → Test independently → Add typed event streaming
5. Add User Story 3 → Test independently → Add mid-mission steering
6. Add User Story 4 → Test independently → Add safety rails
7. Complete Edge Cases & Polish → Full feature delivery

### Priority Order (Recommended)

1. **P1 Stories First**: US1 → US2 → US5 (core functionality)
2. **P2 Stories Second**: US3 → US4 (enhanced capabilities)
3. Each story adds value without breaking previous stories

---

## Acceptance Criteria Coverage

### User Story 1 - Agent completes a tool-driven mission
- ✅ T030: 3-tool mission completes end-to-end (SC-001)
- ✅ T032: 200-call mission without corruption (SC-003)
- ✅ T033: Deterministic event streams (SC-004)
- ✅ T038: Turn-based while-loop (FR-001)
- ✅ T044: Typed error events (FR-005)

### User Story 2 - Interleaved thinking is preserved
- ✅ T046: Thinking blocks in assistant messages
- ✅ T047: Thinking deltas in event stream
- ✅ T048: Thinking blocks persist across turns
- ✅ T051: Context assembly preserves thinking (FR-002)

### User Story 3 - Mid-mission steering
- ✅ T054: Steering message injection mid-mission
- ✅ T055: FIFO queue processing
- ✅ T056: Follow-up messages continue mission
- ✅ T059: injectSteering() method (FR-003)

### User Story 4 - Loop safety rails
- ✅ T065: Max turns enforcement (FR-004)
- ✅ T066: Wall-clock timeout (FR-004)
- ✅ T067: Repetition detection (FR-004)
- ✅ T075: Typed failure outcomes

### User Story 5 - Typed streaming events
- ✅ T080: Chronological event ordering
- ✅ T081: All event types in sequence
- ✅ T083: Multiple consumer support
- ✅ T086: Monotonic sequence numbers (FR-005)

---

## Notes

- All entities use Zorphy annotations per Constitution IX
- No Flutter dependencies per Constitution VII
- MIT attribution for ported patterns per Constitution VIII
- Zero analyzer errors/warnings required per Constitution X
- Tests use package:test ^1.25.0 and mocktail ^1.0.5
- Event streaming uses Dart's Stream<T> with StreamController
- Each user story is independently completable and testable
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently