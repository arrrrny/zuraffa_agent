---
feature: 038-ui-tree-payload
loop: inside-out
profile: .specify/memory/tdd-profile.md
spec_criteria: 7
planned_at: 43dffd7
updated_at: 7e69612
suite_baseline: green
---

# Test List: UiTreePayload value object (serialization + diffing slice)

## Outer loop: acceptance behaviors

Pure value object — the public API (toJson/fromJson/diff) is the entry point
the MCP boundary and replay tooling consume; `loop: inside-out`.

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| A1  | A 3-level tree round-trips toJson->fromJson with full equality                   | AC US1-1 | example         | DONE    | `ui_tree_payload_test.dart` (red @ `fda576f`) |
| A2  | fromJson rejects missing/wrong mimeType with ArgumentError naming mimeType      | AC US1-2 | example         | DONE    | `ui_tree_payload_test.dart` (red @ `fda576f`, M1/M1b killed) |
| A3  | fromJson rejects empty pinning fields and non-map tree                          | AC US1-3 | example         | DONE    | `ui_tree_payload_test.dart` (red @ `fda576f`) |
| A4  | diff reports the exact added/removed/changed path sets on a mixed fixture        | AC US2-1 | example         | DONE    | `ui_tree_payload_test.dart` (red @ `7e69612`, M2 killed) |
| A5  | Pinning drift flags fire with empty structural delta; identical payloads empty  | AC US2-2/3 | example       | DONE    | `ui_tree_payload_test.dart` (red @ `7e69612`) |
| A6  | depth/nodeCount precompute on nested trees (pin)                                | AC US3-1 | characterization | DONE (BASELINE) | `ui_tree_payload_provider_test.dart` |
| A7  | construction validation + deep equality (pin)                                  | AC US3-2 | characterization | DONE (BASELINE) | `ui_tree_payload_provider_test.dart` |

## Inner loop: unit behaviors

### `lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart`

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| U1  | toJson produces exactly mimeType/vocabularyId/schemaVersion/tree                | FR-001   | example         | DONE    | `ui_tree_payload_test.dart` (red @ `fda576f`, M3 killed) |
| U2  | fromJson: 5 error shapes (missing mimeType, wrong mimeType, empty vocab, empty schema, non-map tree) each ArgumentError naming the field | FR-002   | example | DONE    | `ui_tree_payload_test.dart` (red @ `fda576f`, M1/M1b killed) |
| U3  | diff: added/removed/changed paths exact on mixed fixture; hasChanges true        | FR-003   | example         | DONE    | `ui_tree_payload_test.dart` (red @ `7e69612`) |
| U4  | diff: root-level change lands in changedPaths at 'root'; nested change at index path like '0/1' | FR-003   | example | DONE | `ui_tree_payload_test.dart` (red @ `7e69612`, M2 killed) |
| U5  | diff: vocabularyChanged/schemaChanged flags; identical payloads -> all-empty delta, hasChanges false | FR-003   | example | DONE | `ui_tree_payload_test.dart` (red @ `7e69612`) |
| U6  | Round-trip: fromJson(toJson(p)) == p incl. recomputed depth/nodeCount           | FR-002   | example         | DONE    | `ui_tree_payload_test.dart` (red @ `fda576f`) |
| U7  | Shipped construction validation (empty pinning) + mimeType constant (pin)       | FR-005   | characterization | DONE (BASELINE) | `ui_tree_payload_provider_test.dart` |
| U8  | computeDepth/computeNodeCount + deep equality (pin)                             | FR-005   | characterization | DONE (BASELINE) | `ui_tree_payload_provider_test.dart` |
| U9  | UiTreeDiff equality across all six fields + toString summary                    | FR-004   | example         | DONE    | `ui_tree_payload_test.dart` (red @ `7e69612`) |
| U10 | UiTreeDiff path lists are deterministically ordered                             | FR-004   | example         | DONE    | `ui_tree_payload_test.dart` (red @ `7e69612`) |

### `lib/src/data/providers/ui_tree_payload/` (layers untouched — FR-006)

| id  | behavior                                                                        | traces   | kind            | state   | test                                                        |
| --- | ------------------------------------------------------------------------------- | -------- | --------------- | ------- | ----------------------------------------------------------- |
| —   | The 3 clean-arch stub tests keep passing unchanged                              | FR-006   | characterization | BASELINE | `ui_tree_payload_provider_test.dart` |

## Invariants and edge cases still to place

- Round-trip idempotence: fromJson(toJson(fromJson(toJson(p)))) == fromJson(toJson(p)).
- Diff symmetric complement: a.diff(b).addedPaths == b.diff(a).removedPaths
  (order aside) — placed with U3/U5 assertions.
- Diff only sees `children` lists of maps — consistent with the walkers (U4
  fixture includes a non-map child to pin invisibility on both sides).

## Out of scope

- Wiring UiTreePayloadProvider to a store: separate feature; FR-006 pins stubs.
- Vocabulary pinning enforcement (§8.2 allowed-vocabularies gate): engine
  policy feature, not the payload.
- Wire-string encoding (jsonEncode) — callers own it; the payload contract is
  the map shape.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test <file> --plain-name "<test name>"`
- Full suite: `dart test`
- Coverage: raw VM-format only; converter absent — corroboration only, never a gate
- Mutation: no tool configured — deliberate hand-mutants per
  `/speckit.tdd.verify` Phase 4
