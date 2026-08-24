# Feature Specification: UiTreePayload value object (UI/tree+json)

**Branch**: `038-ui-tree-payload` | **Date**: 2026-08-24

## Summary
Hand-curated `UiTreePayload` value object — spec-exact from epic #1 §8.1 / issue #8 body ("Payload typing: tool results and final mission outputs accept a structured content type `ui/tree+json` (tree + schemaVersion + vocabularyId); stored as `ToolInvocation`/`TurnRecord` payloads in the session tree (spec 002 entities) — replayable"). The repo already ships `ToolResult` (PR #49) and the `TurnRecord` / `ToolInvocation` entities; this PR adds the structured payload type that gets embedded in `ToolResult.structuredPayload` (or as a final mission output) — a typed UI tree the plugin/app renders later.

This advances epic issue #8 (UI/tree+json payloads). Vocabulary pinning in specs (§8.2), budget integration (§8.3), eval graders (§8.4), and recording/replay (§8.5) build on this surface in later PRs.

## Files
- `lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart` — `UiTreePayload` value object (vocabularyId + schemaVersion + tree (Map) + depth + nodeCount + mimeType constant "ui/tree+json"; value-based equality with deep map equality on tree; factory constructor auto-computes depth + nodeCount; static helpers `computeDepth` / `computeNodeCount`).
- `lib/src/domain/services/ui_tree_payload_service.dart` — abstract `UiTreePayloadService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/ui_tree_payload/ui_tree_payload_provider.dart` — concrete `UiTreePayloadProvider` stub (UnimplementedError bodies).
- `test/data/providers/ui_tree_payload/ui_tree_payload_provider_test.dart` — 11 regression tests (8 payload + 3 clean-arch).
- `specs/038-ui-tree-payload/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 11 new tests pass

## Advances #8 (UI/tree+json payloads)
