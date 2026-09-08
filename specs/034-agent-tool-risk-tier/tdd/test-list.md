# Test List: 034-agent-tool-risk-tier

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | each maps to its tier, and `name` round-trips the string back. | AC-1 | PENDING |
| A2 | an `ArgumentError` names the input — never a silent `safe` fallback. | AC-2 | PENDING |
| A3 | `safe` dispatches free, `confirm` pauses for approval, `admin` additionally requires a grant (pinned by the existing enum tests; the tier-parse is the new surface). | AC-3 | PENDING |
| A4 | the parsed tool equals the original on every field including the deep params schema. | AC-4 | PENDING |
| A5 | the `paramsSchema` key is absent — never `null`, never an empty map masquerading as a schema. | AC-5 | PENDING |
| A6 | an `ArgumentError` names the offending field — never a silent default tier (which would under-classify). | AC-6 | PENDING |
| A7 | the hashCodes are equal (the scaffold's live violation — genuinely red today). | AC-7 | PENDING |
| A8 | the tools remain equal with equal hashes (order-independent fold). | AC-8 | PENDING |
| A9 | they are unequal (the existing per-axis test pins this; the hash side follows the fix). | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: The `AgentTool` value object keeps its spec-exact five-field surface — `id`, `description`, `riskTier` (default `safe`), `executionMode` (default `sequential`), `paramsSchema?` — with value equality (deep `_mapEq` on the schema), `requiresConfirmation`, `isAdmin`, and the enum surfaces unchanged (compile parity with the 10 existing tests). | FR-001 | PENDING |
| U2 | `RiskTier.fromString(String value)` MUST parse `'safe'`/`'confirm'`/`'admin'` exactly (case-significant) and MUST throw `ArgumentError` naming the input for anything else — never a silent default. `RiskTier.name` (the enum's built-in) round-trips the wire string. | FR-002 | PENDING |
| U3 | `ExecutionMode.fromString(String value)` MUST parse `'sequential'`/`'parallel'` with the same typed-failure discipline (consumed by FR-004). | FR-003 | PENDING |
| U4 | `toJson()` MUST emit `id`, `description`, `riskTier` (tier name), `executionMode` (mode name) always and `paramsSchema` only when non-null (absent-never-fabricated); `AgentTool.fromJson` MUST round-trip all five fields (schema deep-copied) and MUST throw `ArgumentError` naming the field on missing required keys, unknown tier/mode strings, or a non-map schema. | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: The dispatch-policy reads (`RiskTier.severity`, `requiresConfirmation`, `isAdmin`) keep their existing semantics — the classification consumed by dispatch/approval (R3.2); pinned by the existing enum tests. | FR-005 | PENDING |
| U6 | `hashCode` MUST be consistent with `==`: an order-independent fold over the params schema entries (commutative sum of per-entry hashes, nested maps folded recursively) combined with `Object.hash(id, description, riskTier, executionMode)` — fixing the scaffold's live violation where equal tools with distinct-but-equal schema instances hash differently. | FR-006 | PENDING |
| U7 | The system MUST satisfy this requirement: The clean-arch layers (`AgentToolService.current/count`, `AgentToolProvider`) keep their existing signatures and stubs (no behavioral change — the classification + persistence + hash semantics are the deliverable). | FR-007 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 28]
route: A2 -> acceptance lane [declared: type marker, spec line 30]
route: A3 -> acceptance lane [declared: type marker, spec line 32]
route: A4 -> acceptance lane [declared: type marker, spec line 47]
route: A5 -> acceptance lane [declared: type marker, spec line 49]
route: A6 -> acceptance lane [declared: type marker, spec line 51]
route: A7 -> acceptance lane [declared: type marker, spec line 66]
route: A8 -> acceptance lane [declared: type marker, spec line 68]
route: A9 -> acceptance lane [declared: type marker, spec line 70]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

