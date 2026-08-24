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
- **FR-002**: `engine_event.dart` MUST have `part 'turn_completed.dart';` directive.
- **FR-003**: `test/engine/events/engine_event_test.dart` MUST be updated so its `describe(EngineEvent)` switch handles both `TurnStarted` and `TurnCompleted` cases.
- **FR-004**: `dart analyze --fatal-infos` + `dart test` MUST pass.

## Key Entities
- **TurnCompleted**: emitted by the engine loop when a turn finishes (with optional reason like `cancelled` or `max-tokens-reached`).

## Success Criteria
- SC-001: `dart analyze --fatal-infos` exits 0.
- SC-002: `dart test` passes all 139 + new tests.
