# Implementation Plan: UiTreePayload value object
**Branch**: `038-ui-tree-payload` | **Date**: 2026-08-24

## Summary
Hand-curate the `UiTreePayload` value object (§8.1 spec-exact) + `UiTreePayloadService` + `UiTreePayloadProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers) and PR #50 (AgentSession root entity): plain Dart value object, no `@Zorphy` codegen, compiles without `build_runner`. The repo already ships `ToolResult` (PR #49) and the `TurnRecord`/`ToolInvocation` entities; this PR adds the structured payload type that gets embedded in `ToolResult.structuredPayload` (or as a final mission output).

## Phase 1 — Design
- **UiTreePayload** (value object): `vocabularyId` (String, required — e.g. `"shadcn-ui@1.0.0"`), `schemaVersion` (String, required — e.g. `"1.0.0"`), `tree` (Map<String, dynamic>, required — the tree root node; any JSON-compatible map), `depth` (int, precomputed at construction via `computeDepth(tree)`), `nodeCount` (int, precomputed at construction via `computeNodeCount(tree)`), `mimeType` (String, constant `"ui/tree+json"` — explicit content-type tag). Factory constructor `UiTreePayload({required vocabularyId, required schemaVersion, required tree})` validates inputs (`ArgumentError` on empty vocabularyId/schemaVersion or non-map tree) and auto-computes depth + nodeCount. Value equality across vocabularyId/schemaVersion/tree/depth/nodeCount with deep map equality on tree. Static helpers `computeDepth(Map)` and `computeNodeCount(Map)` walk the tree's `children` key (a List<Map>) recursively.
- **Service** (`UiTreePayloadService`): abstract, two `NoParams`-param methods — `current(NoParams)` returns the most-recently-emitted payload, `count(NoParams)` returns the count of payloads in the active mission.
- **Provider** (`UiTreePayloadProvider`): concrete stub implementing `UiTreePayloadService` with matching `NoParams` signatures; bodies throw `UnimplementedError`.

## Phase 2 — Tasks
See `tasks.md`.
