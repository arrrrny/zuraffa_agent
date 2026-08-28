# Implementation Plan: UiTreePayload value object (serialization + diffing)

**Branch**: `038-ui-tree-payload` | **Date**: 2026-08-27 | **Spec**: `specs/038-ui-tree-payload/spec.md`

**Input**: Feature specification from `/specs/038-ui-tree-payload/spec.md` (refined 2026-08-27).

**Note**: Hand-curated original plan (2026-08-24) delivered the payload value object with precomputed depth/nodeCount; this refinement adds the Technical Context and the serialization/diffing slice the task spec mandates.

## Summary

Extend `UiTreePayload` with `toJson`/`fromJson` (mimeType-checked round-trip) and `diff` (path-keyed structural delta + pinning-drift flags), adding one small `UiTreeDiff` value object in the same file. Serialization feeds the MCP/session-tree boundary; diffing feeds replay tooling. No new files beyond the entity extension and its test suite.

## Technical Context

**Language/Version**: Dart SDK ^3.8.0 (pure Dart package, no Flutter SDK — constitution VII).

**Primary Dependencies**: `zuraffa` (git — `NoParams`, `Loggable`, `FailureHandler`), `test` + `mocktail` (dev). No new dependencies; serialization is plain map shaping (mirrors `ToolResult.toJson` precedent — no json_annotation codegen, consistent with the hand-curated file family).

**Storage**: N/A (payload crosses boundaries as an embedded map; provider stays an UnimplementedError stub per FR-006).

**Testing**: `package:test` via `dart test`; baseline at feature start: 716 passed / 0 failed (post-spec-037); single test: `dart test {file} --plain-name "{name}"` (verified, `.specify/memory/tdd-profile.md`).

**Target Platform**: Dart VM (engine package).

**Project Type**: library (agent engine).

**Performance Goals**: toJson O(1) (map literal over stored fields); fromJson inherits constructor cost (one depth+nodeCount walk); diff O(nodes in the larger tree) via simultaneous walk — no quadratic path-set materialization.

**Constraints**: Runtime paths `dart:io`-free; `dart analyze` zero NEW findings vs the 5-issue baseline; no codegen; UI-framework-agnostic (no Flutter imports — the payload carries plain maps).

**Scale/Scope**: One entity file extended (`ui_tree_payload.dart` + `UiTreeDiff` class), one new test file (`test/domain/entities/ui_tree_payload/ui_tree_payload_test.dart`); provider suite untouched.

## Constitution Check

- **I. CLI-Built Only** — PASS: speckit pipeline drives the artifacts; hand-curated header lineage (PR #49–#55) is the recorded exemption for this file family.
- **V. Gates Are Non-Negotiable** — PASS: SC-006 gates the feature.
- **VII. Engine Purity** — PASS: no new imports; stays UI-framework-agnostic per issue #8 ("Engine core imports no Flutter/UI packages").
- **IX. Zorphy Is the Model Layer** — PASS-with-precedent: HAND-CURATED header retained; `UiTreeDiff` follows the same established value-object family (plain Dart, no codegen) rather than introducing a Zorphy codegen dependency mid-family.
- **X. Post-Build Analysis Must Be Pristine** — PASS: zero new analyzer findings required.

## Project Structure

### Documentation (this feature)

```text
specs/038-ui-tree-payload/
├── spec.md              # Refined 2026-08-27 (/speckit.specify)
├── plan.md              # This file (/speckit.plan refinement)
├── tasks.md             # /speckit.tasks dependency-ordered rewrite
└── tdd/
    ├── test-list.md     # /speckit.tdd.plan
    ├── cycle-log.md     # /speckit.tdd.run evidence (append-only)
    └── verification.md  # /speckit.tdd.verify audit
```

### Source Code (repository root)

```text
lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart  # +toJson/fromJson/diff, +UiTreeDiff
lib/src/domain/services/ui_tree_payload_service.dart           # unchanged (FR-006)
lib/src/data/providers/ui_tree_payload/ui_tree_payload_provider.dart # unchanged (FR-006)
test/domain/entities/ui_tree_payload/ui_tree_payload_test.dart # NEW: serialization + diffing suite
test/data/providers/ui_tree_payload/ui_tree_payload_provider_test.dart # unchanged (pinned, 11 tests)
```

## Phase 1 — Design

- **toJson**: `{'mimeType': mimeType, 'vocabularyId': ..., 'schemaVersion': ..., 'tree': tree}` — the tree map is stored as-is (immutable by convention); callers encoding to a wire string own jsonEncode.
- **fromJson**: read `mimeType` (required, == constant → else ArgumentError naming it), `vocabularyId`/`schemaVersion` (non-empty strings → else ArgumentError naming field), `tree` (Map<String, dynamic> → else ArgumentError naming tree); construct via the standard factory so its validation + precompute apply; unknown top-level keys ignored (forward-compatibility, documented in spec Assumptions).
- **diff**: simultaneous recursive walk keyed by path ('root' then '/'.join of children indices); a node exists at a path if a map is there; compare with the file's existing `_deepEq` (reuse, do not duplicate); collect added/removed/changed; pin flags compare vocabularyId/schemaVersion; `hasChanges` derived. Both walks see only `children` lists containing maps — consistent with computeDepth/computeNodeCount.
- **UiTreeDiff**: plain immutable VO; ordered path lists (sorted lexically by collection for determinism); equality across all fields; `toString` summary (`UiTreeDiff(+N, -N, ~N, vocab=x, schema=y)`).
- **Dart language note**: toJson/fromJson/diff/UiTreeDiff are absent today → first reds are compile errors; stubs then drive UnimplementedError reds per playbook.

## Phase 2 — Tasks

See `tasks.md` (dependency-ordered; test tasks precede implementation tasks per `/speckit.tdd.plan`).
