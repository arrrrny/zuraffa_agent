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

- **FR-001**: `final class PlanChanged extends EngineEvent` declared as `part of 'engine_event.dart';` carrying `emittedAt: DateTime` (when the engine emitted the event) and `change: PlanChangedEvent` (the domain payload pairing the previous/next `PlanState` snapshots). The two timestamps are distinct concepts: `emittedAt` is the engine emission time; `change.emittedAt` is when the plan change was applied.
- **FR-002**: `engine_event.dart` includes `part 'plan_changed.dart';` and imports the domain `PlanChangedEvent` (no cycle: planner entities import nothing from `engine/events`).
- **FR-003**: The exhaustive `describe(EngineEvent)` switch handles `PlanChanged`, routing to `plan_changed(<next plan id>)`.
- **FR-004**: `PlanChanged` carries value semantics at birth: `==` (identical-or-runtimeType-and-fields, comparing `emittedAt` and `change`), `hashCode` (`Object.hash(emittedAt, change)`), `toString` (`PlanChanged(emittedAt: …, change: …)` delegating to `PlanChangedEvent.toString`).
- **FR-005**: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911/2 at `30b4b94` + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- The engine-loop runtime site that constructs and emits `PlanChanged` (epic #2 / spec 045 successor work) — this spec delivers the union member and its semantics.
- JSON serialization of events (issue #15, spec 015).
- The other 9 subtypes' value semantics (spec 066, PR #77).
