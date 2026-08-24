# Implementation Plan: SubAgentSpec value object
**Branch**: `036-sub-agent-spec` | **Date**: 2026-08-24

## Summary
Hand-curate the `SubAgentSpec` value object (R5.2 spec-exact) + `SubAgentSpecService` + `SubAgentSpecProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers), PR #50 (AgentSession root entity), and PR #52 (AgentTool + RiskTier): plain Dart value object, no `@Zorphy` codegen, compiles without `build_runner`. The repo already ships `AgentTool` + `RiskTier` (PR #52); this PR adds the declarative spec data structure that captures a sub-agent's name + tools + budgets + system prompt + risk tier, with optional `extends` inheritance pointer.

## Phase 1 — Design
- **SubAgentSpec** (value object): `name` (String, required — unique spec name like `"explore"` / `"compose"` / `"verify"`), `description` (String, required — human-readable), `systemPrompt` (String, required — the prompt fed to the LLM as system role), `extendsSpec` (String?, optional — parent spec name for inheritance, R5.2 "extends"; null for a root spec), `tools` (List<String>, default `const []` — allowlist of tool ids, R5.1 "own tool allowlists"), `subAgents` (List<String>, default `const []` — sub-agent spec names this agent may dispatch, R5.1 "isolated-context dispatch"), `riskTier` (RiskTier, default `RiskTier.safe` — reuses the enum from PR #52), `maxTurns` (int?, optional — turn budget), `wallClockTimeout` (Duration?, optional — wall-clock budget), `contextWindowTokens` (int?, optional — context window size, R5.1 "isolated context windows"). Value equality across all ten fields. `isLeaf` getter (`subAgents.isEmpty` — cannot dispatch sub-agents). `isRoot` getter (`extendsSpec == null` — not inheriting from any parent). `hasBudgets` getter (`maxTurns != null || wallClockTimeout != null || contextWindowTokens != null`).
- **Service** (`SubAgentSpecService`): abstract, two `NoParams`-param methods — `current(NoParams)` returns the current spec, `count(NoParams)` returns the count of registered specs.
- **Provider** (`SubAgentSpecProvider`): concrete stub implementing `SubAgentSpecService` with matching `NoParams` signatures; bodies throw `UnimplementedError`.

## Phase 2 — Tasks
See `tasks.md`.
