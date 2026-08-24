# Implementation Plan: AgentSession root entity
**Branch**: `032-agent-session-root` | **Date**: 2026-08-24

## Summary
Hand-curate the `AgentSession` root entity (R2.1 spec-exact) + `AgentSessionService` + `AgentSessionProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers): plain Dart value object, no `@Zorphy` codegen, compiles without `build_runner`. The repo already has all the leaf entry types; this fills the last gap in the R2.1 data model — the session root that owns the entry tree and the branching cursor.

## Phase 1 — Design
- **Entity** (`AgentSession`): `id` (String, required), `missionId` (String?, optional parent mission), `rootEntryId` (String, required — root of the entry tree), `currentEntryId` (String?, optional cursor at the current head — null when the session has no entries yet), `parentSessionId` (String?, optional — non-null when this session is a fork/branch of another), `createdAt` (DateTime), `updatedAt` (DateTime). Value equality across all seven fields. `isBranch` getter (`parentSessionId != null`). `isHead` getter (`currentEntryId != null`).
- **Service** (`AgentSessionService`): abstract, two `NoParams`-param methods — `current(NoParams)` and `count(NoParams)` — value-object-appropriate, no CRUD surface (matches `ToolResultService` from PR #49).
- **Provider** (`AgentSessionProvider`): concrete stub implementing `AgentSessionService` with matching `NoParams` signatures; bodies throw `UnimplementedError` (matches `ToolResultProvider` from PR #49).

## Phase 2 — Tasks
See `tasks.md`.
