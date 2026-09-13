# Test List: 081-steering-message

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-10 | PENDING |
| A11 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-11 | PENDING |
| A12 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-12 | PENDING |
| A13 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-13 | PENDING |
| A14 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-14 | PENDING |
| A15 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-15 | PENDING |
| A16 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-16 | PENDING |
| A17 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-17 | PENDING |
| A18 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-18 | PENDING |
| A19 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-19 | PENDING |
| A20 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-20 | PENDING |
| A21 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-21 | PENDING |
| A22 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-22 | PENDING |
| A23 | the pinned regression test passes (`test/domain/entities/steering_message/steering_message_test.dart`). | AC-23 | PENDING |
| A24 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-24 | PENDING |
| A25 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-25 | PENDING |
| A26 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-26 | PENDING |
| A27 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-27 | PENDING |
| A28 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-28 | PENDING |
| A29 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-29 | PENDING |
| A30 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-30 | PENDING |
| A31 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-31 | PENDING |
| A32 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-32 | PENDING |
| A33 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-33 | PENDING |
| A34 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-34 | PENDING |
| A35 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-35 | PENDING |
| A36 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-36 | PENDING |
| A37 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-37 | PENDING |
| A38 | the pinned regression test passes (`test/domain/entities/steering_queue/steering_queue_test.dart`). | AC-38 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `SteeringMessage` MUST be a value object with three | FR-001 | PENDING |
| U2 | `SteeringMessage.toJson()` MUST return a | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: `SteeringMessage.fromJson(Map<String, dynamic> json)` | FR-003 | PENDING |
| U4 | `SteeringMessage.fromJson` MUST throw `ArgumentError` | FR-004 | PENDING |
| U5 | `SteeringMessage.==` MUST return `true` iff both | FR-005 | PENDING |
| U6 | Edge cases that MUST round-trip losslessly: | FR-006 | PENDING |
| U7 | `SteeringMessage.toString()` MUST return a human-readable | FR-007 | PENDING |
| U8 | The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the | FR-008 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A2 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A3 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A4 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A5 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A6 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A7 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A8 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A9 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A10 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A11 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A12 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A13 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A14 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A15 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A16 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A17 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A18 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A19 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A20 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A21 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A22 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A23 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A24 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A25 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A26 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A27 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A28 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A29 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A30 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A31 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A32 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A33 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A34 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A35 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A36 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A37 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A38 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

