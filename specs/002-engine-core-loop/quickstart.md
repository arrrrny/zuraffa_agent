# Quickstart: Engine Core Loop

**Feature**: 002-engine-core-loop  
**Date**: 2026-08-18  
**Status**: Complete

## Overview

This quickstart guide provides runnable validation scenarios to verify the engine core loop implementation works end-to-end. These scenarios can be executed to validate all acceptance criteria from the feature specification.

## Prerequisites

### Environment Setup

```bash
# Ensure Dart SDK 3.8.0+ is installed
dart --version  # Should show 3.8.0 or higher

# Install dependencies
cd /Users/ahmettok/Developer/zuraffa_agent
pub get

# Verify dependencies installed
pub deps | grep -E "test|mocktail|zorphy"
```

### Required Dependencies (from pubspec.yaml)

- `dart: sdk ^3.8.0`
- `zorphy_annotation: ^2.0.0`
- `test: ^1.25.0`
- `mocktail: ^1.0.5`
- `build_runner: ^2.16.0`

## Test Execution Commands

### Run All Engine Tests

```bash
# Run all engine core loop tests
dart test test/engine/

# Run with coverage
dart test --coverage=coverage test/engine/
```

### Run Specific Test Suites

```bash
# Test turn execution and tool dispatch
dart test test/engine/engine_loop_test.dart

# Test event streaming and ordering
dart test test/engine/engine_event_test.dart

# Test safety rails (max turns, timeout, repetition)
dart test test/engine/stop_policy_test.dart

# Test steering and follow-up messages
dart test test/engine/steering_test.dart
```

### Generate Zorphy Code

```bash
# Generate Zorphy entity code
dart run build_runner build --delete-conflicting-outputs
```

## Validation Scenarios

### Scenario 1: Basic 3-Tool Mission (FR-001, SC-001)

**Purpose**: Verify the engine completes a multi-tool mission with correct event stream.

**Test File**: `test/engine/engine_loop_test.dart`

**Prerequisites**: Mock LLM provider that returns tool calls

**Validation Steps**:
```bash
# Run the test
dart test test/engine/engine_loop_test.dart --name="completes 3-tool mission"
```

**Expected Outcomes**:
- ✅ Mission starts with `MissionStarted` event
- ✅ Turn 1 executes with `TurnStarted` → thinking deltas → `ToolCallStarted` ×3 → `ToolCallCompleted` ×3 → `TurnCompleted`
- ✅ Turn 2+ continue until model produces final answer
- ✅ Mission ends with `MissionCompleted(outcome: "success")`
- ✅ Event stream contains all event types in chronological order
- ✅ Sequence numbers increase monotonically across all events

**Acceptance Criteria Validated**:
- FR-001: Turn-based while-loop advancing on LLM finish-reason
- FR-005: Typed, ordered event stream with sequence identifiers
- SC-001: 3-tool mission streams every event type

### Scenario 2: Interleaved Thinking Preservation (FR-002, US-2)

**Purpose**: Verify thinking blocks are preserved in context across turns.

**Test File**: `test/engine/engine_loop_test.dart`

**Prerequisites**: Mock provider that streams thinking deltas

**Validation Steps**:
```bash
# Run the test
dart test test/engine/engine_loop_test.dart --name="preserves thinking blocks across turns"
```

**Expected Outcomes**:
- ✅ Thinking deltas emitted as `ThinkingDelta` events during turn
- ✅ Thinking blocks appear in assistant messages alongside tool calls
- ✅ Multi-turn mission includes thinking blocks from previous turns in context
- ✅ Thinking content is not truncated or stripped between turns

**Acceptance Criteria Validated**:
- FR-002: Assistant messages carry thinking blocks alongside tool calls
- US-2: Thinking deltas appear in session stream and persist across turns

### Scenario 3: Mid-Mission Steering (FR-003, US-3, SC-002)

**Purpose**: Verify steering messages can be injected mid-mission without restart.

**Test File**: `test/engine/steering_test.dart`

**Prerequisites**: Multi-turn mission execution

**Validation Steps**:
```bash
# Run the test
dart test test/engine/steering_test.dart --name="injects steering mid-mission"
```

**Expected Outcomes**:
- ✅ `SteeringInjected` event emitted when steering is added
- ✅ Steering message appears in context before next LLM invocation
- ✅ Tool choices in subsequent turns reflect steering guidance
- ✅ Mission continues without restart or state loss

**Acceptance Criteria Validated**:
- FR-003: Support steering and follow-up message queues injected between turns
- US-3: Steering input alters course without restart
- SC-002: Steering input mid-mission alters course

### Scenario 4: Loop Safety Rails (FR-004, US-4)

**Purpose**: Verify max-turns, timeout, and repetition detection abort runaway loops.

**Test File**: `test/engine/stop_policy_test.dart`

**Prerequisites**: Mock provider that generates repetitive tool calls

**Validation Steps**:
```bash
# Test max turns limit
dart test test/engine/stop_policy_test.dart --name="enforces max turns limit"

# Test wall-clock timeout
dart test test/engine/stop_policy_test.dart --name="enforces wall-clock timeout"

# Test repetition detection
dart test test/engine/stop_policy_test.dart --name="detects repetitive tool calls"
```

**Expected Outcomes**:

**Max Turns**:
- ✅ Mission ends with `MissionCompleted(outcome: "max_turns_exceeded")`
- ✅ Exactly `maxTurns` turns executed
- ✅ `totalTurns` in completion event equals configured limit

**Timeout**:
- ✅ Mission ends with `MissionCompleted(outcome: "timeout")`
- ✅ Total execution time ≈ configured timeout
- ✅ Partial turn discarded cleanly

**Repetition Detection**:
- ✅ `MissionCompleted(outcome: "loop_detected")` when threshold hit
- ✅ Repetition detector identifies pattern correctly
- ✅ Mission aborts cleanly without state corruption

**Acceptance Criteria Validated**:
- FR-004: Enforce max-turns, timeout, repetition detection with typed outcomes
- US-4: Safety rails bound every mission with typed failures

### Scenario 5: 200-Call Synthetic Mission (US-1, SC-003)

**Purpose**: Verify engine handles 200+ sequential tool calls without state corruption.

**Test File**: `test/engine/engine_loop_test.dart`

**Prerequisites**: Mock provider that generates 200 sequential tool calls

**Validation Steps**:
```bash
# Run the test
dart test test/engine/engine_loop_test.dart --name="handles 200-call mission"
```

**Expected Outcomes**:
- ✅ All 200 tool calls dispatched successfully
- ✅ Every event type appears in event stream
- ✅ No memory leaks or unbounded growth
- ✅ Event stream completeness verified (no missing events)
- ✅ Session state consistent throughout execution

**Acceptance Criteria Validated**:
- US-1: Mission with 200 sequential tool calls completes
- SC-003: 200-call synthetic mission completes without state corruption

### Scenario 6: Determinism (SC-004)

**Purpose**: Verify same inputs produce identical event streams across multiple runs.

**Test File**: `test/engine/engine_loop_test.dart`

**Prerequisites**: Deterministic mock provider with recorded responses

**Validation Steps**:
```bash
# Run determinism test
dart test test/engine/engine_loop_test.dart --name="produces deterministic event streams"
```

**Expected Outcomes**:
- ✅ Event stream from run 1 equals event stream from run 2 (byte-identical)
- ✅ Same holds across 10 consecutive runs
- ✅ Sequence numbers, timestamps, and all event fields match exactly

**Acceptance Criteria Validated**:
- SC-004: Determinism — same inputs produce identical event streams

## Edge Case Validation

### Edge Case 1: Provider Returns Both Content and Tool Calls

**Test File**: `test/engine/engine_loop_test.dart`

**Validation**:
```bash
dart test test/engine/engine_loop_test.dart --name="handles content and tool calls together"
```

**Expected**: Both honored — content recorded as final message, then tools dispatched

### Edge Case 2: Unknown Tool Reference

**Test File**: `test/engine/engine_loop_test.dart`

**Validation**:
```bash
dart test test/engine/engine_loop_test.dart --name="handles unknown tool gracefully"
```

**Expected**: Typed tool-error result fed back, mission continues

### Edge Case 3: Abort During In-Flight LLM Stream

**Test File**: `test/engine/engine_loop_test.dart`

**Validation**:
```bash
dart test test/engine/engine_loop_test.dart --name="handles abort during LLM stream"
```

**Expected**: Stream cancelled, partial turn discarded, session resumable

### Edge Case 4: Malformed Tool Arguments

**Test File**: `test/engine/engine_loop_test.dart`

**Validation**:
```bash
dart test test/engine/engine_loop_test.dart --name="handles malformed tool arguments"
```

**Expected**: Validation error returned as tool result, mission continues

### Edge Case 5: Provider Disconnects Mid-Stream

**Test File**: `test/engine/engine_loop_test.dart`

**Validation**:
```bash
dart test test/engine/engine_loop_test.dart --name="handles provider disconnect"
```

**Expected**: Clean termination with typed `ProviderError` → `MissionCompleted(error)`

## Integration Validation

### With Session Storage (spec 002)

**Purpose**: Verify engine delegates persistence correctly to session storage.

**Validation**:
```bash
# Ensure session storage tests pass
dart test test/session_storage_test.dart
dart test test/roundtrip_test.dart
```

**Expected**: Engine uses session storage for persistence; owns no persistence itself

### With Provider Layer (spec 004)

**Purpose**: Verify engine works provider-agnostically via LlmClient interface.

**Validation**:
```bash
# Test with multiple mock provider implementations
dart test test/engine/engine_loop_test.dart --name="works with different providers"
```

**Expected**: Engine works with any LlmClient implementation

### With Tool Layer (spec 003)

**Purpose**: Verify engine dispatches tools via tool dispatcher interface.

**Validation**:
```bash
# Test tool dispatch integration
dart test test/tools_test.dart
```

**Expected**: Engine dispatches tools correctly; tool logic remains in spec 003

## Manual Validation Steps

For additional confidence, run these manual validations:

### 1. Inspect Generated Zorphy Code

```bash
# Verify Zorphy entities generated correctly
find lib/src/domain/entities -name "*.g.dart" -exec echo "Generated: {}" \;

# Check engine event entities
ls -la lib/src/domain/entities/engine_event/
ls -la lib/src/domain/entities/stop_policy/
```

**Expected**: All `.zorphy.dart` files have corresponding `.g.dart` files

### 2. Verify No Flutter Dependencies

```bash
# Check pubspec.yaml for Flutter dependencies
grep -i "flutter" pubspec.yaml

# Expected: No Flutter dependencies found
```

### 3. Run Static Analysis

```bash
# Ensure pristine analyzer output
dart analyze

# Expected: Zero errors, zero warnings
```

### 4. Check Event Stream Ordering

Run a mission and manually inspect event stream:

```dart
// In test file, collect events:
final events = <EngineEvent>[];
engine.events.listen(events.add);

// Execute mission
await engine.executeMission(config);

// Verify ordering
for (int i = 0; i < events.length - 1; i++) {
  expect(events[i].sequenceNumber, lessThan(events[i+1].sequenceNumber));
}
```

**Expected**: All sequence numbers increase monotonically

## Troubleshooting

### Common Issues

**Issue**: Tests fail with "Zorphy entity not found"
```bash
# Solution: Regenerate Zorphy code
dart run build_runner build --delete-conflicting-outputs
```

**Issue**: Tests timeout during 200-call mission
```bash
# Solution: Increase test timeout in pubspec.yaml or test file
timeout: 5m  # In pubspec.yaml or test file header
```

**Issue**: Event stream missing events
```bash
# Solution: Check that event controller is properly closed
# Verify that await is used correctly in async tests
```

**Issue**: Determinism test fails
```bash
# Solution: Ensure mock provider is truly deterministic
# Check that timestamps are handled consistently
# Verify that random seeds are fixed in tests
```

## Success Criteria Checklist

After running all validation scenarios, confirm:

- [ ] All 6 main scenarios pass (1-6 above)
- [ ] All 5 edge cases handled correctly
- [ ] Integration with specs 002, 003, 004 works
- [ ] Manual validation steps pass
- [ ] Zero analyzer errors/warnings
- [ ] No Flutter dependencies detected
- [ ] All Zorphy entities generated correctly
- [ ] Event streams are deterministic across runs
- [ ] 200-call mission completes without memory issues

## Next Steps

After successful validation:

1. Review generated artifacts in `specs/002-engine-core-loop/`
2. Proceed to `tasks.md` generation via `/skill:speckit-tasks`
3. Begin implementation following the task order

## References

- Feature Spec: [spec.md](./spec.md)
- Data Model: [data-model.md](./data-model.md)
- API Contracts: [contracts/engine-api.md](./contracts/engine-api.md)
- Research Findings: [research.md](./research.md)
- Constitution: [.specify/memory/constitution.md](../../.specify/memory/constitution.md)