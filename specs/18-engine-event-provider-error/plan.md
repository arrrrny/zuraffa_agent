# Implementation Plan: EngineEvent.ProviderError

**Branch**: `18-engine-event-provider-error` | **Date**: 2026-08-24

## Summary
Emitted when a provider call fails terminally (auth, rate-limit, network). Pairs with the fallback chain (spec-004). Mirrors #34 (TurnCompleted) exactly.

## Phase 1 — Design

### Part file
See `lib/src/engine/events/provider_error.dart`.

### engine_event.dart update
Add `part 'provider_error.dart';` after the last existing `part 'X.dart';` directive.

### Test update
Extend `describe(EngineEvent)` switch with `ProviderError` case. Add is-A + payload tests.

## Phase 2 — Tasks
See `tasks.md`.
