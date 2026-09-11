# Test List: 115-agent-platform-packages

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | sessions/memory/artifacts | AC-1 | PENDING |
| A2 | it throws `StateError` naming the failure — never a | AC-2 | PENDING |
| A3 | the same value returns; after delete, the read returns null. | AC-3 | PENDING |
| A4 | an `ArgumentError` names the key requirement and | AC-4 | PENDING |
| A5 | each declares `zuraffa_agent` + the platform interface as | AC-5 | PENDING |
| A6 | the channel method names and argument maps match the | AC-6 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `AgentPlatform` MUST define the host seam — | FR-001, AgentPlatform.getAgentHome | PENDING |
| U2 | `AgentHomeResolver` MUST compose | FR-002, AgentHomeResolver.compose | PENDING |
| U3 | Secure-store operations MUST validate keys (non-empty, | FR-003, SecureStore.validate | PENDING |
| U4 | The federated packages MUST ship with correct pubspec | FR-004, FederatedBridge.structure | PENDING |
| U5 | The channel contract MUST be exactly: channel | FR-005, FederatedBridge.channel | PENDING |

Seam cost: 3 of 5 unit behaviors will hand-step because return is an entity.

## Contract loop: contract behaviors

One per declared entity method, controller method and usecase in `spec.md` Layer Contracts (issue #1007). A contract test proves the implementation satisfies the DECLARED contract — a failing contract test is BLOCKED (never RED) and blocks the cycle from proceeding to GREEN.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| contract:A1 | AgentPlatform.getAgentHome() -> Future<String?> (usecase contract) | AgentPlatform.getAgentHome | PENDING |
| contract:A2 | AgentPlatform.secureRead(key) -> Future<String?> (usecase contract) | AgentPlatform.secureRead | PENDING |
| contract:A3 | AgentPlatform.secureWrite(key, value) -> Future<void> (usecase contract) | AgentPlatform.secureWrite | PENDING |
| contract:A4 | AgentPlatform.secureDelete(key) -> Future<void> (usecase contract) | AgentPlatform.secureDelete | PENDING |
| contract:A5 | AgentHomeResolver.compose(home) -> AgentHomeLayout (usecase contract) | AgentHomeResolver.compose | PENDING |
| contract:A6 | SecureStore.validate(key) -> void (usecase contract) | SecureStore.validate | PENDING |
| contract:A7 | FederatedBridge.structure(packages) -> StructureReport (usecase contract) | FederatedBridge.structure | PENDING |
| contract:A8 | FederatedBridge.channel(method, args) -> Outcome (usecase contract) | FederatedBridge.channel | PENDING |

## External dependencies

| dependency | type | contract | mock priority |
| ---------- | ---- | -------- | ------------- |
| package:flutter/services | SDK (packages/ only) | `MethodChannel` bridge | P1 |

## Layer contracts

### Domain

- `AgentPlatform`: `getAgentHome() -> Future<String?>`, `secureRead(key) -> Future<String?>`, `secureWrite(key, value) -> Future<void>`, `secureDelete(key) -> Future<void>`
- `AgentHomeResolver`: `compose(home) -> AgentHomeLayout`
- `SecureStore`: `validate(key) -> void`
- `FederatedBridge`: `structure(packages) -> StructureReport`, `channel(method, args) -> Outcome`

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 73]
route: A2 -> acceptance lane [declared: type marker, spec line 78]
route: A3 -> acceptance lane [declared: type marker, spec line 97]
route: A4 -> acceptance lane [declared: type marker, spec line 100]
route: A5 -> acceptance lane [declared: type marker, spec line 121]
route: A6 -> acceptance lane [declared: type marker, spec line 127]
route: U1 -> unit lane [declared: contract row: AgentPlatform, spec line 175]
route: U2 -> unit lane [declared: contract row: AgentHomeResolver, spec line 176]
route: U3 -> unit lane [declared: contract row: SecureStore, spec line 177]
route: U4 -> unit lane [declared: contract row: FederatedBridge, spec line 178]
route: U5 -> unit lane [declared: contract row: FederatedBridge, spec line 178]
route: contract:A1 -> contract lane [declared: AgentPlatform]
route: contract:A2 -> contract lane [declared: AgentPlatform]
route: contract:A3 -> contract lane [declared: AgentPlatform]
route: contract:A4 -> contract lane [declared: AgentPlatform]
route: contract:A5 -> contract lane [declared: AgentHomeResolver]
route: contract:A6 -> contract lane [declared: SecureStore]
route: contract:A7 -> contract lane [declared: FederatedBridge]
route: contract:A8 -> contract lane [declared: FederatedBridge]

