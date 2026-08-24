# Implementation Plan: RepetitionTracker datasource + mock pair
**Branch**: `25-repetition_tracker-datasource-pair` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary
Hand-curate the `repetition_tracker_datasource.dart` interface + `repetition_tracker_mock_datasource.dart` stub pair for the `RepetitionTracker` value object. Tracks per-tool invocation repetition within a window; emits a signal when a tool has been called more than N times in the last M seconds. Bodies throw UnimplementedError matching the zfa-generated stub convention.

## Phase 1 — Design
See `tasks.md` for the file surface.

## Phase 2 — Tasks
See `tasks.md`.
