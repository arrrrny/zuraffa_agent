# Engine Core Loop Interface Contracts

**Feature**: 002-engine-core-loop  
**Date**: 2026-08-18  
**Status**: Complete

## Overview

The engine core loop exposes a public API for mission execution, event streaming, and mid-mission control. This document defines the interface contracts that consuming applications (kernel host, mission UI, trace recorder) must adhere to.

## Public API Contracts

### EngineLoop

**Purpose**: Primary interface for executing missions and consuming event streams.

**Location**: `lib/src/engine/engine_loop.dart`

#### Constructor

```dart
EngineLoop({
  required String sessionId,
  required LlmClient provider,
  required ToolDispatcher toolDispatcher,
  StopPolicy? stopPolicy,
})
```

**Parameters**:
- `sessionId`: Valid session ID from spec 002 session storage
- `provider`: LLM provider implementing `LlmClient` interface (spec 004)
- `toolDispatcher`: Tool dispatcher implementing interface from spec 003
- `stopPolicy`: Optional safety rails; defaults to `StopPolicy.defaultPolicy()`

**Throws**: `SessionNotFoundException` if sessionId is invalid

#### Methods

##### executeMission

```dart
Future<void> executeMission(MissionConfig config)
```

**Purpose**: Start mission execution with the given configuration.

**Parameters**:
- `config`: Mission configuration including initial prompt and available tools

**Behavior**:
- Emits `MissionStarted` event immediately
- Executes turn-based loop until completion or abort
- Emits `MissionCompleted` event on termination
- Throws no exceptions; all errors emit as events

**Throws**: None (errors emit as `ProviderError` → `MissionCompleted`)

**Contract**: Caller must consume the `events` stream to receive lifecycle events

##### injectSteering

```dart
void injectSteering(String message)
```

**Purpose**: Inject a steering or follow-up message into the mission context between turns.

**Parameters**:
- `message`: Steering message content

**Behavior**:
- Adds message to internal steering queue
- Emits `SteeringInjected` event
- Message is injected before next LLM invocation

**Throws**: `StateError` if called after mission completion

**Contract**: Steering messages are processed in FIFO order

##### abort

```dart
Future<void> abort()
```

**Purpose**: Immediately stop mission execution with `aborted` outcome.

**Behavior**:
- Cancels in-flight LLM calls if possible
- Emits `MissionCompleted(outcome: "aborted")`
- Cleans up resources (closes streams)

**Throws**: None (idempotent; safe to call multiple times)

**Contract**: Session state remains resumable at last complete turn

#### Properties

##### events

```dart
Stream<EngineEvent> get events
```

**Purpose**: Stream of lifecycle events in chronological order.

**Event Types** (guaranteed ordering):
1. `MissionStarted` - emitted immediately on `executeMission()`
2. `TurnStarted` - emitted at start of each turn
3. `ThinkingDelta` - emitted for each thinking chunk (if supported)
4. `ToolCallStarted` - emitted for each tool call
5. `ToolCallCompleted` - emitted when tool call completes
6. `TurnCompleted` - emitted when turn finishes
7. `SteeringInjected` - emitted for each steering injection
8. `ProviderError` - emitted on provider failures
9. `MissionCompleted` - emitted on mission termination (last event)

**Contract**:
- Events are emitted in exact order of occurrence
- Each event has monotonically increasing `sequenceNumber`
- Stream completes when `MissionCompleted` is emitted
- Multiple consumers supported via broadcast

##### isRunning

```dart
bool get isRunning
```

**Purpose**: Indicates whether mission is currently executing.

**Contract**: Returns `false` after `MissionCompleted` is emitted

## Event Contracts

### EngineEvent Base Class

**Location**: `lib/src/domain/entities/engine_event/engine_event.dart`

```dart
abstract class EngineEvent {
  String get eventId;
  int get sequenceNumber;
  DateTime get timestamp;
  String get missionId;
}
```

**Contract**: All events extend this base class; consumers can type-check via `is` operator

### Event Type Contracts

#### MissionStarted

```dart
class MissionStarted extends EngineEvent {
  String get missionId;
  Map<String, dynamic> get config;
}
```

**Contract**: First event in stream; `missionId` matches config's mission ID

#### MissionCompleted

```dart
class MissionCompleted extends EngineEvent {
  String get outcome; // "success", "max_turns_exceeded", "timeout", "loop_detected", "error", "aborted"
  String? get errorMessage;
  int get totalTurns;
}
```

**Contract**: Last event in stream; stream completes after this event

#### TurnStarted / TurnCompleted

```dart
class TurnStarted extends EngineEvent {
  int get turnNumber;
  List<String> get messageIds;
}

class TurnCompleted extends EngineEvent {
  int get turnNumber;
  String get finishReason; // "stop", "tool_calls", "length", "error"
  int get toolCallCount;
}
```

**Contract**: `turnNumber` increments monotonically from 1; pairs always match

#### ThinkingDelta

```dart
class ThinkingDelta extends EngineEvent {
  String get content;
  int get deltaIndex;
  bool get isComplete;
}
```

**Contract**: Deltas arrive in order; `deltaIndex` increments per turn; `isComplete` marks end of thinking block

#### ToolCallStarted / ToolCallCompleted

```dart
class ToolCallStarted extends EngineEvent {
  String get toolCallId;
  String get toolName;
  Map<String, dynamic> get arguments;
  int get callIndex;
}

class ToolCallCompleted extends EngineEvent {
  String get toolCallId;
  String get result; // "success" or error details
  String? get errorMessage;
  int get durationMs;
}
```

**Contract**: Pairs always match; `toolCallId` is consistent between start/completion; `callIndex` is per-turn sequence

#### ProviderError

```dart
class ProviderError extends EngineEvent {
  String get errorType; // "timeout", "disconnected", "rate_limit", "parse_error"
  String get message;
  bool get isRecoverable;
}
```

**Contract**: Always followed by `MissionCompleted` with error outcome

#### SteeringInjected

```dart
class SteeringInjected extends EngineEvent {
  String get messageId;
  String get content;
  int get injectionPoint;
}
```

**Contract**: `injectionPoint` is the turn number where message will be injected

## Error Handling Contracts

### Error States

The engine handles errors gracefully without throwing exceptions:

1. **Provider Timeout**: Emits `ProviderError(errorType: "timeout")` → `MissionCompleted(outcome: "timeout")`
2. **Provider Disconnected**: Emits `ProviderError(errorType: "disconnected")` → `MissionCompleted(outcome: "error")`
3. **Tool Errors**: Emits `ToolCallCompleted` with error result → continues normally
4. **Malformed Tool Arguments**: Emits `ToolCallCompleted` with validation error → continues normally
5. **Max Turns Exceeded**: Emits `MissionCompleted(outcome: "max_turns_exceeded")`
6. **Repetition Detected**: Emits `MissionCompleted(outcome: "loop_detected")`

**Contract**: No exceptions propagate from `EngineLoop`; all errors are typed events

### State Recovery

After any error termination:
- Session state is consistent at the last complete turn
- Event stream is complete with all events up to termination
- Resources are cleaned up (streams closed, providers released)
- Session can be resumed by creating a new `EngineLoop` with the same `sessionId`

## Extension Contracts

### StopPolicy Extension

**Location**: `lib/src/engine/stop_policy.dart`

```dart
class StopPolicy {
  factory StopPolicy.defaultPolicy(); // maxTurns: 100, timeout: 5min, repetition: 3
  
  StopPolicy copyWith({
    int? maxTurns,
    Duration? wallClockTimeout,
    int? repetitionThreshold,
  });
}
```

**Contract**: Immutable; modifications create new instances via `copyWith`

### ToolDispatcher Interface

**Note**: This interface is defined by spec 003; the engine consumes it.

**Expected Methods**:
```dart
Future<String> dispatchToolCall({
  required String toolName,
  required Map<String, dynamic> arguments,
});
```

**Contract**: Returns tool result as string; throws `ToolNotFoundException` for unknown tools

## Testing Contracts

### Mock Interfaces

For testing, the following mocks should be provided:

1. **MockLlmClient**: Implements `LlmClient` from spec 004
2. **MockToolDispatcher**: Implements tool dispatcher interface from spec 003
3. **MockSessionStorage**: Implements session storage from spec 002

**Contract**: All mocks should support deterministic responses for repeatability testing

### Determinism Contract

Same inputs + same mock provider = identical event streams across multiple runs.

**Verification**:
```dart
test('determinism: same inputs produce identical event streams', () async {
  final events1 = await runMission(config, mockProvider);
  final events2 = await runMission(config, mockProvider);
  
  expect(events1, equals(events2)); // Byte-identical event streams
});
```

## Integration Contracts

### With Session Storage (spec 002)

**Contract**: `EngineLoop` does NOT own persistence; it delegates to session storage via `sessionId`

**Session Storage Responsibilities**:
- Store turn records with message IDs
- Maintain session tree structure
- Support selective compaction

### With Provider Layer (spec 004)

**Contract**: `EngineLoop` uses `LlmClient` interface provider-agnostically

**Provider Responsibilities**:
- Stream thinking deltas (if supported)
- Return structured responses with finish reason
- Handle timeout and disconnect errors gracefully

### With Tool Layer (spec 003)

**Contract**: `EngineLoop` dispatches tools via `ToolDispatcher` interface; does NOT implement tool logic

**Tool Dispatcher Responsibilities**:
- Validate tool arguments
- Execute tool calls
- Return structured results
- Handle unknown tool errors

## Versioning and Compatibility

**Current Version**: 1.0.0  
**Breaking Changes**: Will increment major version  
**Additions**: Will increment minor version  
**Bug Fixes**: Will increment patch version

**Backward Compatibility**: Events can have new fields added without breaking existing consumers (optional fields with defaults)

## Performance Contracts

### Event Stream Latency

- **Target**: Events emitted within 10ms of occurrence
- **Measurement**: Time between actual event and stream emission

### Turn Execution Throughput

- **Target**: Support 200+ sequential tool calls without performance degradation
- **Measurement**: Time per turn for standard 3-tool mission

### Memory Usage

- **Target**: Constant memory per active mission (no unbounded growth)
- **Measurement**: Memory usage vs turn count for long-running missions

## Security Contracts

### Input Validation

- Tool arguments are validated before dispatch
- Max message sizes enforced (configurable)
- Tool names are whitelisted to available tools

### Resource Limits

- Wall-clock timeout enforced (configurable)
- Max turns enforced (configurable)
- Concurrent tool calls limited (configurable)

## Constitution Compliance

✅ **VII. Engine Purity**: No Flutter dependencies, pure Dart interfaces  
✅ **VIII. Attributed Ports**: Ported patterns from pi_agent carry MIT attribution  
✅ **IX. Zorphy Is the Model Layer**: All entities use Zorphy, interfaces are type-safe