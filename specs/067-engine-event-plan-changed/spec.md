**Template Version**: `zuraffa-1.0`

# Feature Specification: EngineEvent.PlanChanged

**Branch**: `feat/spec-067-engine-event-plan-changed` | **Date**: 2026-08-28

## Summary

Add `PlanChanged` as a `final class` part of the sealed
`lib/src/engine/events/engine_event.dart` library — the 10th member of the
union — wiring the existing domain `PlanChangedEvent`
(`lib/src/domain/entities/planner/plan_changed_event.dart`) into the
EngineEvent union and thereby closing the wiring gap left open by
spec 014.

Spec 014 (planner/TODO system) FR-005 states: *"Plan changes MUST emit
PlanChangedEvent."* The domain value object landed (with full value
semantics), but its own header documents the constraint that blocked the
wiring: *"Wiring it into the sealed EngineEvent union
(lib/src/engine/events/) happens with the engine-loop spec (045), which
owns that library — the EngineEvent sealed class forbids subtypes outside
its declaring library (issues #16–#24), so the union grows only from its
own spec."* Spec 045 landed without performing the wiring. This spec is
the union-growing spec that 014's header called for.

## Files

- `lib/src/engine/events/engine_event.dart` — add `import '../../domain/entities/planner/plan_changed_event.dart';` + `part 'plan_changed.dart';`.
- `lib/src/engine/events/plan_changed.dart` — `final class PlanChanged extends EngineEvent` with `emittedAt: DateTime` + `change: PlanChangedEvent`; born with full value semantics (`==`/`hashCode`/`toString`, spec 066 house pattern).
- `test/engine/events/engine_event_test.dart` — extend the shared `describe(EngineEvent)` switch (the `#24` group) with the `PlanChanged` arm; add the `spec 067` group (is-A, payload round-trip, describe routing, value semantics).
- `specs/067-engine-event-plan-changed/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

## FRs

- **FR-001**: The system MUST satisfy this requirement: `final class PlanChanged extends EngineEvent` declared as `part of 'engine_event.dart';` carrying `emittedAt: DateTime` (when the engine emitted the event) and `change: PlanChangedEvent` (the domain payload pairing the previous/next `PlanState` snapshots). The two timestamps are distinct concepts: `emittedAt` is the engine emission time; `change.emittedAt` is when the plan change was applied.
  traces: EngineEven.fr1
- **FR-002**: The system MUST satisfy this requirement: `engine_event.dart` includes `part 'plan_changed.dart';` and imports the domain `PlanChangedEvent` (no cycle: planner entities import nothing from `engine/events`).
  traces: EngineEven.fr2
- **FR-003**: The system MUST satisfy this requirement: The exhaustive `describe(EngineEvent)` switch handles `PlanChanged`, routing to `plan_changed(<next plan id>)`.
  traces: EngineEven.fr3
- **FR-004**: The system MUST satisfy this requirement: `PlanChanged` carries value semantics at birth: `==` (identical-or-runtimeType-and-fields, comparing `emittedAt` and `change`), `hashCode` (`Object.hash(emittedAt, change)`), `toString` (`PlanChanged(emittedAt: …, change: …)` delegating to `PlanChangedEvent.toString`).
  traces: EngineEven.fr4
- **FR-005**: The system MUST satisfy this requirement: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911/2 at `30b4b94` + new tests).
  traces: EngineEven.fr5

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- The engine-loop runtime site that constructs and emits `PlanChanged` (epic #2 / spec 045 successor work) — this spec delivers the union member and its semantics.
- JSON serialization of events (issue #15, spec 015).
- The other 9 subtypes' value semantics (spec 066, PR #77).

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

## Layer Contracts

**Domain**:

- `EngineEven`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`

