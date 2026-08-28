# Test List: EngineEvent.MissionStarted

---
feature: 017-engine-event-mission-started
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — constitution.md gates applied instead (see verification.md)
spec_criteria: 4 # acceptance criteria SC-001, SC-002 + FR-001..FR-004 in spec.md
planned_at: 30b4b94 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 911 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at 30b4b94; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Context at cycle start

`MissionStarted` (part file, `part` directive, sealed-switch arm, is-A +
payload tests) landed on master via PR #41 (`20737f0`-line history, closed
issue #17) before this TDD pass ran. This cycle closes the two gaps that
remained against the spec's TDD obligations:

1. `specs/17-engine-event-mission-started/tdd/` artifacts did not exist.
2. Behavioral coverage was partial: the `describe(EngineEvent)` routing
   for `MissionStarted` was never asserted, and every pre-existing test
   constructed `startedAt` equal to `emittedAt` (`fixedTime`) — a
   cross-binding or field-swap defect in the two timestamps was
   undetectable.

## Outer loop: acceptance behaviors

Per `spec.md`'s Verification section, the acceptance behaviors for this
spec are exercised through `test/engine/events/engine_event_test.dart`
(this is a library feature; the public `EngineEvent` library is the
entry surface).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `MissionStarted` is `is EngineEvent` AND `is MissionStarted` | FR-001, SC-001 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#17 — EngineEvent.MissionStarted::MissionStarted is an EngineEvent` (landed with #41; re-verified this cycle) |
| A2  | `MissionStarted` carries `emittedAt`, `missionId` AND `startedAt` as independently assertable values (two distinct timestamps round-trip to their own fields) | FR-001, SC-002 | example | DONE | `…::MissionStarted carries payload fields` (strengthened this cycle: distinct `emittedAt` vs `startedAt`) |
| A3  | `dart analyze --fatal-infos` exits 0 | FR-004, SC-001 | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |
| A4  | `dart test` passes all 911 baseline + new tests | FR-004, SC-002 | gate | DONE | full suite green at HEAD (see verification.md for exact counts) |

## Inner loop: unit behaviors

### `lib/src/engine/events/mission_started.dart` (part file — landed via #41)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class MissionStarted extends EngineEvent` declared as `part of 'engine_event.dart';` with `final DateTime emittedAt; final String missionId; final DateTime startedAt;` and a `const` all-required constructor — value semantics, immutable | FR-001 | example | DONE | A1, A2 (above); proven by mutants M1/M2 |
| U2  | `emittedAt` and `startedAt` constructor parameters bind to the fields of the same name (no cross-binding — the mission start time and the event emission time are distinct concepts) | FR-001 | example | DONE | A2 distinct-timestamps assertions; proven by mutant M2 |

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | `engine_event.dart` includes `part 'mission_started.dart';` directive, picked up by the sealed library | FR-002 | gate | DONE | CI Analyze gate; proven by mutant M3 |

### Test file: `test/engine/events/engine_event_test.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | The `describe(EngineEvent)` `switch` handles `MissionStarted` (exhaustive with no `default` arm) and routes it to `mission_started(<missionId>)` — extends the `switch` from PR #33/#41 with an asserted routing case | FR-003 | example | DONE | `…::describe(EngineEvent) switch routes MissionStarted to mission_started(missionId)` (new this cycle; the shared #24 group switch already carries the arm — this test asserts its output) |

## Invariants and edge cases still to place

- `startedAt` != `emittedAt` (mission scheduled/started earlier, event
  emitted at observation time): covered by the strengthened A2 with two
  distinct `DateTime.utc(...)` values.
- `missionId` non-empty: not asserted at the type level — the mission
  runner owns id validity (out of scope, spec-002/spec-005).
- Pairs with `MissionCompleted` (spec 016): the pairing is documented at
  the type level in doc comments; runtime pairing is the engine loop's
  concern (out of scope).

## Out of scope

- The 8 sibling event subtypes — each has its own spec (016 precedes,
  018 follows; the other six predate it).
- The concrete engine loop / mission runner that emits `MissionStarted`
  — spec-002 / spec-005.
- json_serializable / Zorphy annotations for `MissionStarted` —
  issue #15 / spec-015-engine-event-json-part.
- Re-landing the class itself: landed via merged PR #41; this cycle
  completes the spec-kit TDD artifacts and closes the coverage gaps.

## Verification commands

- Single feature: `dart test test/engine/events/engine_event_test.dart --name "MissionStarted" --reporter expanded`
- Full suite: `dart test`
- Analyze gate: `dart analyze --fatal-infos`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; adding deps mid-loop is forbidden)
- Mutation: no mutation tool installed — deliberate mutants per rubric (see `verification.md`)
