# Test List: 075-engine-event-bus

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: request/response (registerHandler / request): the draft's | FR-002 | PENDING |
| U2 | The system MUST satisfy this requirement: `AgentController`: with request/response deferred, the | FR-004 | PENDING |
| U3 | "engine MUST emit through the bus": the runtimes (PRs | FR-005 | PENDING |
| U4 | The system MUST satisfy this requirement: Typed subscription: `subscribe<T extends EngineEvent>( | FR-001 | PENDING |
| U5 | The system MUST satisfy this requirement: `publish(EngineEvent event)`: synchronous delivery, in | FR-002 | PENDING |
| U6 | The system MUST satisfy this requirement: Subscriber error isolation: a handler that throws must | FR-003 | PENDING |
| U7 | The system MUST satisfy this requirement: `cancel()` stops delivery (idempotent — double cancel is | FR-004 | PENDING |
| U8 | The system MUST satisfy this requirement: `replay(Iterable<EngineEvent> events)`: re-publishes the | FR-005 | PENDING |
| U9 | The system MUST satisfy this requirement: `subscriberCount`: the number of live subscriptions. | FR-006 | PENDING |
| U10 | The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` | FR-007 | PENDING |

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
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U9 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U10 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

