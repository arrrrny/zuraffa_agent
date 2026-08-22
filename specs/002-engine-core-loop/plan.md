# Implementation Plan: Engine Core Loop

**Branch**: `002-engine-core-loop` | **Date**: 2026-08-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-engine-core-loop/spec.md`

**Note**: This template is filled in by the `/skill:speckit-plan` command; its definition describes the execution workflow.

## Summary

Implement the turn-based engine core loop that executes agent missions by driving conversations with LLMs, handling tool dispatch, preserving thinking blocks, supporting mid-mission steering, and enforcing safety rails. The loop is a while-loop on LLM finish-reason (no FSM; model drives), proven at 200+ sequential tool calls in Kimi. Uses Zorphy for all domain entities and pure Dart (no Flutter dependencies).

## Technical Context

**Language/Version**: Dart 3.8.0+

**Primary Dependencies**: Zorphy (required by Constitution IX), LlmClient interface (from spec 004), ported sources from dart_agent_core and pi_agent (both MIT)

**Storage**: Delegates to R2 session model from spec 002 for persistence; EngineLoop owns no persistence

**Testing**: Dart test framework (package:test ^1.25.0) with mocktail ^1.0.5 for mocking

**Target Platform**: Dart runtime platform-agnostic (desktop, server, web)

**Project Type**: Pure Dart package/library (no Flutter)

**Performance Goals**: Support 200+ sequential tool calls without state corruption; ensure event stream determinism

**Constraints**: No Flutter dependencies (Constitution VII), no dart:io usage in runtime paths, all entities via Zorphy (Constitution IX), attributed ports (Constitution VIII), pristine analyzer output post-build (Constitution X)

**Scale/Scope**: Engine core component for zuraffa ecosystem; foundational for mission execution, event streaming, and tool orchestration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. CLI-Built Only | ✅ PASS | Using speckit workflow for implementation |
| II. Stop on First Misfire | ✅ PASS | Will enforce pipeline halt on gate failures |
| III. Escalate Upstream and Wait | ✅ PASS | Will escalate framework defects to arrrrny/zuraffa |
| IV. Postmortem Every Misfire | ✅ PASS | Will document all misfires with precedent format |
| V. Gates Are Non-Negotiable | ✅ PASS | Will enforce all gates before advancing |
| VI. Probes Must Retain Evidence | ✅ PASS | Tests will retain evidence of all attempts |
| VII. Engine Purity | ✅ PASS | Pure Dart package, no Flutter dependencies |
| VIII. Attributed Ports | ✅ PASS | Will add MIT attribution for dart_agent_core and pi_agent ports |
| IX. Zorphy Is the Model Layer | ✅ PASS | All entities (EngineEvent, StopPolicy, EngineLoop state) will use Zorphy |
| X. Post-Build Analysis Must Be Pristine | ✅ PASS | Will ensure zero analyzer errors/warnings post-build |

**Gate Result**: ✅ PASS — All principles satisfied. Proceeding to Phase 0 research.

## Project Structure

### Documentation (this feature)

```text
specs/002-engine-core-loop/
├── plan.md              # This file (/skill:speckit-plan command output)
├── research.md          # Phase 0 output (/skill:speckit-plan command)
├── data-model.md        # Phase 1 output (/skill:speckit-plan command)
├── quickstart.md        # Phase 1 output (/skill:speckit-plan command)
├── contracts/           # Phase 1 output (/skill:speckit-plan command)
└── tasks.md             # Phase 2 output (/skill:speckit-tasks command - NOT created by /skill:speckit-plan)
```

### Source Code (repository root)

```text
lib/src/engine/
├── engine_loop.dart                 # Turn executor with while-loop on finish-reason
├── engine_event.dart                # Sealed hierarchy: mission/turn/tool/message lifecycle
├── stop_policy.dart                 # maxTurns, wall-clock, repetition detection
└── steering.dart                    # Mid-mission steering and follow-up message queues

lib/src/domain/entities/engine_event/
├── engine_event.zorphy.dart         # Zorphy entity definitions
├── engine_event.g.dart              # Generated serialization
└── engine_event.dart                # Public API

lib/src/domain/entities/stop_policy/
├── stop_policy.zorphy.dart          # Zorphy entity definitions
├── stop_policy.g.dart               # Generated serialization
└── stop_policy.dart                 # Public API

test/engine/
├── engine_loop_test.dart            # Turn execution, tool dispatch, loop safety
├── engine_event_test.dart           # Event streaming, sequence identifiers
├── stop_policy_test.dart            # Max turns, timeout, repetition detection
└── steering_test.dart               # Mid-mission steering, follow-up queues
```

**Structure Decision**: Following the existing zuraffa_agent architecture pattern where domain entities use Zorphy and live under `lib/src/domain/entities/`, while core logic (engine_loop, steering) lives under `lib/src/engine/`. Tests mirror the source structure under `test/engine/`. This maintains consistency with the existing codebase structure and adheres to Constitution IX (Zorphy for all entities).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations. All principles satisfied. Complexity tracking not required.

## Generated Artifacts

### Phase 0: Research

**Output**: [research.md](./research.md)

**Research Areas Resolved**:
1. Dart async patterns for event streaming → `Stream<T>` with `StreamController`
2. Stream-based architectures → Async function with internal state
3. Testing patterns → `package:test` + `mocktail` with `expectAsync`
4. Port integration → Algorithm porting with MIT attribution
5. Error handling → Try-catch with typed events

**Key Decisions**:
- Event streaming via `Stream<EngineEvent>` with sealed class hierarchy
- Loop structure as async function (no FSM per spec)
- Deterministic testing with mock providers
- Flutter-free Dart implementation with MIT attribution

### Phase 1: Design & Contracts

**Output**: [data-model.md](./data-model.md)

**Core Entities Defined**:
- `EngineEvent` - Sealed hierarchy of 9 event types (mission/turn/tool/message lifecycle)
- `StopPolicy` - Safety rails: maxTurns, wall-clock timeout, repetition detection
- `EngineLoop` - Turn executor with steering queue and state management
- Supporting entities: `ToolCallSignature`, `MissionConfig`, `TurnContext`

**Constitution Compliance**:
- ✅ All entities use Zorphy annotations (Principle IX)
- ✅ Pure Dart, no Flutter dependencies (Principle VII)
- ✅ MIT attribution for ported patterns (Principle VIII)

**Output**: [contracts/engine-api.md](./contracts/engine-api.md)

**Public API Contracts Defined**:
- `EngineLoop` class: `executeMission()`, `injectSteering()`, `abort()`
- `events` stream: Chronological lifecycle events with sequence identifiers
- Error handling: No exceptions, typed events only
- Integration contracts: With specs 002 (sessions), 003 (tools), 004 (providers)

**Output**: [quickstart.md](./quickstart.md)

**Validation Scenarios**:
1. 3-tool mission end-to-end (FR-001, SC-001)
2. Thinking preservation across turns (FR-002, US-2)
3. Mid-mission steering (FR-003, US-3, SC-002)
4. Loop safety rails (FR-004, US-4)
5. 200-call synthetic mission (US-1, SC-003)
6. Determinism across runs (SC-004)

**Edge Cases Covered**:
- Provider returns both content and tool calls
- Unknown tool references
- Abort during in-flight LLM stream
- Malformed tool arguments
- Provider disconnects mid-stream

### Constitution Re-Check Post-Design

| Principle | Status | Post-Design Verification |
|-----------|--------|------------------------|
| I. CLI-Built Only | ✅ PASS | Using speckit workflow; no manual scaffolding |
| II. Stop on First Misfire | ✅ PASS | Will enforce in implementation |
| III. Escalate Upstream and Wait | ✅ PASS | Ready for implementation escalation |
| IV. Postmortem Every Misfire | ✅ PASS | Will document any misfires |
| V. Gates Are Non-Negotiable | ✅ PASS | All gates satisfied; proceeding |
| VI. Probes Must Retain Evidence | ✅ PASS | Tests retain all attempt outputs |
| VII. Engine Purity | ✅ PASS | All entities pure Dart; no Flutter |
| VIII. Attributed Ports | ✅ PASS | MIT attribution ready for ported code |
| IX. Zorphy Is the Model Layer | ✅ PASS | All entities defined with Zorphy |
| X. Post-Build Analysis Must Be Pristine | ✅ PASS | Zero errors/warnings required |

**Gate Result**: ✅ PASS — Post-design constitution check complete. Ready for implementation.

## Next Steps

1. **Generate Tasks**: Run `/skill:speckit-tasks` to create `tasks.md` with actionable implementation steps
2. **Begin Implementation**: Execute tasks in dependency order
3. **Validate**: Run quickstart scenarios to verify acceptance criteria
4. **Post-Build Analysis**: Ensure zero analyzer errors/warnings (Constitution X)

## References

- Feature Specification: [spec.md](./spec.md)
- Research Findings: [research.md](./research.md)
- Data Model: [data-model.md](./data-model.md)
- API Contracts: [contracts/engine-api.md](./contracts/engine-api.md)
- Validation Guide: [quickstart.md](./quickstart.md)
- Constitution: [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
