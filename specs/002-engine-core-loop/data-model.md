# Data Model: Engine Core Loop

**Feature**: 002-engine-core-loop  
**Date**: 2026-08-18  
**Status**: Complete

## Entity Overview

This document defines the domain entities for the engine core loop, following Constitution IX (Zorphy for all entities). All entities use Zorphy annotations and are generated with `.zorphy.dart` and `.g.dart` files.

## Core Entities

### EngineEvent

**Purpose**: Sealed hierarchy of lifecycle events emitted during mission execution, providing typed, ordered event stream for UI layer, kernel host, and trace recorder.

**Zorphy Entity**: `engine_event.zorphy.dart`

**Fields**:
```dart
@ZorphyEntity()
class EngineEvent {
  final String eventId;              // Unique identifier for event
  final int sequenceNumber;          // Monotonically increasing sequence ID
  final DateTime timestamp;          // Event occurrence time
  final String missionId;            // Associated mission identifier
}

// Subtypes (sealed classes in Dart 3)

@ZorphyEntity()
class MissionStarted extends EngineEvent {
  final String missionId;
  final Map<String, dynamic> config; // Mission configuration
}

@ZorphyEntity()
class MissionCompleted extends EngineEvent {
  final String outcome;              // "success", "max_turns_exceeded", "timeout", "loop_detected", "error"
  final String? errorMessage;        // Error details if applicable
  final int totalTurns;              // Total turns executed
}

@ZorphyEntity()
class TurnStarted extends EngineEvent {
  final int turnNumber;              // Current turn number (1-indexed)
  final List<String> messageIds;     // Message IDs in context for this turn
}

@ZorphyEntity()
class TurnCompleted extends EngineEvent {
  final int turnNumber;
  final String finishReason;         // "stop", "tool_calls", "length", "error"
  final int toolCallCount;           // Number of tool calls in this turn
}

@ZorphyEntity()
class ThinkingDelta extends EngineEvent {
  final String content;              // Thinking content delta
  final int deltaIndex;              // Delta index within turn
  final bool isComplete;             // Whether thinking block is complete
}

@ZorphyEntity()
class ToolCallStarted extends EngineEvent {
  final String toolCallId;           // Unique tool call identifier
  final String toolName;             // Tool being called
  final Map<String, dynamic> arguments; // Tool arguments
  final int callIndex;               // Index within turn's tool calls
}

@ZorphyEntity()
class ToolCallCompleted extends EngineEvent {
  final String toolCallId;
  final String result;               // Tool result (success/error)
  final String? errorMessage;        // Error details if failed
  final int durationMs;              // Execution duration
}

@ZorphyEntity()
class ProviderError extends EngineEvent {
  final String errorType;            // "timeout", "disconnected", "rate_limit", etc.
  final String message;              // Error message
  final bool isRecoverable;          // Whether error can be retried
}

@ZorphyEntity()
class SteeringInjected extends EngineEvent {
  final String messageId;            // ID of injected steering message
  final String content;              // Steering message content
  final int injectionPoint;          // Turn number where injected
}
```

**Validation Rules**:
- `sequenceNumber` must be monotonically increasing across all events
- `eventId` must be unique within mission scope
- `turnNumber` must be >= 1 and <= maxTurns
- `toolCallId` must be unique within turn scope
- `outcome` must be one of: "success", "max_turns_exceeded", "timeout", "loop_detected", "error"

**State Transitions**:
```
MissionStarted → (TurnStarted → TurnCompleted)* → MissionCompleted
              → (ToolCallStarted → ToolCallCompleted)*
              → ThinkingDelta*
              → SteeringInjected*
              → ProviderError → MissionCompleted (error outcome)
```

### StopPolicy

**Purpose**: Enforces safety rails for mission execution, including max-turns, wall-clock timeout, and repetition detection.

**Zorphy Entity**: `stop_policy.zorphy.dart`

**Fields**:
```dart
@ZorphyEntity()
class StopPolicy {
  final int maxTurns;                // Maximum turns before abort (default: 100)
  final Duration wallClockTimeout;   // Maximum wall-clock time (default: 5 minutes)
  final int repetitionThreshold;     // Max identical tool calls before abort (default: 3)
  final bool enabled;                // Whether policy is enforced
}

@ZorphyEntity()
class RepetitionTracker {
  final Map<String, int> callSignatures; // Tool signature -> occurrence count
  final List<String> recentCalls;        // Recent tool call signatures (for sliding window)
}
```

**Validation Rules**:
- `maxTurns` must be >= 1
- `wallClockTimeout` must be >= 1 second
- `repetitionThreshold` must be >= 2 (to detect actual repetition, not single calls)

**Behavior**:
- Emits `MissionCompleted(outcome: "max_turns_exceeded")` when turn count exceeds `maxTurns`
- Emits `MissionCompleted(outcome: "timeout")` when wall-clock time exceeds `wallClockTimeout`
- Emits `MissionCompleted(outcome: "loop_detected")` when identical tool calls exceed `repetitionThreshold`

### EngineLoop

**Purpose**: Turn executor that drives missions by invoking LLMs, dispatching tools, preserving thinking, and enforcing stop policies. Owns no persistence (delegates to R2 session model).

**Zorphy Entity**: `engine_loop.zorphy.dart`

**Fields**:
```dart
@ZorphyEntity()
class EngineLoop {
  final String loopId;               // Unique loop identifier
  final String sessionId;            // Associated session ID (from spec 002)
  final StopPolicy stopPolicy;       // Safety rails configuration
  final List<String> steeringQueue;  // Pending steering/follow-up messages
  final RepetitionTracker repetitionTracker; // For loop detection
}

@ZorphyEntity()
class TurnContext {
  final int turnNumber;              // Current turn number
  final List<String> messageIds;     // Message IDs in context
  final DateTime turnStartTime;      // Turn start time
  final List<String> toolCallIds;    // Tool calls dispatched this turn
}
```

**Validation Rules**:
- `sessionId` must reference a valid session from spec 002
- `turnNumber` starts at 1 and increments monotonically
- `steeringQueue` messages are processed in FIFO order

**Behavior**:
- Executes turn-based while-loop on LLM finish-reason
- Emits `EngineEvent` for each lifecycle milestone
- Preserves thinking blocks in context assembly
- Injects steering messages between turns
- Enforces `StopPolicy` before each turn
- Transitions to error state on provider failures

## Supporting Entities

### ToolCallSignature

**Purpose**: Normalized representation of tool calls for repetition detection.

**Zorphy Entity**: `tool_call_signature.zorphy.dart`

**Fields**:
```dart
@ZorphyEntity()
class ToolCallSignature {
  final String toolName;             // Tool name
  final String normalizedArgs;       // JSON string of sorted, normalized arguments
}
```

**Validation Rules**:
- `normalizedArgs` must be deterministic (sorted keys, consistent formatting)

### MissionConfig

**Purpose**: Configuration for mission execution.

**Zorphy Entity**: `mission_config.zorphy.dart`

**Fields**:
```dart
@ZorphyEntity()
class MissionConfig {
  final String missionId;            // Mission identifier
  final String initialPrompt;        // Initial user message
  final List<String> availableTools; // Tool IDs available to LLM
  final Map<String, dynamic> metadata; // Additional configuration
}
```

## Entity Relationships

```
EngineLoop (1) ──→ (1) StopPolicy
EngineLoop (1) ──→ (1) RepetitionTracker
EngineLoop (1) ──→ (*) EngineEvent [emits]
EngineLoop (1) ──→ (1) TurnContext [per turn]
EngineLoop (1) ──→ (0..*) steeringQueue [pending messages]
EngineEvent (1) ──→ (1) MissionConfig [via missionId]

TurnContext (1) ──→ (*) ToolCallSignature [via tool calls]
StopPolicy (1) ──→ (1) RepetitionTracker [uses]
```

## Integration with Existing Entities

From spec 002 (state and sessions):
- `EngineLoop.sessionId` references `Session.id` from spec 002
- `EngineLoop` delegates persistence to `SessionStorage` from spec 002

From spec 004 (providers and fallback):
- `EngineLoop` uses `LlmClient` interface from spec 004
- Provider errors emit `ProviderError` events

From spec 003 (tools and MCP):
- `EngineLoop` dispatches tools via interfaces from spec 003
- Tool call results are fed back as messages in context

## Data Model Notes

1. **Zorphy Compliance**: All entities use `@ZorphyEntity()` annotations and are generated with build_runner
2. **Type Safety**: Sealed class hierarchies (via Dart 3) enable exhaustive pattern matching
3. **Immutability**: All entities are immutable (final fields) to support determinism
4. **Serialization**: Zorphy generates JSON serialization for all entities
5. **Event Ordering**: `sequenceNumber` ensures total ordering across all event types
6. **Determinism**: Entity design supports determinism requirement (SC-004) - same inputs produce identical event streams

## Constitution Compliance

✅ **IX. Zorphy Is the Model Layer**: All entities defined with Zorphy annotations  
✅ **VII. Engine Purity**: No Flutter dependencies, pure Dart entities  
✅ **VIII. Attributed Ports**: Ported patterns from dart_agent_core/pi_agent will carry MIT attribution in implementation