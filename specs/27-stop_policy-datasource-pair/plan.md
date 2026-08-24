# Implementation Plan: StopPolicy datasource + mock pair
**Branch**: `27-stop_policy-datasource-pair` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

## Summary
Hand-curate the `stop_policy_datasource.dart` interface + `stop_policy_mock_datasource.dart` stub pair for the `StopPolicy` value object. Policy surface for the engine loop's stop conditions: max turns, wall-clock timeout, token budget, repetition threshold. Producers produce typed StopOutcome outcomes. Bodies throw UnimplementedError matching the zfa-generated stub convention.

## Phase 1 — Design
See `tasks.md` for the file surface.

## Phase 2 — Tasks
See `tasks.md`.
