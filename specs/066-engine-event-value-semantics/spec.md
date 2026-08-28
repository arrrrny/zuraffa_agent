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

- **FR-001**: Every `EngineEvent` subtype implements `operator ==` following the house pattern: `identical(this, other) || (other is T && runtimeType == other.runtimeType && <field-by-field equality>)`. Two events with identical field values are equal; events differing in ANY field are not.
- **FR-002**: Every subtype overrides `hashCode` with `Object.hash(<all fields in declaration order>)`; equal objects have equal hashCodes.
- **FR-003**: Every subtype overrides `toString` as `TypeName(field: value, …)` covering ALL fields in declaration order (nullable fields render `null`; `DateTime` renders via its own `toString`).
- **FR-004**: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911 passed / 2 pre-existing skips at `30b4b94` + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All ≥ 911 tests pass (baseline) + new spec-066 tests, 0 new failures

## Out of scope

- Wiring the events into the engine loop runtime (spec 045's successor work, epic #2).
- The 10th event `PlanChanged` (spec 067 — follows this spec; brings its own semantics at birth).
- The event log / recording layer (spec 068).
- JSON serialization of events (issue #15, spec 015-engine-event-json-part).
