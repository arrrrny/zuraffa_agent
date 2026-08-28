# Test List: EngineEvent.PlanChanged

---
feature: 067-engine-event-plan-changed
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 5 # FR-001..FR-005 in spec.md
planned_at: 30b4b94 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 911 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at 30b4b94
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `PlanChanged` is `is EngineEvent` AND `is PlanChanged` | FR-001 | example | DONE | `test/engine/events/engine_event_test.dart::spec 067 — EngineEvent.PlanChanged::PlanChanged is an EngineEvent` |
| A2  | `PlanChanged` carries `emittedAt` and the domain `change: PlanChangedEvent` payload; `change.previous`/`change.next` are the exact `PlanState` instances passed in | FR-001 | example | DONE | `…::PlanChanged carries emittedAt + the PlanChangedEvent payload` |
| A3  | The exhaustive `describe(EngineEvent)` switch routes `PlanChanged` to `plan_changed(<next plan id>)` | FR-003 | example | DONE | `…::describe(EngineEvent) switch routes PlanChanged to plan_changed(next plan id)` |
| A4  | Value semantics at birth: equal (`emittedAt`, `change`) ⇒ `==` and equal `hashCode`; varying either field ⇒ unequal; `toString` renders both fields | FR-004 | example | DONE | `…::PlanChanged value semantics (born with spec 066 pattern)` |
| A5  | `dart analyze --fatal-infos` exits 0 and `dart test` passes baseline + new | FR-005 | gate | DONE | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/events/plan_changed.dart` (part file — new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class PlanChanged extends EngineEvent` declared `part of 'engine_event.dart';` with `emittedAt` + `change` and a const all-required constructor | FR-001 | example | DONE | A1, A2 + mutants M1/M2 |
| U2  | `engine_event.dart` includes `part 'plan_changed.dart';` and imports the domain `PlanChangedEvent` | FR-002 | gate | DONE | compile gate + mutant M3 |

### Test file: `test/engine/events/engine_event_test.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | The shared `#24` group's `describe(EngineEvent)` switch is extended with the `PlanChanged` arm (exhaustive, no `default`) | FR-003 | example | DONE | shared switch test compiles and passes; mutant M4 proves the arm is load-bearing |
| U4  | `==` compares `emittedAt` AND `change`; `hashCode` = `Object.hash(emittedAt, change)`; `toString` = `PlanChanged(emittedAt: …, change: …)` | FR-004 | example | DONE | A4 + mutants M1/M2 |

## Invariants and edge cases

- `emittedAt` vs `change.emittedAt` are distinct instants (engine emission time vs plan-change application time) — the payload test constructs them differently.
- Empty plans (`steps: []`) render deterministically in `toString` without `PlanStep` noise — used for the exact-string assertion.
- Equality delegates to `PlanChangedEvent.==` (domain semantics, spec 014) — equal domain events with equal `emittedAt` produce equal engine events.

## Out of scope

- The engine-loop emission site (epic #2 successor work).
- Sibling subtypes' semantics (spec 066 / PR #77).
- JSON serialization (issue #15 / spec 015).

## Verification commands

- Single feature: `dart test test/engine/events/engine_event_test.dart --name "PlanChanged" --reporter expanded`
- Full suite: `dart test`
- Analyze gate: `dart analyze --fatal-infos`
- Mutation: deliberate mutants, one at a time, `cp`-restored (see `verification.md`)
