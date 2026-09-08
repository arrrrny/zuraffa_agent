# Test List: 038-ui-tree-payload

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the parsed payload equals the original (fields, tree, depth, nodeCount) and its `toJson()` is deep-equal to the first. | AC-1 | PENDING |
| A2 | `ArgumentError` naming `mimeType` is thrown. | AC-2 | PENDING |
| A3 | `ArgumentError` is thrown naming the offending field. | AC-3 | PENDING |
| A4 | exactly those three paths appear in `addedPaths`/`removedPaths`/`changedPaths` and `hasChanges` is true. | AC-4 | PENDING |
| A5 | the structural paths are empty but `vocabularyChanged` (or `schemaChanged`) is true and `hasChanges` is true. | AC-5 | PENDING |
| A6 | all delta collections are empty, both pin flags false, `hasChanges` false. | AC-6 | PENDING |
| A7 | `depth == 3` and `nodeCount == 5` (pinned by existing tests). | AC-7 | PENDING |
| A8 | `ArgumentError` (pinned by existing tests). | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `toJson()` MUST produce a `Map<String, dynamic>` with exactly the keys `mimeType` (the constant `'ui/tree+json'`), `vocabularyId`, `schemaVersion`, and `tree`. | FR-001 | PENDING |
| U2 | `UiTreePayload.fromJson(Map<String, dynamic> json)` MUST validate: `mimeType` present AND equal to the `mimeType` constant (else `ArgumentError` naming `mimeType`); `vocabularyId`/`schemaVersion` non-empty strings (else `ArgumentError` naming the field); `tree` a `Map<String, dynamic>` (else `ArgumentError` naming `tree`). On success it MUST construct via the standard constructor (inheriting its validation and depth/nodeCount precomputation) so `fromJson(toJson(p)) == p`. | FR-002 | PENDING |
| U3 | `diff(UiTreePayload other)` MUST return a `UiTreeDiff` value object with: `addedPaths` (paths present in other's tree, absent in this one), `removedPaths` (reverse), `changedPaths` (same path, deep-unequal node maps) — paths are `'root'` or child-index chains like `'0/1'` (the `children` list index path, `/`-joined) — plus `vocabularyChanged` and `schemaChanged` booleans, and a derived `hasChanges` getter (any collection non-empty OR either flag true). | FR-003 | PENDING |
| U4 | `UiTreeDiff` MUST be a plain value object (equality across all six fields, `toString` summarizing counts) living beside the payload in the same entity file. | FR-004 | PENDING |
| U5 | The shipped construction validation, `computeDepth`/`computeNodeCount`, `mimeType` constant, and deep equality/hashCode MUST keep their semantics (pinned by the 8 pre-existing payload tests, unchanged). | FR-005 | PENDING |
| U6 | The clean-arch layers (`UiTreePayloadService.current/count`, `UiTreePayloadProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature. | FR-006 | PENDING |

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

