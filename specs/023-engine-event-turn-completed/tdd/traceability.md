# Traceability: 023-engine-event-turn-completed

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:15a0c4020bbad8882c39ca3c374b85b8e75f29fce35d001ac2d091501cae4def
statements: 44
automated: 44
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 21 | - **FR-001**: `turn_completed.dart` MUST be `part of 'engine_event.dart';` and declare `final class TurnCompleted extends EngineEvent` with `final DateTime emittedAt; final String? reason; const TurnCompleted({required this.emittedAt, this.reason});`. | U1 | automated |
| FR-002 | 22 | - **FR-002**: `engine_event.dart` MUST have `part 'turn_completed.dart';` directive. | U2 | automated |
| FR-003 | 23 | - **FR-003**: `test/engine/events/engine_event_test.dart` MUST be updated so its `describe(EngineEvent)` switch handles both `TurnStarted` and `TurnCompleted` cases. | U3 | automated |
| FR-004 | 24 | - **FR-004**: `dart analyze --fatal-infos` + `dart test` MUST pass. | U4 | automated |
| AC-1 | 38 | 1. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A1 | automated |
| AC-2 | 40 | 2. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted carries emittedAt + optional turnId **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A2 | automated |
| AC-3 | 42 | 3. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted.turnId defaults to null for ephemeral turns **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A3 | automated |
| AC-4 | 44 | 4. **Given** the feature implementation under its clean-architecture seams **When** switch over EngineEvent is exhaustive with all current subtypes **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A4 | automated |
| AC-5 | 46 | 5. **Given** the feature implementation under its clean-architecture seams **When** NoParams is reachable (smoke) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A5 | automated |
| AC-6 | 48 | 6. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A6 | automated |
| AC-7 | 50 | 7. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted carries emittedAt + optional reason **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A7 | automated |
| AC-8 | 52 | 8. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted.reason defaults to null on normal completion **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A8 | automated |
| AC-9 | 54 | 9. **Given** the feature implementation under its clean-architecture seams **When** ToolCallStarted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A9 | automated |
| AC-10 | 56 | 10. **Given** the feature implementation under its clean-architecture seams **When** ToolCallStarted carries emittedAt, toolName, callId **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A10 | automated |
| AC-11 | 58 | 11. **Given** the feature implementation under its clean-architecture seams **When** ToolCallCompleted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A11 | automated |
| AC-12 | 60 | 12. **Given** the feature implementation under its clean-architecture seams **When** ToolCallCompleted carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A12 | automated |
| AC-13 | 62 | 13. **Given** the feature implementation under its clean-architecture seams **When** ThinkingDelta is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A13 | automated |
| AC-14 | 64 | 14. **Given** the feature implementation under its clean-architecture seams **When** ThinkingDelta carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A14 | automated |
| AC-15 | 66 | 15. **Given** the feature implementation under its clean-architecture seams **When** SteeringInjected is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A15 | automated |
| AC-16 | 68 | 16. **Given** the feature implementation under its clean-architecture seams **When** SteeringInjected carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A16 | automated |
| AC-17 | 70 | 17. **Given** the feature implementation under its clean-architecture seams **When** ProviderError is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A17 | automated |
| AC-18 | 72 | 18. **Given** the feature implementation under its clean-architecture seams **When** ProviderError carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A18 | automated |
| AC-19 | 74 | 19. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes ProviderError to provider_error(providerName) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A19 | automated |
| AC-20 | 76 | 20. **Given** the feature implementation under its clean-architecture seams **When** MissionStarted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A20 | automated |
| AC-21 | 78 | 21. **Given** the feature implementation under its clean-architecture seams **When** MissionStarted carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A21 | automated |
| AC-22 | 80 | 22. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes MissionStarted to mission_started(missionId) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A22 | automated |
| AC-23 | 82 | 23. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A23 | automated |
| AC-24 | 84 | 24. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted carries payload fields **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A24 | automated |
| AC-25 | 86 | 25. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted.summary is nullable and round-trips null **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A25 | automated |
| AC-26 | 88 | 26. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes MissionCompleted to mission_completed(missionId) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A26 | automated |
| AC-27 | 90 | 27. **Given** the feature implementation under its clean-architecture seams **When** TurnStarted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A27 | automated |
| AC-28 | 92 | 28. **Given** the feature implementation under its clean-architecture seams **When** TurnCompleted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A28 | automated |
| AC-29 | 94 | 29. **Given** the feature implementation under its clean-architecture seams **When** ToolCallStarted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A29 | automated |
| AC-30 | 96 | 30. **Given** the feature implementation under its clean-architecture seams **When** ToolCallCompleted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A30 | automated |
| AC-31 | 98 | 31. **Given** the feature implementation under its clean-architecture seams **When** ThinkingDelta equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A31 | automated |
| AC-32 | 100 | 32. **Given** the feature implementation under its clean-architecture seams **When** SteeringInjected equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A32 | automated |
| AC-33 | 102 | 33. **Given** the feature implementation under its clean-architecture seams **When** ProviderError equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A33 | automated |
| AC-34 | 104 | 34. **Given** the feature implementation under its clean-architecture seams **When** MissionStarted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A34 | automated |
| AC-35 | 106 | 35. **Given** the feature implementation under its clean-architecture seams **When** MissionCompleted equality, hashCode, toString **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A35 | automated |
| AC-36 | 108 | 36. **Given** the feature implementation under its clean-architecture seams **When** different runtimeTypes are never equal **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A36 | automated |
| AC-37 | 110 | 37. **Given** the feature implementation under its clean-architecture seams **When** PlanChanged is an EngineEvent **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A37 | automated |
| AC-38 | 112 | 38. **Given** the feature implementation under its clean-architecture seams **When** PlanChanged carries emittedAt + the PlanChangedEvent payload **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A38 | automated |
| AC-39 | 114 | 39. **Given** the feature implementation under its clean-architecture seams **When** describe(EngineEvent) switch routes PlanChanged to plan_changed(next plan id) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A39 | automated |
| AC-40 | 116 | 40. **Given** the feature implementation under its clean-architecture seams **When** PlanChanged value semantics (born with spec 066 pattern) **Then** the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | A40 | automated |

