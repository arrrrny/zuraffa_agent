# Test List: 031-tool-result-value-object

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the parsed value equals the original (content, payload, isError all preserved). | AC-1 | PENDING |
| A2 | `isError` is still true and the content (error message) is preserved. | AC-2 | PENDING |
| A3 | the payload key is absent/null — not an empty object masquerading as data. | AC-3 | PENDING |
| A4 | content is a bounded summary, `artifactRef` is non-null, and `isSummarized` is true. | AC-4 | PENDING |
| A5 | the artifactRef (kind, id, uri) survives the round-trip. | AC-5 | PENDING |
| A6 | it is false and serialization omits the artifactRef. | AC-6 | PENDING |
| A7 | the hashCodes are equal (the contract the scaffold violates). | AC-7 | PENDING |
| A8 | they are unequal. | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The `ToolResult` value object MUST keep the spec-003-exact field surface — `content` (String), `structuredPayload` (Map?), `artifactRef` (ArtifactRef?) — with NO `id` field, and MUST add `isError` (bool, default false) as the success/error discriminator. | FR-001 | PENDING |
| U2 | Named constructors `ToolResult.success` and `ToolResult.error` MUST construct results with `isError` false/true respectively; `isError` participates in equality and hashCode. | FR-002 | PENDING |
| U3 | `toJson()` MUST produce a JSON map with `content`, `structuredPayload` (null-safe), `artifactRef` (nested kind/id/uri, null-safe), and `isError`; `ToolResult.fromJson` MUST round-trip all four fields exactly. | FR-003 | PENDING |
| U4 | The oversized path (`ToolResult.oversized`) MUST require a summary and an artifactRef; such results report `isSummarized == true` (artifactRef non-null). | FR-004 | PENDING |
| U5 | `isSummarized` MUST remain the derived getter (artifactRef != null) — true for any result carrying a ref, false otherwise; serialization omits a null artifactRef. | FR-005 | PENDING |
| U6 | Equality MUST compare content, structuredPayload (deep map equality), isError, and artifactRef; `hashCode` MUST be consistent with equality (equal results — including distinct-but-equal payload instances, any insertion order — hash equally) and MUST fold the payload in an order-independent way so payload-only differences stop colliding deterministically. | FR-006 | PENDING |
| U7 | The clean-arch layers (`ToolResultService.current/count`, `ToolResultProvider`) MUST keep their existing signatures and compile parity; the provider stubs remain UnimplementedError (no behavioral change in this feature — the value object semantics are the deliverable). | FR-007 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 47]
route: A6 -> acceptance lane [declared: type marker, spec line 49]
route: A7 -> acceptance lane [declared: type marker, spec line 64]
route: A8 -> acceptance lane [declared: type marker, spec line 66]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

