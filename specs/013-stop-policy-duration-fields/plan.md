# Implementation Plan: StopPolicy Duration field support
**Branch**: `013-stop-policy-duration-fields` | **Date**: 2026-08-24

## Summary
Extend `StopPolicy` value object with `maxTurns:int`, `wallClockTimeout:Duration`, `repetitionThreshold:int`, `enabled:bool` (spec-exact from specs/002-engine-core-loop/data-model.md). zfa rejects Duration; hand-curate the surface instead.

## Phase 1 — Design
Entity becomes a 5-field value object with value-based equality (Object.hash). Update tests to assert Duration field is constructible + that value equality holds across all five fields.

## Phase 2 — Tasks
See `tasks.md`.
