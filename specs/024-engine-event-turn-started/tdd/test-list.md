# Test List: 024-engine-event-turn-started

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | `dart analyze` reports no `invalid_use_of_type_outside_library` error. | AC-1 | PENDING |
| A2 | it succeeds with no `exhaustive_switch` warnings (the `switch` over `EngineEvent` in the test uses a `default` arm OR is checked with `is TurnStarted`). | AC-2 | PENDING |
| A3 | the switch is exhaustive when expanded as `switch (e) { case TurnStarted(): ... }`. | AC-3 | PENDING |
| A4 | `dart analyze` succeeds with no new errors. | AC-4 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `lib/src/engine/events/engine_event.dart` MUST declare `sealed class EngineEvent` with `part 'turn_started.dart';` and `part 'engine_event.g.dart';` directives. | FR-001 | PENDING |
| U2 | `lib/src/engine/events/turn_started.dart` MUST be `part of 'engine_event.dart';` and declare `final class TurnStarted extends EngineEvent` with a `const TurnStarted();` constructor and any payload fields the engine will emit (start-of-turn timestamp `DateTime`, optional `turnId` `String?`). | FR-002 | PENDING |
| U3 | `lib/src/engine/events/engine_event.dart` MUST export the `EngineEvent` library through `lib/zuraffa_agent.dart` (i.e., add `export 'src/engine/events/engine_event.dart';`). | FR-003 | PENDING |
| U4 | `dart analyze --fatal-infos` MUST report zero issues on `lib/` and on the new files in particular. | FR-004 | PENDING |
| U5 | A new test file at `test/engine/events/engine_event_test.dart` MUST assert: (a) `TurnStarted()` is `is EngineEvent`; (b) `TurnStarted()` is `is TurnStarted`; (c) a `switch` over `EngineEvent` with a single `TurnStarted` case + `default` compiles and runs. | FR-005 | PENDING |
| U6 | `dart test` MUST pass all pre-existing tests (now 134 after PR #32) + new tests = ≥ 137 passing. | FR-006 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

