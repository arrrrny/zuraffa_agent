# Test List: 013-event-bus

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | each chunk event is delivered. | AC-1 | PENDING |
| A2 | all subscribers receive it. | AC-2 | PENDING |
| A3 | the handler's response is used. | AC-3 | PENDING |
| A4 | all listeners receive the event. | AC-4 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | An `EventBus` MUST support typed pub/sub (on<T>, emit<T>). | FR-001 | PENDING |
| U2 | An `EventBus` MUST support typed request/response (request<R>, registerHandler<T,R>). | FR-002 | PENDING |
| U3 | Events MUST be delivered synchronously in registration order. | FR-003 | PENDING |
| U4 | An `AgentController` MUST wrap EventBus with convenience methods. | FR-004 | PENDING |
| U5 | The engine MUST emit lifecycle events through the bus. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| EventBus |  |
| AgentController |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 41]
route: A4 -> acceptance lane [declared: type marker, spec line 54]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

