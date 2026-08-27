# Feature Specification: Loop Detection (LLM-based)

**Feature Branch**: `011-loop-detection-llm`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has basic StopPolicy (maxTurns, timeout, repetition) but no LLM-based cognitive stagnation detection.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tool call loop detection (Priority: P1)

As the engine, I detect when the model repeats the same tool call with the same arguments multiple times in succession, indicating a loop.

**Why this priority**: Tool loops waste tokens and can hang missions indefinitely.

**Independent Test**: A model that calls `read_file("lib/a.dart")` 5 times in a row is detected as looping.

**Acceptance Scenarios**:

1. **Given** the same tool call (name + args) repeated N times, **When** the threshold is reached, **Then** a loop is detected and the mission stops.

### User Story 2 - LLM-based stagnation detection (Priority: P1)

As the engine, after a configurable number of turns, I periodically send recent history to an LLM to diagnose whether the agent is stuck in cognitive stagnation (repeating reasoning, making no progress).

**Why this priority**: Some loops are subtle — the model repeats reasoning patterns without obvious tool call repetition.

**Independent Test**: A model that generates similar reasoning blocks for 30+ turns without progress is detected as stagnant.

**Acceptance Scenarios**:

1. **Given** llmCheckAfterTurns=30, **When** 30 turns pass, **Then** an LLM diagnosis is triggered.
2. **Given** the LLM diagnoses stagnation with confidence > 0.8, **When** the diagnosis returns, **Then** the loop is detected and the mission stops.
3. **Given** a diagnosis below the confidence threshold, **When** it returns, **Then** the mission continues normally.

### User Story 3 - Configurable thresholds (Priority: P2)

As an operator, I configure the loop detection parameters: tool call repetition threshold, LLM check interval, and stagnation confidence threshold.

**Why this priority**: Different missions have different loop characteristics.

**Independent Test**: Changing toolLoopThreshold from 5 to 3 makes detection more aggressive.

**Acceptance Scenarios**:

1. **Given** custom thresholds, **When** detection runs, **Then** the configured thresholds are used.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST detect tool call loops by tracking recent call signatures.
- **FR-002**: The engine MUST detect cognitive stagnation via periodic LLM diagnosis.
- **FR-003**: LLM diagnosis MUST be triggered after a configurable number of turns.
- **FR-004**: Stagnation detection MUST use a confidence threshold (default 0.8).
- **FR-005**: Detection parameters MUST be configurable.

### Key Entities

- **LoopDetector** (interface): detect(ModelMessage) → LoopDetectorResult
- **DefaultLoopDetector**: tool-loop + LLM-based detection
- **LoopDetectorResult**: isLoop, reason, confidence
- **LoopDetectorConfig**: toolLoopThreshold, llmCheckAfterTurns, llmCheckInterval, stagnationThreshold

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 5 identical tool calls are detected as a loop.
- **SC-002**: 30+ turns of stagnation are detected via LLM diagnosis.
- **SC-003**: False positives are below 5% on non-stagnant missions.

## Dependencies

- After: spec 007 (LLM clients for stagnation diagnosis)
- Feeds: spec 002 (engine loop uses loop detector)
