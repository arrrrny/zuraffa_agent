# Test List: 112-structured-logging

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | both records arrive at the sink carrying logger names `zuraffa.agent.llm` | AC-1 | PENDING |
| A2 | nothing is printed, nothing throws, and | AC-2 | PENDING |
| A3 | they are filtered out by the hierarchy and only | AC-3 | PENDING |
| A4 | transport is FINE, lifecycle is INFO, resilience (retry, | AC-4 | PENDING |
| A5 | a | AC-5 | PENDING |
| A6 | an INFO | AC-6 | PENDING |
| A7 | Type: acceptance | AC-7 | PENDING |
| A8 | there are zero matches (the engine | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `AgentLog` MUST expose the named subsystem loggers `llm`, | FR-001, AgentLog.logger | PENDING |
| U2 | The level policy MUST be pinned as facade constants — | FR-002, AgentLog.levelPolicy | PENDING |
| U3 | `ZuraffaLogging.install({level, onRecord})` MUST be the only | FR-003, AgentLog.install | PENDING |
| U4 | Emission MUST be safe and cheap before install: no listener | FR-004, AgentLog.logger | PENDING |
| U5 | The first adoption sites MUST ship with this spec: the LLM | FR-005, AgentLog.retryWarning | PENDING |
| U6 | ARCHITECTURE.md MUST document the logger hierarchy, the | FR-006, AgentLog.document | PENDING |

Seam cost: 3 of 6 unit behaviors will hand-step because return is an entity.

## Contract loop: contract behaviors

One per declared entity method, controller method and usecase in `spec.md` Layer Contracts (issue #1007). A contract test proves the implementation satisfies the DECLARED contract — a failing contract test is BLOCKED (never RED) and blocks the cycle from proceeding to GREEN.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| contract:A7 | AgentLog.logger(subsystem) -> Logger (usecase contract) | AgentLog.logger | PENDING |
| contract:A8 | AgentLog.install(level, onRecord) -> void (usecase contract) | AgentLog.install | PENDING |
| contract:A9 | AgentLog.levelPolicy() -> LevelTable (usecase contract) | AgentLog.levelPolicy | PENDING |
| contract:A10 | AgentLog.retryWarning(attempt, delay, error) -> void (usecase contract) | AgentLog.retryWarning | PENDING |
| contract:A11 | AgentLog.missionInfo(missionId, outcome) -> void (usecase contract) | AgentLog.missionInfo | PENDING |
| contract:A12 | AgentLog.document(hierarchy, policy, sinkRecipe) -> void (usecase contract) | AgentLog.document | PENDING |

## External dependencies

| dependency | type | contract | mock priority |
| ---------- | ---- | -------- | ------------- |
| package:logging | pub dependency | `Logger`, `Level`, `LogRecord`, `Logger.root.onRecord` | P1 |

## Layer contracts

### Domain

- `AgentLog`: `logger(subsystem) -> Logger`, `install(level, onRecord) -> void`, `levelPolicy() -> LevelTable`, `retryWarning(attempt, delay, error) -> void`, `missionInfo(missionId, outcome) -> void`, `document(hierarchy, policy, sinkRecipe) -> void`

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 68]
route: A2 -> acceptance lane [declared: type marker, spec line 74]
route: A3 -> acceptance lane [declared: type marker, spec line 78]
route: A4 -> acceptance lane [declared: type marker, spec line 97]
route: A5 -> acceptance lane [declared: type marker, spec line 101]
route: A6 -> acceptance lane [declared: type marker, spec line 106]
route: A7 -> acceptance lane [declared: type marker, spec line 126]
route: A8 -> acceptance lane [declared: type marker, spec line 131]
route: U1 -> unit lane [declared: contract row: AgentLog, spec line 178]
route: U2 -> unit lane [declared: contract row: AgentLog, spec line 178]
route: U3 -> unit lane [declared: contract row: AgentLog, spec line 178]
route: U4 -> unit lane [declared: contract row: AgentLog, spec line 178]
route: U5 -> unit lane [declared: contract row: AgentLog, spec line 178]
route: U6 -> unit lane [declared: contract row: AgentLog, spec line 178]
route: contract:A7 -> contract lane [declared: AgentLog]
route: contract:A8 -> contract lane [declared: AgentLog]
route: contract:A9 -> contract lane [declared: AgentLog]
route: contract:A10 -> contract lane [declared: AgentLog]
route: contract:A11 -> contract lane [declared: AgentLog]
route: contract:A12 -> contract lane [declared: AgentLog]

