# Implementation Plan: SteeringQueue + SteeringMessage
**Branch**: `033-steering-queue` | **Date**: 2026-08-24

## Summary
Hand-curate the `SteeringQueue` + `SteeringMessage` value objects (R1.3 spec-exact) + `SteeringQueueService` + `SteeringQueueProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers): plain Dart value objects, no `@Zorphy` codegen, compiles without `build_runner`. The repo already has the `SteeringInjected` lifecycle event; this PR fills the queue + message data model that the engine drains between turns.

## Phase 1 — Design
- **SteeringMessage** (value object): `id` (String, required), `content` (String, required), `injectedAt` (DateTime, required). Value equality across all three fields. The atomic unit of mid-mission user input.
- **SteeringQueue** (value object, immutable snapshot): `id` (String, required — queue id, scoped per mission), `pending` (`List<SteeringMessage>`, required — FIFO order, head at index 0), `processedCount` (int, required — total messages ever drained from this queue), `lastInjectedAt` (DateTime?, optional — when the most recent message was added; null when the queue has never been injected). `isEmpty` getter (`pending.isEmpty`). `pendingCount` getter (`pending.length`). `head` getter (`pending.isEmpty ? null : pending.first`).
- **Service** (`SteeringQueueService`): abstract, two `NoParams`-param methods — `current(NoParams)` returns the current queue snapshot, `count(NoParams)` returns the count of pending messages.
- **Provider** (`SteeringQueueProvider`): concrete stub implementing `SteeringQueueService` with matching `NoParams` signatures; bodies throw `UnimplementedError`.

## Phase 2 — Tasks
See `tasks.md`.
