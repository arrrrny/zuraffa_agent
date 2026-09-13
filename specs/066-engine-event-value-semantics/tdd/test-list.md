# Test List: 066-engine-event-value-semantics

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-10 | PENDING |
| A11 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-11 | PENDING |
| A12 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-12 | PENDING |
| A13 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-13 | PENDING |
| A14 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-14 | PENDING |
| A15 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-15 | PENDING |
| A16 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-16 | PENDING |
| A17 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-17 | PENDING |
| A18 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-18 | PENDING |
| A19 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-19 | PENDING |
| A20 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-20 | PENDING |
| A21 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-21 | PENDING |
| A22 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-22 | PENDING |
| A23 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-23 | PENDING |
| A24 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-24 | PENDING |
| A25 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-25 | PENDING |
| A26 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-26 | PENDING |
| A27 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-27 | PENDING |
| A28 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-28 | PENDING |
| A29 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-29 | PENDING |
| A30 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-30 | PENDING |
| A31 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-31 | PENDING |
| A32 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-32 | PENDING |
| A33 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-33 | PENDING |
| A34 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-34 | PENDING |
| A35 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-35 | PENDING |
| A36 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-36 | PENDING |
| A37 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-37 | PENDING |
| A38 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-38 | PENDING |
| A39 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-39 | PENDING |
| A40 | the pinned regression test passes (`test/engine/events/engine_event_test.dart`). | AC-40 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: Every `EngineEvent` subtype implements `operator ==` following the house pattern: `identical(this, other) || (other is T && runtimeType == other.runtimeType && <field-by-field equality>)`. Two events with identical field values are equal; events differing in ANY field are not. | FR-001 | PENDING |
| U2 | The system MUST satisfy this requirement: Every subtype overrides `hashCode` with `Object.hash(<all fields in declaration order>)`; equal objects have equal hashCodes. | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: Every subtype overrides `toString` as `TypeName(field: value, …)` covering ALL fields in declaration order (nullable fields render `null`; `DateTime` renders via its own `toString`). | FR-003 | PENDING |
| U4 | The system MUST satisfy this requirement: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911 passed / 2 pre-existing skips at `30b4b94` + new tests). | FR-004 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 59]
route: A2 -> acceptance lane [declared: type marker, spec line 61]
route: A3 -> acceptance lane [declared: type marker, spec line 63]
route: A4 -> acceptance lane [declared: type marker, spec line 65]
route: A5 -> acceptance lane [declared: type marker, spec line 67]
route: A6 -> acceptance lane [declared: type marker, spec line 69]
route: A7 -> acceptance lane [declared: type marker, spec line 71]
route: A8 -> acceptance lane [declared: type marker, spec line 73]
route: A9 -> acceptance lane [declared: type marker, spec line 75]
route: A10 -> acceptance lane [declared: type marker, spec line 77]
route: A11 -> acceptance lane [declared: type marker, spec line 79]
route: A12 -> acceptance lane [declared: type marker, spec line 81]
route: A13 -> acceptance lane [declared: type marker, spec line 83]
route: A14 -> acceptance lane [declared: type marker, spec line 85]
route: A15 -> acceptance lane [declared: type marker, spec line 87]
route: A16 -> acceptance lane [declared: type marker, spec line 89]
route: A17 -> acceptance lane [declared: type marker, spec line 91]
route: A18 -> acceptance lane [declared: type marker, spec line 93]
route: A19 -> acceptance lane [declared: type marker, spec line 95]
route: A20 -> acceptance lane [declared: type marker, spec line 97]
route: A21 -> acceptance lane [declared: type marker, spec line 99]
route: A22 -> acceptance lane [declared: type marker, spec line 101]
route: A23 -> acceptance lane [declared: type marker, spec line 103]
route: A24 -> acceptance lane [declared: type marker, spec line 105]
route: A25 -> acceptance lane [declared: type marker, spec line 107]
route: A26 -> acceptance lane [declared: type marker, spec line 109]
route: A27 -> acceptance lane [declared: type marker, spec line 111]
route: A28 -> acceptance lane [declared: type marker, spec line 113]
route: A29 -> acceptance lane [declared: type marker, spec line 115]
route: A30 -> acceptance lane [declared: type marker, spec line 117]
route: A31 -> acceptance lane [declared: type marker, spec line 119]
route: A32 -> acceptance lane [declared: type marker, spec line 121]
route: A33 -> acceptance lane [declared: type marker, spec line 123]
route: A34 -> acceptance lane [declared: type marker, spec line 125]
route: A35 -> acceptance lane [declared: type marker, spec line 127]
route: A36 -> acceptance lane [declared: type marker, spec line 129]
route: A37 -> acceptance lane [declared: type marker, spec line 131]
route: A38 -> acceptance lane [declared: type marker, spec line 133]
route: A39 -> acceptance lane [declared: type marker, spec line 135]
route: A40 -> acceptance lane [declared: type marker, spec line 137]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

