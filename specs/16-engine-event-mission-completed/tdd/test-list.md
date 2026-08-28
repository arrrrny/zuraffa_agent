# Test List: EngineEvent.MissionCompleted

---
feature: 016-engine-event-mission-completed
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — constitution.md gates applied instead (see verification.md)
spec_criteria: 4 # acceptance criteria SC-001, SC-002 + FR-001..FR-004 in spec.md
planned_at: 30b4b94 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 911 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at 30b4b94; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Context at cycle start

`MissionCompleted` (part file, `part` directive, sealed-switch arm, is-A +
payload tests) landed on master via PR #42 (`32496b6`, closed issue #16)
before this TDD pass ran. This cycle therefore closes the two gaps that
remained against the spec's TDD obligations:

1. `specs/16-engine-event-mission-completed/tdd/` artifacts did not exist.
2. Behavioral coverage was partial: the `describe(EngineEvent)` routing for
   `MissionCompleted` was never asserted, and `summary` was constructed
   `null` in every test without ever being asserted (non-null round-trip
   untested; distinct-payload mutants undetectable).

## Outer loop: acceptance behaviors

Per `spec.md`'s Verification section, the acceptance behaviors for this
spec are exercised through `test/engine/events/engine_event_test.dart`
(this is a library feature; the public `EngineEvent` library is the
entry surface).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `MissionCompleted` is `is EngineEvent` AND `is MissionCompleted` | FR-001, SC-001 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#16 — EngineEvent.MissionCompleted::MissionCompleted is an EngineEvent` (landed with #42; re-verified this cycle) |
| A2  | `MissionCompleted` carries `emittedAt`, `missionId`, `status` with distinct values AND `summary: String?` round-trips both a non-null terminal summary and `null` | FR-001, SC-002 | example | DONE | `…::MissionCompleted carries payload fields` (strengthened this cycle: distinct missionId/status/summary values) + `…::MissionCompleted.summary is nullable and round-trips null` (new this cycle) |
| A3  | `dart analyze --fatal-infos` exits 0 | FR-004, SC-001 | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |
| A4  | `dart test` passes all 911 baseline + new tests | FR-004, SC-002 | gate | DONE | full suite green at HEAD (see verification.md for exact counts) |

## Inner loop: unit behaviors

### `lib/src/engine/events/mission_completed.dart` (part file — landed via #42)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class MissionCompleted extends EngineEvent` declared as `part of 'engine_event.dart';` with `final DateTime emittedAt; final String missionId; final String status; final String? summary;` and a `const` all-required constructor — value semantics, immutable | FR-001 | example | DONE | A1, A2 (above); proven by mutants M1/M2 |
| U2  | `missionId` and `status` constructor parameters bind to the fields of the same name (no cross-binding) | FR-001 | example | DONE | A2 distinct-values assertions; proven by mutant M2 |

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | `engine_event.dart` includes `part 'mission_completed.dart';` directive, picked up by the sealed library | FR-002 | gate | DONE | CI Analyze gate; proven by mutant M3 |

### Test file: `test/engine/events/engine_event_test.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | The `describe(EngineEvent)` `switch` handles `MissionCompleted` (exhaustive with no `default` arm) and routes it to `mission_completed(<missionId>)` — extends the `switch` from PR #33/#42 with an asserted routing case | FR-003 | example | DONE | `…::describe(EngineEvent) switch routes MissionCompleted to mission_completed(missionId)` (new this cycle; the shared #24 group switch already carries the arm — this test asserts its output) |

## Invariants and edge cases still to place

- `summary = null` (cancelled mission with no summary): covered by
  `…::MissionCompleted.summary is nullable and round-trips null`.
- Specific `status` strings (`success`, `fail`, `cancelled`): not asserted
  at the type level — the mission runner is the right enforcement site
  (out of scope, spec-002/spec-005). The tests assert representative
  distinct status strings round-trip.
- `emittedAt` vs mission end time: the spec carries no separate
  `completedAt`; `emittedAt` is the single timestamp (matches merged
  #42 shape — no drift).

## Out of scope

- The 8 sibling event subtypes — each has its own spec (017 and 018
  follow this one; the other six predate it).
- The concrete engine loop / mission runner that emits
  `MissionCompleted` — spec-002 / spec-005.
- json_serializable / Zorphy annotations for `MissionCompleted` —
  issue #15 / spec-015-engine-event-json-part.
- Re-landing the class itself: landed via merged PR #42; this cycle
  completes the spec-kit TDD artifacts and closes the coverage gaps.

## Verification commands

- Single feature: `dart test test/engine/events/engine_event_test.dart --name "MissionCompleted" --reporter expanded`
- Full suite: `dart test`
- Analyze gate: `dart analyze --fatal-infos`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; adding deps mid-loop is forbidden)
- Mutation: no mutation tool installed — deliberate mutants per rubric (see `verification.md`)
