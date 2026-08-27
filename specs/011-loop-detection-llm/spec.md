# Feature Specification: Loop Detection (LLM-based)

**Feature Branch**: `011-loop-detection-llm`

**Created**: 2026-08-27

**Status**: Approved *(refined by /speckit.specify — added acceptance-criterion ids AC-1..AC-6; mapped the draft's `ModelMessage` onto this engine's `AgentMessage` model (tool calls live in `AssistantMessage.content` as `ToolCallBlock`s); pinned the tool-call signature contract (name + argument map, key-order-insensitive, call-id-insensitive), the streak semantics (a different signature resets; intervening tool-result/user messages do not), the stagnation-diagnosis cadence (first check at llmCheckAfterTurns, then every llmCheckInterval turns), and the fail-open diagnosis contract (unparseable LLM output never stops a mission)*

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has basic StopPolicy (maxTurns, timeout, repetition) but no LLM-based cognitive stagnation detection.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tool call loop detection (Priority: P1)

As the engine, I detect when the model repeats the same tool call with the same arguments multiple times in succession, indicating a loop.

**Why this priority**: Tool loops waste tokens and can hang missions indefinitely.

**Independent Test**: A model that calls `read_file("lib/a.dart")` 5 times in a row is detected as looping.

**Acceptance Scenarios**:

1. **Given** the same tool call signature (name + arguments) repeated `toolLoopThreshold` times in succession, **When** the threshold is reached, **Then** a loop is detected (isLoop=true, reason "tool_call_loop", confidence 1.0) and the mission should stop. **[AC-1]**
2. **Given** a tool-call streak interrupted by a *different* tool call, **When** the different call is observed, **Then** the streak resets and no loop is detected from the earlier run. **[AC-2]**
3. **Given** tool-result or user messages interleaved between identical tool calls, **When** the detector observes them, **Then** they do not reset the streak (a call→result→call→result chain still accumulates). **[AC-3]**

### User Story 2 - LLM-based stagnation detection (Priority: P1)

As the engine, after a configurable number of turns, I periodically send recent history to an LLM to diagnose whether the agent is stuck in cognitive stagnation (repeating reasoning, making no progress).

**Why this priority**: Some loops are subtle — the model repeats reasoning patterns without obvious tool call repetition.

**Independent Test**: A model that generates similar reasoning blocks for 30+ turns without progress is detected as stagnant.

**Acceptance Scenarios**:

1. **Given** llmCheckAfterTurns=30, **When** 30 turns pass, **Then** an LLM diagnosis is triggered (exactly one LLM call at the boundary). **[AC-4]**
2. **Given** the LLM diagnoses stagnation with confidence > stagnationThreshold (default 0.8), **When** the diagnosis returns, **Then** the loop is detected and the mission stops. **[AC-5]**
3. **Given** a diagnosis below the confidence threshold, **When** it returns, **Then** the mission continues normally (no detection). **[AC-6]**

### User Story 3 - Configurable thresholds (Priority: P2)

As an operator, I configure the loop detection parameters: tool call repetition threshold, LLM check interval, and stagnation confidence threshold.

**Why this priority**: Different missions have different loop characteristics.

**Independent Test**: Changing toolLoopThreshold from 5 to 3 makes detection more aggressive.

**Acceptance Scenarios**:

1. **Given** custom thresholds, **When** detection runs, **Then** the configured thresholds are used. **[AC-1/AC-4/AC-6 with non-default settings]**

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST detect tool call loops by tracking recent call signatures.
- **FR-002**: The engine MUST detect cognitive stagnation via periodic LLM diagnosis.
- **FR-003**: LLM diagnosis MUST be triggered after a configurable number of turns.
- **FR-004**: Stagnation detection MUST use a confidence threshold (default 0.8).
- **FR-005**: Detection parameters MUST be configurable.

### Key Entities

- **LoopDetector** (interface): `Future<LoopDetectorResult> observe(AgentMessage message)` — one call per message as the conversation progresses (the draft's `detect(ModelMessage)` mapped onto the engine's AgentMessage model).
- **DefaultLoopDetector**: tool-loop streak tracking + LLM-based stagnation diagnosis (uses the spec-007 `LlmClient` contract).
- **LoopDetectorResult**: isLoop, reason, confidence (+ turnNumber at observation time).
- **LoopDetectorConfig**: toolLoopThreshold (default 5), llmCheckAfterTurns (default 30), llmCheckInterval (default 5), stagnationThreshold (default 0.8), plus diagnosisWindowMessages (default 20 — how much recent history the diagnosis prompt carries).
- **Tool call signature**: tool name + JSON-normalized argument map (sorted keys — key-order-insensitive; call `id` excluded — every engine call gets a fresh id, so the loop signal is name+arguments).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 5 identical tool calls are detected as a loop (default threshold).
- **SC-002**: 30+ turns of stagnation are detected via LLM diagnosis (scripted stagnation verdict).
- **SC-003**: False positives are below 5% on non-stagnant missions — pinned deterministically: 50 varied tool calls and 50 varied assistant turns with non-stagnant diagnoses produce zero detections.
- **SC-004**: `dart analyze` reports zero issues in files added by this feature; the full suite adds no new failures vs. the spec-010 baseline (+469 passed / 6 unrelated pre-existing loading failures).

## Dependencies

- After: spec 007 (LLM clients for stagnation diagnosis)
- Feeds: spec 002 (engine loop uses loop detector)

## Assumptions

- "Turn" = one assistant message; the engine will call `observe()` once per message (spec 002 wires the engine integration; this spec ships the detector).
- The stagnation diagnosis prompt asks the LLM for a JSON verdict `{"isStagnant": bool, "confidence": number, "reason": string}`; a verdict that fails to parse is fail-open (no detection, error surfaced on the result) — a malformed diagnosis must never stop a mission by itself.
- The LLM client is optional at construction: without one, DefaultLoopDetector still performs tool-loop detection (pure heuristic path) and never triggers a diagnosis.
- Stagnation checks repeat every `llmCheckInterval` turns after the first `llmCheckAfterTurns` boundary; a stagnation hit is terminal (the detector keeps reporting the detection on subsequent observations until reset).
- The detector holds no `dart:io` dependencies (constitution VII) and carries dart_agent_core-lineage attribution (VIII).
