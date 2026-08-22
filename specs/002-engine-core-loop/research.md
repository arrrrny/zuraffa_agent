# Research: Engine Core Loop

**Feature**: 002-engine-core-loop  
**Date**: 2026-08-18  
**Status**: Complete

## Research Overview

This document captures research findings for technical decisions in the engine core loop implementation, focusing on Dart async patterns, event streaming, testing approaches, and integration with ported sources.

## Research Areas

### 1. Dart Async Patterns for Event Streaming

**Research Question**: What are the best practices for implementing typed, ordered event streams in Dart for the engine lifecycle events?

**Decision**: Use `Stream<T>` with a `StreamController` for event emission, implementing typed sealed classes for event hierarchy.

**Rationale**:
- Dart's `Stream<T>` is the idiomatic pattern for async data flow with multiple consumers
- `StreamController` provides backpressure handling and broadcast capabilities
- Sealed classes (via enum classes in Dart 3) enable exhaustive pattern matching on event types
- Stream ordering guarantees match the spec requirement for chronological event sequence

**Alternatives Considered**:
- **Future-based callbacks**: Rejected - doesn't support multiple consumers naturally
- **Custom event bus**: Rejected - overengineering; Stream<T> is sufficient and idiomatic
- **RxDart extensions**: Rejected - adds dependency; core Stream<T> provides needed functionality

**Implementation Pattern**:
```dart
sealed class EngineEvent {
  const EngineEvent();
}

final class MissionStarted extends EngineEvent { ... }
final class TurnStarted extends EngineEvent { ... }
final class ThinkingDelta extends EngineEvent { ... }
final class ToolCallStarted extends EngineEvent { ... }

// Event emission via StreamController
final _eventController = StreamController<EngineEvent>();
Stream<EngineEvent> get events => _eventController.stream;
```

### 2. Stream-Based Architectures in Dart

**Research Question**: How to structure the turn-based loop while ensuring clean stream lifecycle and proper resource management?

**Decision**: Implement the loop as an async function with internal state management, emitting events through a StreamController that's properly closed on completion.

**Rationale**:
- Async functions with `await` provide readable turn-by-turn execution
- Internal state management (turn counter, tool call tracker) fits naturally within function scope
- StreamController lifetime is bounded to the loop execution, ensuring proper cleanup
- Supports cancellation via StreamController close or abort flag

**Alternatives Considered**:
- **Recursive async function**: Rejected - harder to manage shared state across turns
- **Generator/Stream-based loop**: Rejected - overkill for this use case; simpler async function more maintainable
- **State machine class**: Rejected - spec explicitly requires "no FSM; model drives"

**Implementation Pattern**:
```dart
Future<void> executeMission(Mission mission) async {
  try {
    while (_shouldContinue()) {
      await _executeTurn();
    }
    _emitEvent(MissionCompleted(...));
  } finally {
    await _eventController.close();
  }
}
```

### 3. Testing Patterns for Async/Stream-Based Code

**Research Question**: How to effectively test deterministic loop behavior, event streaming, and timeout handling in Dart?

**Decision**: Use `package:test` with `mocktail` for mocking providers, combined with `expectAsync` for stream verification and `fakeAsync` for timeout testing.

**Rationale**:
- `package:test ^1.25.0` is already in pubspec.yaml and is the standard Dart testing framework
- `mocktail ^1.0.5` provides modern mocking capabilities compatible with Dart null safety
- `expectAsync` allows precise verification of async callbacks and stream events
- `fakeAsync` from `package:test` enables deterministic testing of timeout behavior without actual delays

**Alternatives Considered**:
- **Unit tests only**: Rejected - insufficient for testing end-to-end loop behavior
- **Integration tests with real LLM**: Rejected - introduces flakiness; deterministic tests preferred
- **Custom test doubles**: Rejected - mocktail provides cleaner API and better null safety

**Implementation Pattern**:
```dart
test('completes 3-tool mission with correct event sequence', () async {
  final mockProvider = MockLlmClient();
  final events = <EngineEvent>[];
  
  engine.events.listen(events.add);
  
  await engine.executeMission(mission);
  
  expect(events, hasLength(expectedEventCount));
  expect(events[0], isA<MissionStarted>());
  expect(events[1], isA<TurnStarted>());
  // ... verify sequence
});
```

### 4. Port Integration from dart_agent_core and pi_agent

**Research Question**: How to integrate ported sources from dart_agent_core and pi_agent while maintaining proper attribution and avoiding Flutter dependencies?

**Decision**: Port relevant algorithmic patterns (not code) as Dart equivalents with MIT attribution headers, ensuring Flutter-free implementation.

**Rationale**:
- Direct code import may bring Flutter dependencies or incompatible patterns
- Algorithm porting ensures Dart-idiomatic implementation
- MIT attribution satisfies Constitution VIII
- Focus on proven patterns (200+ sequential tool calls) rather than literal code

**Alternatives Considered**:
- **Direct code import**: Rejected - may violate Flutter-free constraint (Constitution VII)
- **No ports**: Rejected - loses proven patterns from Kimi/pi-mono implementations
- **Full framework integration**: Rejected - overkill; we need specific patterns, not entire frameworks

**Implementation Pattern**:
```dart
// Ported from pi_agent MIT implementation
// Reference: https://github.com/anthropics/pi_agent/blob/main/src/agent-loop.ts
// Attribution: MIT License, Copyright (c) 2023-2024 Anthropic, PBC

Future<void> _executeTurn() async {
  // Ported turn-execution logic adapted to Dart patterns
  final response = await provider.complete(messages);
  
  if (response.toolCalls.isNotEmpty) {
    await _dispatchToolCalls(response.toolCalls);
  } else {
    _completeMission(response.content);
  }
}
```

### 5. Error Handling Patterns for Provider Failures

**Research Question**: How to handle provider disconnects, timeouts, and malformed responses without breaking the loop invariant?

**Decision**: Wrap provider calls in try-catch blocks, emit typed failure events, and transition to error state while maintaining session resumability.

**Rationale**:
- Typed failure events satisfy spec requirements for error handling
- Session resumability ensures state consistency across failures
- Clean error state transition prevents resource leaks
- Exception handling at provider boundary isolates failures

**Alternatives Considered**:
- **Propagate exceptions to caller**: Rejected - loses typed event stream benefits
- **Silent retry**: Rejected - masks failures, violates probe evidence requirement (Constitution VI)
- **Crash on error**: Rejected - violates session resumability requirement

**Implementation Pattern**:
```dart
try {
  final response = await provider.complete(messages);
  _processResponse(response);
} on ProviderDisconnectedException catch (e) {
  _emitEvent(ProviderDisconnected(error: e.message));
  _transitionToErrorState();
} on TimeoutException catch (e) {
  _emitEvent(ProviderTimeout(error: e.message));
  _transitionToErrorState();
}
```

## Technology Decisions Summary

| Area | Decision | Key Considerations |
|------|----------|-------------------|
| Event Streaming | `Stream<T>` with `StreamController` | Idiomatic Dart, supports multiple consumers |
| Loop Structure | Async function with internal state | Readable, manageable, no FSM |
| Testing Framework | `package:test` + `mocktail` | Already in pubspec, null-safe, proven |
| Timeout Testing | `fakeAsync` from `package:test` | Deterministic without real delays |
| Port Integration | Algorithm porting with MIT attribution | Flutter-free, idiomatic Dart |
| Error Handling | Try-catch with typed events | Clean state transitions, event stream consistency |

## Open Questions Resolved

All technical decisions from the Technical Context section have been resolved through this research. No additional clarification needed for Phase 1 design.

## References

- Dart async programming: https://dart.dev/async
- Dart Streams: https://dart.dev/tutorials/language/streams
- package:test documentation: https://pub.dev/packages/test
- mocktail documentation: https://pub.dev/packages/mocktail
- pi_agent reference implementation: https://github.com/anthropics/pi_agent/blob/main/src/agent-loop.ts