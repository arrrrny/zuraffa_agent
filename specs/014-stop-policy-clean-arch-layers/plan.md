# Implementation Plan: StopPolicy clean-architecture layers
**Branch**: `014-stop-policy-clean-arch-layers` | **Date**: 2026-08-24

## Summary
Hand-curate StopPolicyRepository + StopPolicyService + StopPolicyProvider — the clean-arch layers that `zfa make` crashes before emitting (issue #14). Pattern mirrors PR #32 (ArtifactService/ArtifactProvider with NoParams parameterless methods).

## Phase 1 — Design
- Repository: getCurrent(id), update(policy), reset(id) — value-object-appropriate surface (no CRUD).
- Service: current(NoParams), defaultPolicy(NoParams) — parameterless, NoParams-typed to match PR #32 pattern.
- Provider: implements StopPolicyService with UnimplementedError bodies.

## Phase 2 — Tasks
See `tasks.md`.
