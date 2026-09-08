# Test List: 068-engine-event-log

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/engine/events/engine_event_log_test.dart`). | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: `void add(EngineEvent event)` appends one event; `void addAll(Iterable<EngineEvent> events)` appends in iteration order. Order of insertion is preserved exactly on read-back. | FR-001 | PENDING |
| U2 | The system MUST satisfy this requirement: `List<EngineEvent> get events` returns an unmodifiable copy — mutating the returned list (add/remove/clear/element assignment) throws; mutations never propagate into the log. `int get length`, `bool get isEmpty`, `bool get isNotEmpty` reflect the append count. | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: `List<T> byType<T extends EngineEvent>()` returns the sub-list of events of exactly type `T`, in insertion order. `T? firstOfType<T extends EngineEvent>()` / `T? lastOfType<T extends EngineEvent>()` return the first/last such event or `null`. | FR-003 | PENDING |
| U4 | The system MUST satisfy this requirement: `List<EngineEvent> since(DateTime cutoff, {bool inclusive = true})` returns events with `emittedAt >= cutoff` (or `>` when `inclusive: false`), preserving order; `List<EngineEvent> before(DateTime cutoff, {bool inclusive = false})` mirrors it for `emittedAt <=`/`<` cutoff. Implementation note (design discovery during the red phase): the sealed base `EngineEvent` gains an abstract `DateTime get emittedAt;` — every subtype already carries the field, so all 9 conform without modification, and the temporal projections filter the whole union uniformly. | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911/2 at `30b4b94` + new tests). Engine purity preserved: pure Dart, no `dart:io`, no new dependencies. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 62]
route: A2 -> acceptance lane [declared: type marker, spec line 64]
route: A3 -> acceptance lane [declared: type marker, spec line 66]
route: A4 -> acceptance lane [declared: type marker, spec line 68]
route: A5 -> acceptance lane [declared: type marker, spec line 70]
route: A6 -> acceptance lane [declared: type marker, spec line 72]
route: A7 -> acceptance lane [declared: type marker, spec line 74]
route: A8 -> acceptance lane [declared: type marker, spec line 76]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

