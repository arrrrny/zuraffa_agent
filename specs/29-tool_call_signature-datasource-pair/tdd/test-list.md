# Test List: 29-tool_call_signature-datasource-pair

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | a subsequent `lookup(signature.key)` returns the signature (round-trip). | AC-1 | PENDING |
| A2 | absence is reported (null / not-found — no throw, no phantom entry). | AC-2 | PENDING |
| A3 | both signatures are equal, hash equally, and their keys are identical. | AC-3 | PENDING |
| A4 | the signature is unequal to the version-1 signature and its key differs. | AC-4 | PENDING |
| A5 | the store holds one entry (idempotent capture — dedup at the datasource level too). | AC-5 | PENDING |
| A6 | it returns 3. | AC-6 | PENDING |
| A7 | `count` returns 0 and every `lookup` reports absence. | AC-7 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The `ToolCallSignature` value object MUST carry `toolName`, `argumentHash`, `version` (default 1) with value equality and hashCode across all three fields. | FR-001 | PENDING |
| U2 | `ToolCallSignature` MUST derive `id`/`key` from content — a stable canonical string of the form `toolName@version:argumentHash` — identical for equal signatures, different for any differing component. | FR-002 | PENDING |
| U3 | Constructor backward compatibility MUST hold: `ToolCallSignature(id: ...)` from the anemic scaffold keeps compiling, and a content-only constructor derives the key automatically. | FR-003 | PENDING |
| U4 | The datasource interface MUST define the persistence contract: `capture(signature)`, `lookup(key)`, `count()`, `reset()` — all asynchronous; plus the scaffolded `current()`/`reset()` semantics folded into the refined surface. | FR-004 | PENDING |
| U5 | `capture` MUST be idempotent per key — duplicate captures of equal signatures do not grow the store. | FR-005 | PENDING |
| U6 | `lookup` MUST return the captured signature for a known key and absence (null) for an unknown key — never throw for misses. | FR-006 | PENDING |
| U7 | The mock datasource MUST implement the contract in memory: a key-addressed map, seeded empty, `reset` clearing all entries. | FR-007 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 43]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 47]
route: A6 -> acceptance lane [declared: type marker, spec line 62]
route: A7 -> acceptance lane [declared: type marker, spec line 64]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

