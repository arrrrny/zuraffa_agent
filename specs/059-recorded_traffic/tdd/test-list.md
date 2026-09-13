# Test List: 059-recorded_traffic

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart`). | AC-6 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 30]
route: A2 -> acceptance lane [declared: type marker, spec line 32]
route: A3 -> acceptance lane [declared: type marker, spec line 34]
route: A4 -> acceptance lane [declared: type marker, spec line 36]
route: A5 -> acceptance lane [declared: type marker, spec line 38]
route: A6 -> acceptance lane [declared: type marker, spec line 40]

