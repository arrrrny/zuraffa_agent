# Test List: 27-stop_policy-datasource-pair

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the default policy is returned (`maxTurns=100`, `wallClockTimeout=0`, `repetitionThreshold=5`, `enabled=true`, `id='default'`). | AC-1 | PENDING |
| A2 | the updated policy is returned — the read always reflects the last write. | AC-2 | PENDING |
| A3 | `current()` returns a policy equal to the one written (full replace; value objects are immutable). | AC-3 | PENDING |
| A4 | `current()` returns the default policy and any subsequent `update` starts again from a clean state. | AC-4 | PENDING |
| A5 | the call is served by that datasource (observable through returned state); the repository consumes the same datasource for id-keyed access. | AC-5 | PENDING |
| A6 | a typed error surfaces (no silent default substitution — a wrong-id read is a wiring bug). | AC-6 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The `StopPolicy` value object MUST expose the spec-002-exact surface (`id`, `maxTurns`, `wallClockTimeout`, `repetitionThreshold`, `enabled`) with value equality, and MUST carry the canonical default (`maxTurns=100`, `wallClockTimeout=0`, `repetitionThreshold=5`, `enabled=true`) as a single constant. | FR-001 | PENDING |
| U2 | The datasource interface MUST define the persistence contract for the single-instance value object: `current()`, `update(policy)`, `reset()` — all asynchronous. | FR-002 | PENDING |
| U3 | The mock datasource MUST implement the contract in memory: seeded with the default, `update` fully replaces, `reset` restores the default, `current` returns the live value. | FR-003 | PENDING |
| U4 | A concrete repository (`StopPolicyRepositoryImpl`) MUST implement the domain `StopPolicyRepository` (`getCurrent(id)`, `update(policy)`, `reset(id)`) by delegating to the datasource, raising `StateError` on an id mismatch. | FR-004 | PENDING |
| U5 | The provider MUST implement the domain `StopPolicyService` (`current(NoParams)`, `defaultPolicy(NoParams)`) by consuming the datasource's id-less `current()` for the live policy (the service surface is id-less by design — `NoParams`), and by returning the canonical default constant for `defaultPolicy`. The repository remains the id-keyed domain-facing seam over the same datasource; both consume the datasource. | FR-005 | PENDING |
| U6 | Constructor backward compatibility MUST hold: `StopPolicyProvider()` and `StopPolicyMockDatasource()` parameterless constructions keep compiling; the provider defaults its wiring to a fresh mock datasource. | FR-006 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 43]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 60]
route: A6 -> acceptance lane [declared: type marker, spec line 62]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

