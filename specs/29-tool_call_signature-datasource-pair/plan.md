# Implementation Plan: ToolCallSignature datasource + mock pair
**Branch**: `29-tool_call_signature-datasource-pair` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary
Hand-curate the `tool_call_signature_datasource.dart` interface + `tool_call_signature_mock_datasource.dart` stub pair for the `ToolCallSignature` value object. Content-addressable signature of a tool invocation: tool name + argument hash + version. Used by RepetitionTracker and the eval harness to dedupe calls. Bodies throw UnimplementedError matching the zfa-generated stub convention.

## Phase 1 — Design
See `tasks.md` for the file surface.

## Phase 2 — Tasks
See `tasks.md`.
