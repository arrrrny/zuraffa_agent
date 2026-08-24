# Implementation Plan: AgentTool entity + RiskTier enum
**Branch**: `034-agent-tool-risk-tier` | **Date**: 2026-08-24

## Summary
Hand-curate the `AgentTool` value object + `RiskTier` enum (R3.1+R3.2 spec-exact) + `AgentToolService` + `AgentToolProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers) and PR #50 (AgentSession root entity): plain Dart value object, no `@Zorphy` codegen, compiles without `build_runner`. The repo already ships `ToolResult` (the runtime result of a dispatch) and `ToolCallSignature` (the call-site signature); this PR adds the static **declaration** — the registered tool metadata (id + description + risk tier + params schema) the registry holds.

## Phase 1 — Design
- **RiskTier** (enum): `safe` (default — read-only / idempotent), `confirm` (requires user approval callback before dispatch — e.g. destructive fs writes), `admin` (operator-only, requires admin grant). Extension provides `severity` (0/1/2), `requiresConfirmation` (`!= safe`), `isAdmin`.
- **AgentTool** (value object): `id` (String, required — unique tool name like `"fs.read"`), `description` (String, required — what the tool does, surfaces in tool-selection prompts), `riskTier` (RiskTier, default `RiskTier.safe`), `executionMode` (ExecutionMode, default `ExecutionMode.sequential`), `paramsSchema` (`Map<String, dynamic>?`, optional — JSON Schema for typed-params validation at dispatch per R3.1). Value equality across all five fields. `requiresConfirmation` getter delegating to `riskTier.requiresConfirmation`.
- **ExecutionMode** (enum): `sequential` (default — one tool call at a time), `parallel` (engine may batch-dispatch with other parallel tools).
- **Service** (`AgentToolService`): abstract, two `NoParams`-param methods — `current(NoParams)` returns the current registered tool, `count(NoParams)` returns the count of registered tools.
- **Provider** (`AgentToolProvider`): concrete stub implementing `AgentToolService` with matching `NoParams` signatures; bodies throw `UnimplementedError`.

## Phase 2 — Tasks
See `tasks.md`.
