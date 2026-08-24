# Implementation Plan: ToolResult value object + clean-arch layers
**Branch**: `031-tool-result-value-object` | **Date**: 2026-08-24

## Summary
Hand-curate the ToolResult value object (spec-exact, no id) + ToolResultService + ToolResultProvider. Pattern mirrors PR #32 (ArtifactProvider/ArtifactService). zfa v6.0.0 aborts on value objects without id; ship the surface in the consuming repo.

## Phase 1 — Design
- Entity: content (String, required), structuredPayload (Map?, optional), artifactRef (ArtifactRef?, optional). No id. isSummarized getter. Value equality (content + payload + artifactRef).
- Service: current(NoParams), count(NoParams) — value-object-appropriate, no CRUD.
- Provider: implements ToolResultService with UnimplementedError stubs.

## Phase 2 — Tasks
See `tasks.md`.
