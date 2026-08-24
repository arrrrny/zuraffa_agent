# Feature Specification: SubAgentSpec value object (R5 sub-agents & specs)

**Branch**: `036-sub-agent-spec` | **Date**: 2026-08-24

## Summary
Hand-curated `SubAgentSpec` value object — spec-exact from epic #1 §R5.2 (issue #6 body: "Declarative agent specs (YAML, `extends` inheritance): tools, sub-agents, budgets, system prompt, risk tier — specs are data"). The repo already ships `AgentTool` (PR #52) including the `RiskTier` enum; this PR adds the declarative spec for a sub-agent — the data structure that captures name + description + systemPrompt + extends + tools allowlist + subAgents + riskTier + budgets (maxTurns / wallClockTimeout / contextWindowTokens). Reuses `RiskTier` from PR #52 for consistency.

This advances epic issue #6 (R5 — sub-agents & specs). The spec loader (YAML parser + `extends` resolution) and the dispatch (Kimi LaborMarket pattern, isolated context windows) build on this surface in later PRs.

## Files
- `lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart` — `SubAgentSpec` value object (name + description + systemPrompt + extendsSpec? + tools (List<String>) + subAgents (List<String>) + riskTier (default safe) + maxTurns? + wallClockTimeout? + contextWindowTokens?; value-based equality; `isLeaf` / `isRoot` / `hasBudgets` getters; reuses `RiskTier` from PR #52).
- `lib/src/domain/services/sub_agent_spec_service.dart` — abstract `SubAgentSpecService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/sub_agent_spec/sub_agent_spec_provider.dart` — concrete `SubAgentSpecProvider` stub (UnimplementedError bodies).
- `test/data/providers/sub_agent_spec/sub_agent_spec_provider_test.dart` — 11 regression tests (8 entity + 3 clean-arch).
- `specs/036-sub-agent-spec/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 11 new tests pass

## Advances #6 (R5 — sub-agents & specs)
