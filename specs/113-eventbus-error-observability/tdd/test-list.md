# Test List: 113-eventbus-error-observability

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the later subscriber still receives the event and a SEVERE | AC-1 | PENDING |
| A2 | the hook is invoked with the | AC-2 | PENDING |
| A3 | exactly one | AC-3 | PENDING |
| A4 | no NEW `EngineEventSubscriberError` is published (the | AC-4 | PENDING |
| A5 | `publish` still returns normally, later | AC-5 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | With no consumer hook installed, the bus MUST route | FR-001, EngineEventBus.logSubscriberError | PENDING |
| U2 | A consumer-provided `onSubscriberError` hook MUST fully | FR-002, EngineEventBus.logSubscriberError | PENDING |
| U3 | After the error route runs, the bus MUST publish an | FR-003, EngineEventBus.subscriberErrorEvent | PENDING |
| U4 | A throwing hook or a throwing subscriber of the | FR-004, EngineEventBus.logSubscriberError | PENDING |

Seam cost: 1 of 4 unit behaviors will hand-step because return is an entity.

## Contract loop: contract behaviors

One per declared entity method, controller method and usecase in `spec.md` Layer Contracts (issue #1007). A contract test proves the implementation satisfies the DECLARED contract — a failing contract test is BLOCKED (never RED) and blocks the cycle from proceeding to GREEN.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| contract:A1 | EngineEventBus.logSubscriberError(error, event) -> void (usecase contract) | EngineEventBus.logSubscriberError | PENDING |
| contract:A3 | EngineEventBus.subscriberErrorEvent(error, event) -> EngineEventSubscriberError (usecase contract) | EngineEventBus.subscriberErrorEvent | PENDING |

## External dependencies

| dependency | type | contract | mock priority |
| ---------- | ---- | -------- | ------------- |
| AgentLog (spec 112) | internal facade | `eventBus` logger + SEVERE policy level | P1 |

## Layer contracts

### Domain

- `EngineEventBus`: `logSubscriberError(error, event) -> void`, `subscriberErrorEvent(error, event) -> EngineEventSubscriberError`

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 59]
route: A2 -> acceptance lane [declared: type marker, spec line 65]
route: A3 -> acceptance lane [declared: type marker, spec line 89]
route: A4 -> acceptance lane [declared: type marker, spec line 94]
route: A5 -> acceptance lane [declared: type marker, spec line 99]
route: U1 -> unit lane [declared: contract row: EngineEventBus, spec line 137]
route: U2 -> unit lane [declared: contract row: EngineEventBus, spec line 137]
route: U3 -> unit lane [declared: contract row: EngineEventBus, spec line 137]
route: U4 -> unit lane [declared: contract row: EngineEventBus, spec line 137]
route: contract:A1 -> contract lane [declared: EngineEventBus]
route: contract:A3 -> contract lane [declared: EngineEventBus]

