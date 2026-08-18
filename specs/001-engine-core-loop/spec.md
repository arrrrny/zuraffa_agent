# Feature Specification: Engine Core Loop

**Feature Branch**: `001-engine-core-loop`

**Created**: 2026-08-18

**Status**: Draft

**Input**: Epic arrrrny/zuraffa_agent#1 §R1 — converted from issue #2. This spec is the conversion of that issue into spec-driven form; the issue remains the tracking surface.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Agent completes a tool-driven mission (Priority: P1)

As a consuming app, I submit messages + tools to the engine and the engine drives turns autonomously — calling the LLM, dispatching tool calls, feeding results back — until the model produces a final answer. The loop is a turn-based while-loop on finish-reason (no FSM; model drives; Kimi pattern proven at 200+ sequential tool calls).

**Why this priority**: This is the engine's reason to exist; every other story builds on a working loop.

**Independent Test**: A 3-tool mission (mock LLM, scriptable tools) completes end-to-end with the correct final message and full event stream — testable with zero other engine subsystems beyond types.

**Acceptance Scenarios**:

1. **Given** a mission with tools available, **When** the LLM returns `tool_calls`, **Then** the engine dispatches each call, appends result messages, and re-invokes the LLM until a non-tool finish reason.
2. **Given** a scripted 200-call mission, **When** executed, **Then** it completes without state corruption or event loss.
3. **Given** the same inputs and a recorded LLM, **When** re-run 10×, **Then** the event stream is byte-identical (determinism).

### User Story 2 - Interleaved thinking is preserved (Priority: P1)

As the engine, I keep assistant thinking blocks in context alongside tool calls — never stripped between turns (Kimi evidence: dropping them degrades browse-style tasks ~40%).

**Why this priority**: Harness correctness for thinking-capable models (Kimi K2 Thinking class); silently discarding reasoning cripples long missions.

**Independent Test**: A mission against a thinking-capable mock provider asserts thinking deltas appear in the session stream and thinking blocks persist into subsequent-turn context.

**Acceptance Scenarios**:

1. **Given** a provider streaming thinking deltas, **When** a turn completes, **Then** the assistant message carries thinking blocks next to tool calls.
2. **Given** a multi-turn mission, **When** turn N+1's context is assembled, **Then** prior turns' thinking blocks are present.

### User Story 3 - Mid-mission steering (Priority: P2)

As a user, I inject guidance mid-mission (pi-mono steering/follow-up pattern) and the engine applies it between turns without restart or state loss.

**Why this priority**: Enables human-in-the-loop corrections (confirmations, redirects) without mission restarts.

**Independent Test**: Steering message enqueued during turn 2 of a 4-turn mission alters the tool choices of turn 3+.

**Acceptance Scenarios**:

1. **Given** a running mission, **When** a steering message is enqueued, **Then** it is injected before the next LLM call.
2. **Given** follow-up messages queued at mission end, **When** the loop checks stop conditions, **Then** the loop continues with the follow-ups instead of exiting.

### User Story 4 - Loop safety rails (Priority: P2)

As the engine operator, I bound every mission: max-turns, wall-clock timeout, and repetition detection abort runaway loops with typed failure events.

**Why this priority**: Agent loops without rails hang and burn budget.

**Independent Test**: A looping mock (always same tool call) trips the repetition detector within the configured threshold and emits a typed `LoopDetected` failure.

**Acceptance Scenarios**:

1. **Given** maxTurns=5, **When** the model never stops calling tools, **Then** the mission ends with a `MaxTurnsExceeded` outcome after turn 5.
2. **Given** identical repeated tool calls, **When** the threshold is hit, **Then** `LoopDetected` fires and the mission aborts cleanly.

### User Story 5 - Typed streaming events (Priority: P1)

As the UI layer, I consume the mission as typed lifecycle events — thinking delta, tool call start/update/end, turn boundaries — decoupled from any transport (wire-protocol pattern).

**Why this priority**: The kernel host, mission UI, and trace recorder all consume this stream.

**Independent Test**: Every acceptance scenario above is verified through the event stream alone.

**Acceptance Scenarios**:

1. **Given** any running mission, **When** events occur, **Then** consumers receive them in order with monotonic turn/sequence identifiers.

### Edge Cases

- Provider returns both final content and tool calls in one message → both honored (content recorded, tools dispatched).
- Tool call references an unknown tool → typed tool-error result is fed back to the model, mission continues.
- Abort during an in-flight LLM stream → stream cancelled, partial turn discarded, session left resumable.
- Empty tool-call arguments / malformed JSON → validation error returned as tool result, never a crash.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST implement a turn-based while-loop advancing on LLM finish-reason, with no external state machine.
- **FR-002**: Assistant messages MUST carry thinking blocks alongside tool calls; context assembly MUST preserve them across turns.
- **FR-003**: The engine MUST support steering and follow-up message queues injected between turns.
- **FR-004**: The engine MUST enforce max-turns, wall-clock timeout, and repetition-detection aborts with typed outcome events.
- **FR-005**: The engine MUST emit every lifecycle event as a typed, ordered stream with sequence identifiers.
- **FR-006**: The loop design MUST follow pi-mono's `agent-loop.ts` reference (turn-based, injectable behavior callbacks); pi_agent's loop stub is completed, not kept.

### Key Entities

- **EngineLoop**: the turn executor; owns no persistence (delegates to R2 session model, spec 002).
- **EngineEvent**: sealed hierarchy — mission/turn/tool/message lifecycle events.
- **StopPolicy**: maxTurns, wall-clock, repetition threshold; produces typed outcomes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 3-tool mission streams every event type; interleaved thinking preserved in the session tree (issue #2 AC).
- **SC-002**: Steering input mid-mission alters course without restart (AC).
- **SC-003**: 200-call synthetic mission completes without state corruption (AC).
- **SC-004**: Determinism — same inputs + recorded LLM produce identical event streams across 10 runs (AC).

## Assumptions

- Types are shared with spec 002 (pi_agent seed lands first); this spec consumes them.
- Provider abstraction comes from spec 004; loop is provider-agnostic via `LlmClient` interface.
- Tool dispatch mechanics come from spec 003; the loop only selects and forwards calls.

## Dependencies

- Issue: arrrrny/zuraffa_agent#2 · Epic: #1 · Feeds: zuraffa kernel host (arrrrny/zuraffa#386) · Pairs: specs 002–006 · Design: arrrrny/zik_zak `docs/architecture/zikzak-ai-agent-architecture.md` §14.7
