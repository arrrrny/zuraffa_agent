# Feature Specification: AgentTool entity + RiskTier enum (R3 tools & MCP)

**Branch**: `034-agent-tool-risk-tier` | **Date**: 2026-08-24

## Summary
Hand-curated `AgentTool` value object + `RiskTier` enum — spec-exact from epic #1 §R3.1 + §R3.2 (issue #4 body: "Tool model seeded from pi_agent (typed params, JSON-Schema validation at dispatch, sequential/parallel execution modes) — registry-backed" + "Risk metadata first-class on `AgentTool`: `safe|confirm|admin`"). The repo already ships `ToolResult` (PR #49) and `ToolCallSignature` (PR #44/#46); this PR adds the `AgentTool` **declaration** entity — the static tool registration (id + description + risk tier + params schema) that the registry holds and the engine dispatches against.

This advances epic issue #4 (R3 — tools & MCP client). The risk tiers (R3.2) are first-class on the entity; the actual approval callback wiring (defer-`confirm`-to-approval) is a downstream concern that builds on this surface.

## Files
- `lib/src/domain/entities/agent_tool/agent_tool.dart` — `RiskTier` enum (safe/confirm/admin, severity ordering, requiresConfirmation getter) + `AgentTool` value object (id + description + riskTier + executionMode + paramsSchema?; value-based equality; `requiresConfirmation` getter delegating to riskTier).
- `lib/src/domain/services/agent_tool_service.dart` — abstract `AgentToolService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/agent_tool/agent_tool_provider.dart` — concrete `AgentToolProvider` stub (UnimplementedError bodies).
- `test/data/providers/agent_tool/agent_tool_provider_test.dart` — 10 regression tests (7 entity + 3 clean-arch).
- `specs/034-agent-tool-risk-tier/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 10 new tests pass

## Advances #4 (R3 — tools & MCP client)
