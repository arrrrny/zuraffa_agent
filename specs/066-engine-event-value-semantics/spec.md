**Template Version**: `zuraffa-1.0`

# Feature Specification: EngineEvent value semantics

**Branch**: `feat/spec-066-engine-event-value-semantics` | **Date**: 2026-08-28

## Summary

Give the 9 hand-curated `EngineEvent` subtypes (issues #16–#24: `TurnStarted`,
`TurnCompleted`, `ToolCallStarted`, `ToolCallCompleted`, `ThinkingDelta`,
`SteeringInjected`, `ProviderError`, `MissionStarted`, `MissionCompleted`)
full value semantics — `operator ==`, `hashCode`, and `toString` — matching
the house pattern every other hand-curated value object in this repo already
follows (`EngineLoop` spec 045: "value equality across all fields";
`PlanChangedEvent` spec 014; `SteeringQueue` spec 033; `AgentTool`;
`StopPolicy` PR #47).

Today the events are `const` classes with default identity equality and
default `Object.toString`. Two independently constructed `MissionStarted`
instances with identical fields are unequal, and printing any event yields
`Instance of 'MissionStarted'`. This blocks the downstream consumers the
roadmap calls for: the event bus (spec 013 Draft) needs to assert delivered
events, session/recording replay needs event diffing, and the eval harness
(epic #7) needs to assert emitted event sequences — all of which require
value equality and readable diagnostics.

## Files

- `lib/src/engine/events/turn_started.dart` … `mission_completed.dart` (9 part files) — add `operator ==` (identical-or-runtimeType-and-fields, house pattern), `hashCode` (`Object.hash` over all fields, declaration order), `toString` (`TypeName(field: value, …)` over all fields, declaration order, house pattern).
- `test/engine/events/engine_event_test.dart` — new `spec 066` group: equality (reflexive, symmetric, per-field distinctness), hashCode consistency (equal objects → equal hashCodes), toString exact-format assertions for each of the 9 subtypes.
- `specs/066-engine-event-value-semantics/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

##FRs

- **FR-001**: The system MUST satisfy this requirement: Every `EngineEvent` subtype implements `operator ==` following the house pattern: `identical(this, other) || (other is T && runtimeType == other.runtimeType && <field-by-field equality>)`. Two events with identical field values are equal; events differing in ANY field are not.
- **FR-002**: The system MUST satisfy this requirement: Every subtype overrides `hashCode` with `Object.hash(<all fields in declaration order>)`; equal objects have equal hashCodes.
- **FR-003**: The system MUST satisfy this requirement: Every subtype overrides `toString` as `TypeName(field: value, …)` covering ALL fields in declaration order (nullable fields render `null`; `DateTime` renders via its own `toString`).
- **FR-004**: The system MUST satisfy this requirement: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911 passed / 2 pre-existing skips at `30b4b94` + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 911 tests pass (baseline) + new spec-066 tests, 0 new failures

## Out of scope

- Wiring the events into the engine loop runtime (spec 045's successor work, epic #2).
- The 10th event `PlanChanged` (spec 067 — follows this spec; brings its own semantics at birth).
- The event log / recording layer (spec 068).
- JSON serialization of events (issue #15, spec 015-engine-event-json-part).

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
