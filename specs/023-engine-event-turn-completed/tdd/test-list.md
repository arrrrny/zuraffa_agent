# Test List: EngineEvent.TurnCompleted

---
feature: 023-engine-event-turn-completed
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 4 # acceptance criteria SC-001, SC-002 + FR-001..FR-004 in spec.md
planned_at: 4cdf63b
updated_at: HEAD
suite_baseline: green # full suite green at parent commit; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Outer loop: acceptance behaviors

Per `spec.md`'s Verification section, the acceptance behaviors for this
spec are exercised through `test/engine/events/engine_event_test.dart`
(this is a library feature; the public `EngineEvent` library is the
entry surface).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `TurnCompleted` is `is EngineEvent` AND `is TurnCompleted` | FR-001, SC-001 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#23 — EngineEvent.TurnCompleted::TurnCompleted is an EngineEvent` |
| A2  | `TurnCompleted` carries `emittedAt` and optional `reason` (null on normal completion, set on early termination: `cancelled`, `max-tokens-reached`, `tool-error-limit`) | FR-001, SC-002 | example | DONE | `test/engine/events/engine_event_test.dart::…::TurnCompleted carries emittedAt + optional reason` + `…::TurnCompleted.reason defaults to null on normal completion` |
| A3  | `dart analyze --fatal-infos` exits 0 | FR-004, SC-001 | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |
| A4  | `dart test` passes all 139 + new tests | FR-004, SC-002 | gate | DONE | 529 tests pass at HEAD |

## Inner loop: unit behaviors

### `lib/src/engine/events/turn_completed.dart` (part file)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class TurnCompleted extends EngineEvent` declared as `part of 'engine_event.dart';` with `final DateTime emittedAt; final String? reason;` and a `const TurnCompleted({required this.emittedAt, this.reason})` constructor — value semantics, immutable | FR-001 | example | DONE | A1, A2 (above) |

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U2  | `engine_event.dart` includes `part 'turn_completed.dart';` directive, picked up by the sealed library | FR-002 | gate | DONE | CI Analyze gate |

### Test file: `test/engine/events/engine_event_test.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | The existing `describe(EngineEvent)` `switch` is updated to handle both `TurnStarted` and `TurnCompleted` cases (exhaustive with no `default` arm) — extends the `switch` from PR #33 with the new case | FR-003 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#24 — sealed EngineEvent library::switch over EngineEvent is exhaustive with all current subtypes` (handles all 9 subtypes including TurnCompleted) |

## Invariants and edge cases still to place

- `reason = null` on normal completion: covered by `…::TurnCompleted.reason defaults to null on normal completion`.
- Specific reason strings (`cancelled`, `max-tokens-reached`, `tool-error-limit`): not asserted at the type level — the dispatcher is the right enforcement site (out of scope, spec-002). The test asserts a representative reason string round-trips; a dispatcher-level enum would replace the free-form `String?`.

## Out of scope

- The 8 sibling event subtypes — each has its own spec.
- The concrete engine loop that emits `TurnCompleted` — spec-002.
- json_serializable for `TurnCompleted` — issue #15.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test test/engine/events/engine_event_test.dart --name "TurnCompleted" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; profile forbids mid-loop dep additions)
- Mutation: none installed — deliberate mutants per rubric (see `verification.md`)
