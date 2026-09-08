# Traceability: 038-ui-tree-payload

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:600105f81f131d0a5b51c312a264a4c8f2d5c243efe7df20d99e196b815011b4
statements: 14
automated: 14
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a payload with a 3-level tree, **When** serialized with `toJson()` and parsed with `fromJson`, **Then** the parsed payload equals the original (fields, tree, depth, nodeCount) and its `toJson()` is deep-equal to the first. | A1 | automated |
| AC-2 | 27 | 2. **Given** a JSON map with `mimeType` absent, or set to `"application/json"`, **When** parsed, **Then** `ArgumentError` naming `mimeType` is thrown. | A2 | automated |
| AC-3 | 29 | 3. **Given** a JSON map with an empty `vocabularyId`/`schemaVersion` or a `tree` that is not a `Map`, **When** parsed, **Then** `ArgumentError` is thrown naming the offending field. | A3 | automated |
| AC-4 | 44 | 4. **Given** two payloads with identical pinning where b adds a child, removes a child, and modifies a props value, **When** diffed, **Then** exactly those three paths appear in `addedPaths`/`removedPaths`/`changedPaths` and `hasChanges` is true. | A4 | automated |
| AC-5 | 46 | 5. **Given** two payloads with identical trees but different `vocabularyId` (or `schemaVersion`), **When** diffed, **Then** the structural paths are empty but `vocabularyChanged` (or `schemaChanged`) is true and `hasChanges` is true. | A5 | automated |
| AC-6 | 48 | 6. **Given** two identical payloads, **When** diffed, **Then** all delta collections are empty, both pin flags false, `hasChanges` false. | A6 | automated |
| AC-7 | 63 | 7. **Given** nested trees of depth 3 / 5 nodes, **When** constructed, **Then** `depth == 3` and `nodeCount == 5` (pinned by existing tests). | A7 | automated |
| AC-8 | 65 | 8. **Given** empty `vocabularyId` or `schemaVersion`, **When** constructed, **Then** `ArgumentError` (pinned by existing tests). | A8 | automated |
| FR-001 | 80 | - **FR-001**: `toJson()` MUST produce a `Map<String, dynamic>` with exactly the keys `mimeType` (the constant `'ui/tree+json'`), `vocabularyId`, `schemaVersion`, and `tree`. | U1 | automated |
| FR-002 | 81 | - **FR-002**: `UiTreePayload.fromJson(Map<String, dynamic> json)` MUST validate: `mimeType` present AND equal to the `mimeType` constant (else `ArgumentError` naming `mimeType`); `vocabularyId`/`schemaVersion` non-empty strings (else `ArgumentError` naming the field); `tree` a `Map<String, dynamic>` (else `ArgumentError` naming `tree`). On success it MUST construct via the standard constructor (inheriting its validation and depth/nodeCount precomputation) so `fromJson(toJson(p)) == p`. | U2 | automated |
| FR-003 | 82 | - **FR-003**: `diff(UiTreePayload other)` MUST return a `UiTreeDiff` value object with: `addedPaths` (paths present in other's tree, absent in this one), `removedPaths` (reverse), `changedPaths` (same path, deep-unequal node maps) — paths are `'root'` or child-index chains like `'0/1'` (the `children` list index path, `/`-joined) — plus `vocabularyChanged` and `schemaChanged` booleans, and a derived `hasChanges` getter (any collection non-empty OR either flag true). | U3 | automated |
| FR-004 | 83 | - **FR-004**: `UiTreeDiff` MUST be a plain value object (equality across all six fields, `toString` summarizing counts) living beside the payload in the same entity file. | U4 | automated |
| FR-005 | 84 | - **FR-005**: The shipped construction validation, `computeDepth`/`computeNodeCount`, `mimeType` constant, and deep equality/hashCode MUST keep their semantics (pinned by the 8 pre-existing payload tests, unchanged). | U5 | automated |
| FR-006 | 85 | - **FR-006**: The clean-arch layers (`UiTreePayloadService.current/count`, `UiTreePayloadProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature. | U6 | automated |

