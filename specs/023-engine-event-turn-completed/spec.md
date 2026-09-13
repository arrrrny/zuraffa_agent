**Template Version**: `zuraffa-1.0`

# Feature Specification: EngineEvent.TurnCompleted

**Feature Branch**: `023-engine-event-turn-completed`
**Created**: 2026-08-24
**Status**: Draft
**Input**: Bug arrrrny/zuraffa_agent#23 — second of 9 sibling issues (#16–#24) caused by `zfa entity create --sealed --generate-subs` emitting each EngineEvent subtype as a standalone entity library that `implements EngineEvent`, triggering `invalid_use_of_type_outside_library`. The first sibling (PR #33 / issue #24) shipped the hand-curated `lib/src/engine/events/engine_event.dart` sealed library + `TurnStarted` part. This PR adds `TurnCompleted` as the second `final class` part of that library.

## User Scenarios & Testing

### User Story 1 - TurnCompleted compiles inside the EngineEvent library (P1)
As the build CI, I see `dart analyze --fatal-infos` succeed on the new `turn_completed.dart` part file because `TurnCompleted` is declared inside the same library as `sealed class EngineEvent`.

**Independent Test**: `dart analyze lib/src/engine/events/` exits 0; new test asserts `TurnCompleted()` is an `EngineEvent` and the `switch` over `EngineEvent` now handles both `TurnStarted` and `TurnCompleted` (exhaustive).

### Edge Cases
- With 2 subtypes (TurnStarted, TurnCompleted), a `switch` over `EngineEvent` MUST handle both — the existing test from #24 is updated to include the TurnCompleted case, otherwise the switch is non-exhaustive (analyzer error).

## Requirements
- **FR-001**: `turn_completed.dart` MUST be `part of 'engine_event.dart';` and declare `final class TurnCompleted extends EngineEvent` with `final DateTime emittedAt; final String? reason; const TurnCompleted({required this.emittedAt, this.reason});`.
  traces: EngineEven.fr1
- **FR-002**: `engine_event.dart` MUST have `part 'turn_completed.dart';` directive.
  traces: EngineEven.fr2
- **FR-003**: `test/engine/events/engine_event_test.dart` MUST be updated so its `describe(EngineEvent)` switch handles both `TurnStarted` and `TurnCompleted` cases.
  traces: EngineEven.fr3
- **FR-004**: `dart analyze --fatal-infos` + `dart test` MUST pass.
  traces: EngineEven.fr4

## Key Entities
- **TurnCompleted**: emitted by the engine loop when a turn finishes (with optional reason like `cancelled` or `max-tokens-reached`).

## Layer Contracts

**Domain**:

- `EngineEven`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`

## Success Criteria
- SC-001: `dart analyze --fatal-infos` exits 0.
- SC-002: `dart test` passes all 139 + new tests.

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted carries emittedAt + optional turnId **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted.turnId defaults to null for ephemeral turns **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** switch over EngineEvent is exhaustive with all current subtypes **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** NoParams is reachable (smoke) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted carries emittedAt + optional reason **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted.reason defaults to null on normal completion **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
9. **Given** the feature implementation under its clean-architecture seams **When** ToolCallStarted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** ToolCallStarted carries emittedAt, toolName, callId **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** ToolCallCompleted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** ToolCallCompleted carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** ThinkingDelta is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** ThinkingDelta carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
15. **Given** the feature implementation under its clean-architecture seams **When** SteeringInjected is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
16. **Given** the feature implementation under its clean-architecture seams **When** SteeringInjected carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
17. **Given** the feature implementation under its clean-architecture seams **When** ProviderError is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
18. **Given** the feature implementation under its clean-architecture seams **When** ProviderError carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
19. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes ProviderError to provider_error(providerName) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
20. **Given** the feature implementation under its clean-architecture seams **When** MissionStarted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
21. **Given** the feature implementation under its clean-architecture seams **When** MissionStarted carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
22. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes MissionStarted to mission_started(missionId) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
23. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
24. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
25. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted.summary is nullable and round-trips null **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
26. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes MissionCompleted to mission_completed(missionId) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
27. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
28. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
29. **Given** the feature implementation under its clean-architecture seams **When** ToolCallStarted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
30. **Given** the feature implementation under its clean-architecture seams **When** ToolCallCompleted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
31. **Given** the feature implementation under its clean-architecture seams **When** ThinkingDelta equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
32. **Given** the feature implementation under its clean-architecture seams **When** SteeringInjected equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
33. **Given** the feature implementation under its clean-architecture seams **When** ProviderError equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
34. **Given** the feature implementation under its clean-architecture seams **When** MissionStarted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
35. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
36. **Given** the feature implementation under its clean-architecture seams **When** different runtimeTypes are never equal **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
37. **Given** the feature implementation under its clean-architecture seams **When** PlanChanged is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
38. **Given** the feature implementation under its clean-architecture seams **When** PlanChanged carries emittedAt + the PlanChangedEvent payload **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
39. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes PlanChanged to plan_changed(next plan id) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
40. **Given** the feature implementation under its clean-architecture seams **When** PlanChanged value semantics (born with spec 066 pattern) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`).
   **Type**: acceptance
