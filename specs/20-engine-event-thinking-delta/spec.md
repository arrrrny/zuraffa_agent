**Template Version**: `zuraffa-1.0`

# Feature Specification: EngineEvent.ThinkingDelta

**Branch**: `20-engine-event-thinking-delta` | **Date**: 2026-08-24

## Summary
Add `ThinkingDelta` as a `final class` part of `lib/src/engine/events/engine_event.dart` (sealed library established by #33/#24, extended through the previous sibling PRs). Emitted by the engine loop on every thinking-text delta chunk from the provider. Streamed; not persisted.

## Files
- `lib/src/engine/events/thinking_delta.dart` — `final class ThinkingDelta extends EngineEvent` with `emittedAt: DateTime` + delta: String.
- `lib/src/engine/events/engine_event.dart` — add `part 'thinking_delta.dart';`.
- `test/engine/events/engine_event_test.dart` — extend `describe(EngineEvent)` switch with `ThinkingDelta` case; add is-A + payload tests.
- `specs/20-engine-event-thinking-delta/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 146 tests pass

## Closes #20

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
