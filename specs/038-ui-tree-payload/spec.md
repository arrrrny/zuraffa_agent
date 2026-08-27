# Feature Specification: UiTreePayload value object (UI/tree+json)

**Feature Branch**: `038-ui-tree-payload`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation — serialization + diffing semantics added, criteria made measurable)

**Status**: Approved

**Input**: Verbatim task spec — "038-ui-tree-payload — UI tree snapshot payload (UI-aware agents). Existing: lib/src/data/providers/ui_tree_payload/ui_tree_payload_provider.dart, lib/src/domain/services/ui_tree_payload_service.dart, lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart. Spec + tests for serialization/diffing of the UI tree payload."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - ui/tree+json payloads cross boundaries as JSON (Priority: P1)

As the MCP tool boundary (spec 003 / issue #8), when a tool result or final mission output carries a UI tree, I serialize the payload to a plain JSON map — `mimeType` (`"ui/tree+json"`), `vocabularyId`, `schemaVersion`, `tree` — and parse it back losslessly on the other side, with the content type checked on entry: a payload whose `mimeType` is missing or different is rejected with `ArgumentError`, not misparsed.

**Why this priority**: The payload exists to cross process boundaries (ToolResult.structuredPayload, session tree, recorded traffic); without round-trip serialization the type is a dead end, and an unchecked mimeType silently corrupts the content-type contract.

**Independent Test**: `toJson()` produces exactly the four keys; `fromJson(toJson(p)) == p` (deep tree equality, recomputed depth/nodeCount); `fromJson` throws on missing/wrong `mimeType`, empty vocabularyId/schemaVersion, or a non-map `tree`.

**Acceptance Scenarios**:

1. **Given** a payload with a 3-level tree, **When** serialized with `toJson()` and parsed with `fromJson`, **Then** the parsed payload equals the original (fields, tree, depth, nodeCount) and its `toJson()` is deep-equal to the first.
2. **Given** a JSON map with `mimeType` absent, or set to `"application/json"`, **When** parsed, **Then** `ArgumentError` naming `mimeType` is thrown.
3. **Given** a JSON map with an empty `vocabularyId`/`schemaVersion` or a `tree` that is not a `Map`, **When** parsed, **Then** `ArgumentError` is thrown naming the offending field.

---

### User Story 2 - Two payloads diff into a structural delta (Priority: P2)

As the replay/record tooling (specs 059/060 lineage), I compare two ui/tree+json payloads — before vs. after a re-run — and need a typed delta: which nodes were added, removed, or changed (by child-index path), and whether the pinning (vocabulary/schema) drifted — so replay diffs can report UI changes without a second tree-walk DSL.

**Why this priority**: Diffing is the read-side of the record/replay pipeline; without it the payload is only storable, not comparable. Path-keyed deltas keep the report actionable.

**Independent Test**: `a.diff(b)` reports `addedPaths`/`removedPaths`/`changedPaths` by child-index path (`'root'` for the root, `'0/1'` for nested), plus `vocabularyChanged`/`schemaChanged` flags; identical trees yield an empty structural delta and `hasChanges == false`.

**Acceptance Scenarios**:

1. **Given** two payloads with identical pinning where b adds a child, removes a child, and modifies a props value, **When** diffed, **Then** exactly those three paths appear in `addedPaths`/`removedPaths`/`changedPaths` and `hasChanges` is true.
2. **Given** two payloads with identical trees but different `vocabularyId` (or `schemaVersion`), **When** diffed, **Then** the structural paths are empty but `vocabularyChanged` (or `schemaChanged`) is true and `hasChanges` is true.
3. **Given** two identical payloads, **When** diffed, **Then** all delta collections are empty, both pin flags false, `hasChanges` false.

---

### User Story 3 - Construction precomputes and validates (Priority: P3)

As the emitting tool, I construct the payload once and the cost model (depth/nodeCount for §8.3 budget caps) is precomputed; empty pinning fields are rejected at construction. Shipped behavior — pinned, not new.

**Why this priority**: The O(1) budget lookups and construction validation are what make the payload safe to gate on; they exist and stay pinned.

**Independent Test**: depth/nodeCount auto-compute on nested trees (existing tests); empty vocabularyId/schemaVersion throw (existing tests); deep equality (existing tests).

**Acceptance Scenarios**:

1. **Given** nested trees of depth 3 / 5 nodes, **When** constructed, **Then** `depth == 3` and `nodeCount == 5` (pinned by existing tests).
2. **Given** empty `vocabularyId` or `schemaVersion`, **When** constructed, **Then** `ArgumentError` (pinned by existing tests).

### Edge Cases

- `tree` with a `children` list containing non-map entries? → Walked but skipped by computeDepth/computeNodeCount (shipped); diff uses the same walk so paths stay consistent.
- Round-trip of a tree containing `null`/bool/num values? → Preserved (plain JSON map contract; deep-equality holds).
- Diff of payloads with different tree shapes at the same path? → Node comparison is by deep equality of the node map; a shape change is a `changedPath`, not add+remove.
- Diff root changes? → Root path `'root'` appears in `changedPaths`.
- Extra unknown keys in incoming JSON? → Rejected? No — ignored is NOT the contract: `fromJson` requires the four known keys and tolerates no others being *used*, but unknown keys are preserved inside `tree` only; top-level unknown keys are ignored (JSON forward-compatibility, documented assumption).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `toJson()` MUST produce a `Map<String, dynamic>` with exactly the keys `mimeType` (the constant `'ui/tree+json'`), `vocabularyId`, `schemaVersion`, and `tree`.
- **FR-002**: `UiTreePayload.fromJson(Map<String, dynamic> json)` MUST validate: `mimeType` present AND equal to the `mimeType` constant (else `ArgumentError` naming `mimeType`); `vocabularyId`/`schemaVersion` non-empty strings (else `ArgumentError` naming the field); `tree` a `Map<String, dynamic>` (else `ArgumentError` naming `tree`). On success it MUST construct via the standard constructor (inheriting its validation and depth/nodeCount precomputation) so `fromJson(toJson(p)) == p`.
- **FR-003**: `diff(UiTreePayload other)` MUST return a `UiTreeDiff` value object with: `addedPaths` (paths present in other's tree, absent in this one), `removedPaths` (reverse), `changedPaths` (same path, deep-unequal node maps) — paths are `'root'` or child-index chains like `'0/1'` (the `children` list index path, `/`-joined) — plus `vocabularyChanged` and `schemaChanged` booleans, and a derived `hasChanges` getter (any collection non-empty OR either flag true).
- **FR-004**: `UiTreeDiff` MUST be a plain value object (equality across all six fields, `toString` summarizing counts) living beside the payload in the same entity file.
- **FR-005**: The shipped construction validation, `computeDepth`/`computeNodeCount`, `mimeType` constant, and deep equality/hashCode MUST keep their semantics (pinned by the 8 pre-existing payload tests, unchanged).
- **FR-006**: The clean-arch layers (`UiTreePayloadService.current/count`, `UiTreePayloadProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature.

### Key Entities *(include if feature involves data)*

- **UiTreePayload** (value object, existing): + `toJson`/`fromJson` (FR-001/002) and `diff` (FR-003); nothing else changes.
- **UiTreeDiff** (NEW value object, same file): addedPaths/removedPaths/changedPaths + vocabularyChanged/schemaChanged + hasChanges (FR-004).
- **UiTreePayloadService / UiTreePayloadProvider** (existing interfaces): unchanged; pinned by the 3 clean-arch tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 3-level tree round-trips through toJson→fromJson with full equality (AC US1-1).
- **SC-002**: fromJson rejects missing mimeType, wrong mimeType, empty vocabularyId/schemaVersion, non-map tree — 5 error shapes (AC US1-2..3).
- **SC-003**: diff reports the exact added/removed/changed path sets on a mixed-change fixture and hasChanges flips (AC US2-1).
- **SC-004**: pinning drift flags fire with empty structural delta (AC US2-2); identical payloads yield an empty diff (AC US2-3).
- **SC-005**: All 11 pre-existing tests pass unchanged (FR-005/006).
- **SC-006**: `dart analyze` zero new findings vs the 5-issue baseline; full `dart test` green.

## Assumptions

- Paths are child-index chains (`'0/1'`), not node ids: the tree contract carries no id requirement, and index paths are stable for replay diffing of recorded trees.
- Top-level unknown JSON keys are ignored by `fromJson` (forward-compatibility); strict four-key output is only guaranteed for `toJson`.
- Diff compares structure the same way the walkers do (only `children` lists of maps); non-map children are invisible to both, consistently.
