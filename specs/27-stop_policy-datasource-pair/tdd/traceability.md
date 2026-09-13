# Traceability: 27-stop_policy-datasource-pair

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:fafcc8a65cb0604c32ce5fe4502dd0a0c906d94cca0088130f4e93a50a91752e
statements: 12
automated: 12
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a fresh chain wired over the mock datasource, **When** `current` is called, **Then** the default policy is returned (`maxTurns=100`, `wallClockTimeout=0`, `repetitionThreshold=5`, `enabled=true`, `id='default'`). | A1 | automated |
| AC-2 | 27 | 2. **Given** a policy persisted via `update`, **When** `current` is called, **Then** the updated policy is returned — the read always reflects the last write. | A2 | automated |
| AC-3 | 42 | 3. **Given** any current policy, **When** `update(policy)` completes, **Then** `current()` returns a policy equal to the one written (full replace; value objects are immutable). | A3 | automated |
| AC-4 | 44 | 4. **Given** a non-default policy active, **When** `reset()` is called, **Then** `current()` returns the default policy and any subsequent `update` starts again from a clean state. | A4 | automated |
| AC-5 | 59 | 5. **Given** the provider is constructed over a datasource, **When** any service method is called, **Then** the call is served by that datasource (observable through returned state); the repository consumes the same datasource for id-keyed access. | A5 | automated |
| AC-6 | 61 | 6. **Given** `getCurrent` is called with an id that matches no stored policy, **Then** a typed error surfaces (no silent default substitution — a wrong-id read is a wiring bug). | A6 | automated |
| FR-001 | 75 | - **FR-001**: The `StopPolicy` value object MUST expose the spec-002-exact surface (`id`, `maxTurns`, `wallClockTimeout`, `repetitionThreshold`, `enabled`) with value equality, and MUST carry the canonical default (`maxTurns=100`, `wallClockTimeout=0`, `repetitionThreshold=5`, `enabled=true`) as a single constant. | U1 | automated |
| FR-002 | 76 | - **FR-002**: The datasource interface MUST define the persistence contract for the single-instance value object: `current()`, `update(policy)`, `reset()` — all asynchronous. | U2 | automated |
| FR-003 | 77 | - **FR-003**: The mock datasource MUST implement the contract in memory: seeded with the default, `update` fully replaces, `reset` restores the default, `current` returns the live value. | U3 | automated |
| FR-004 | 78 | - **FR-004**: A concrete repository (`StopPolicyRepositoryImpl`) MUST implement the domain `StopPolicyRepository` (`getCurrent(id)`, `update(policy)`, `reset(id)`) by delegating to the datasource, raising `StateError` on an id mismatch. | U4 | automated |
| FR-005 | 79 | - **FR-005**: The provider MUST implement the domain `StopPolicyService` (`current(NoParams)`, `defaultPolicy(NoParams)`) by consuming the datasource's id-less `current()` for the live policy (the service surface is id-less by design — `NoParams`), and by returning the canonical default constant for `defaultPolicy`. The repository remains the id-keyed domain-facing seam over the same datasource; both consume the datasource. | U5 | automated |
| FR-006 | 80 | - **FR-006**: Constructor backward compatibility MUST hold: `StopPolicyProvider()` and `StopPolicyMockDatasource()` parameterless constructions keep compiling; the provider defaults its wiring to a fresh mock datasource. | U6 | automated |

