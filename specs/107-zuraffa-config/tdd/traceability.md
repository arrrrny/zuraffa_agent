# Traceability: 107-zuraffa-config

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:ba3884f035c832c5952545225fbaeeb2c8479a4e380513f40820d4130c0d1106
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 72 | 1. **Given** a fully-populated configuration document, **When** it loads, **Then** every field is preserved in the typed sections, `validate()` returns no issues, and the runner accepts it. | A1 | automated |
| AC-2 | 85 | 2. **Given** an environment map (partial or full), **When** a configuration is produced from it, **Then** the corresponding sections populate, partial maps yield partial configurations, and unknown keys never become sections and never error. | A2 | automated |
| AC-3 | 101 | 3. **Given** a configuration with multiple problems, **When** `validate()` runs and the runner starts, **Then** the validation names each problem with its section and field, the runner throws before emitting any event or calling the engine, a valid configuration runs the mission unchanged, and no configuration preserves the pre-existing behavior. | A3 | automated |
| AC-4 | 114 | 4. **Given** the resolver interface, **When** it is inspected and exercised with absence, **Then** it exposes the three source kinds and the shipped stub resolves nothing (returns absence) and never throws. | A4 | automated |
| FR-001 | 132 | - **FR-001**: `ZuraffaConfig` aggregates the six sections, each | U2 | automated |
| FR-002 | 136 | - **FR-002**: the YAML loader parses a document into the typed | U8 | automated |
| FR-003 | 140 | - **FR-003**: the environment loader maps documented variables to | U10 | automated |
| FR-004 | 144 | - **FR-004**: `validate()` returns typed issues — `missing` (a | U5 | automated |
| FR-005 | 150 | - **FR-005**: `MissionRunner.run` with a configuration that fails | U14 | automated |
| FR-006 | 155 | - **FR-006**: the `SecretResolver` interface exposes the three source | U11 | automated |

