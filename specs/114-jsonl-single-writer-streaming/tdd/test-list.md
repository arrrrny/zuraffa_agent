# Test List: 114-jsonl-single-writer-streaming

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | every entry | AC-1 | PENDING |
| A2 | acquisition fails fast | AC-2 | PENDING |
| A3 | iteration stops without requiring | AC-3 | PENDING |
| A4 | the same entry set is yielded as | AC-4 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | Every `JsonlSessionStorage` mutation (`appendEntry`, | FR-001, JsonlSessionStorage.guard | PENDING |
| U2 | `JsonlSessionStorage.init` MUST acquire an advisory | FR-002, SessionLock.acquire | PENDING |
| U3 | `SessionStorage.entries()` MUST return a lazy | FR-003, SessionStorage.entries | PENDING |
| U4 | Hive persistence MUST document its single-writer | FR-004, SessionStorage.entries | PENDING |

## Contract loop: contract behaviors

One per declared entity method, controller method and usecase in `spec.md` Layer Contracts (issue #1007). A contract test proves the implementation satisfies the DECLARED contract — a failing contract test is BLOCKED (never RED) and blocks the cycle from proceeding to GREEN.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| contract:A1 | SessionLock.acquire() -> Future<void> (usecase contract) | SessionLock.acquire | PENDING |
| contract:A2 | SessionLock.release() -> Future<void> (usecase contract) | SessionLock.release | PENDING |
| contract:A3 | JsonlSessionStorage.guard(mutation) -> Future<void> (usecase contract) | JsonlSessionStorage.guard | PENDING |

## External dependencies

| dependency | type | contract | mock priority |
| ---------- | ---- | -------- | ------------- |
| package:synchronized | pub dependency | `Lock` critical-section mutex | P1 |
| Hive | pub dependency | hive_ce `Box<K>` lazy key iteration (`keys`, `getAt`) | P1 |
| dart:io | SDK (quarantined) | `File.lock` advisory sidecar locking | P1 |

## Layer contracts

### Domain

- `SessionLock`: `acquire() -> Future<void>`, `release() -> Future<void>`
- `JsonlSessionStorage`: `guard(mutation) -> Future<void>`

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 59]
route: A2 -> acceptance lane [declared: type marker, spec line 64]
route: A3 -> acceptance lane [declared: type marker, spec line 83]
route: A4 -> acceptance lane [declared: type marker, spec line 87]
route: U1 -> unit lane [declared: contract row: JsonlSessionStorage, spec line 119]
route: U2 -> unit lane [declared: contract row: SessionLock, spec line 118]
route: U3 -> refused [danglingReference: behavior "U3" traces to "SessionStorage.entries", which names no declared contract row (Key Entities, Layer Contracts, or External Dependencies).]
route: U4 -> refused [danglingReference: behavior "U4" traces to "SessionStorage.entries", which names no declared contract row (Key Entities, Layer Contracts, or External Dependencies).]
route: contract:A1 -> contract lane [declared: SessionLock]
route: contract:A2 -> contract lane [declared: SessionLock]
route: contract:A3 -> contract lane [declared: JsonlSessionStorage]

