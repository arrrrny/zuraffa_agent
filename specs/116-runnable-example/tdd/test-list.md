# Test List: 116-runnable-example

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | it exits 0 and prints | AC-1 | PENDING |
| A2 | it | AC-2 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The example MUST run a full mission through `MissionRunner` | FR-001, MinimalAgent.run | PENDING |
| U2 | The example MUST print the mission lifecycle (start, | FR-002, MinimalAgent.transcript | PENDING |
| U3 | A test MUST execute the example as a subprocess and assert | FR-003, MinimalAgent.subprocess | PENDING |

## Contract loop: contract behaviors

One per declared entity method, controller method and usecase in `spec.md` Layer Contracts (issue #1007). A contract test proves the implementation satisfies the DECLARED contract — a failing contract test is BLOCKED (never RED) and blocks the cycle from proceeding to GREEN.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| contract:A1 | MinimalAgent.run() -> Future<MissionResult> (usecase contract) | MinimalAgent.run | PENDING |
| contract:A2 | MinimalAgent.transcript(events) -> List<String> (usecase contract) | MinimalAgent.transcript | PENDING |
| contract:A3 | MinimalAgent.subprocess() -> ProcessResult (usecase contract) | MinimalAgent.subprocess | PENDING |

## External dependencies

| dependency | type | contract | mock priority |
| ---------- | ---- | -------- | ------------- |
| dart:io | SDK (test/example only) | `Process.run` for the subprocess check | P1 |

## Layer contracts

### Domain

- `MinimalAgent`: `run() -> Future<MissionResult>`, `transcript(events) -> List<String>`, `subprocess() -> ProcessResult`

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 47]
route: A2 -> acceptance lane [declared: type marker, spec line 52]
route: U1 -> unit lane [declared: contract row: MinimalAgent, spec line 79]
route: U2 -> unit lane [declared: contract row: MinimalAgent, spec line 79]
route: U3 -> unit lane [declared: contract row: MinimalAgent, spec line 79]
route: contract:A1 -> contract lane [declared: MinimalAgent]
route: contract:A2 -> contract lane [declared: MinimalAgent]
route: contract:A3 -> contract lane [declared: MinimalAgent]

