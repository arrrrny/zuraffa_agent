# Test List: 008-fallback-chain-runtime

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | B serves it; the mission observes only latency. [AC-1] | AC-1 | PENDING |
| A2 | a half-open probe routes real traffic back on success. [AC-2] | AC-2 | PENDING |
| A3 | the policy restarts on the next provider — never silently truncates. [AC-3] | AC-3 | PENDING |
| A4 | the breaker opens. [AC-4] | AC-4 | PENDING |
| A5 | the state transitions to half-open. [AC-5] | AC-5 | PENDING |
| A6 | the state transitions to closed. [AC-6] | AC-6 | PENDING |
| A7 | it matches the internal breaker states. [AC-7] | AC-7 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | A `FallbackChainClient` MUST wrap multiple `LlmClient` instances with automatic failover. | FR-001 | PENDING |
| U2 | Each provider MUST have an independent circuit breaker (open/half-open/closed). | FR-002 | PENDING |
| U3 | The chain MUST advance on connection error, timeout, 5xx, context overflow, or repeated 429. | FR-003 | PENDING |
| U4 | Mid-stream failures MUST restart on the next provider (configurable policy). | FR-004 | PENDING |
| U5 | A health snapshot API MUST expose chain state at any time. | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| FallbackChainClient |  |
| CircuitBreaker |  |
| ClientHealth |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 45]
route: A6 -> acceptance lane [declared: type marker, spec line 47]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

