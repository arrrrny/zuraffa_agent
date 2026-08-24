# Feature Specification: AgentSession root entity (R2 sessions)

**Branch**: `032-agent-session-root` | **Date**: 2026-08-24

## Summary
Hand-curated `AgentSession` root entity — the tree-of-entries root from epic #1 §R2.1 (`AgentSession` = tree-of-entries, branching; port pi_agent's session tree). The repo already ships the leaf entry types (`TurnRecord`, `ToolInvocation`, `UsageLedger`, `ModelChangeEntry`, `BranchSummaryEntry`, `CompactionEntry`, `LabelEntry`, `CustomEntry`, `ThinkingLevelChangeEntry`, `ToolCallSignature`); this PR adds the **root** that ties them into a session tree and tracks the branching cursor.

This advances epic issue #1 (R2 — state & sessions). The leaf-entry entities were landed incrementally (PRs #32–#48); the root entity was the last missing piece of the R2.1 data model.

## Files
- `lib/src/domain/entities/agent_session/agent_session.dart` — `AgentSession` root entity (id + missionId? + rootEntryId + currentEntryId? + parentSessionId? + createdAt + updatedAt; value-based equality; `isBranch` / `isHead` getters).
- `lib/src/domain/services/agent_session_service.dart` — abstract `AgentSessionService` (current(NoParams), count(NoParams) — value-object-appropriate, no CRUD).
- `lib/src/data/providers/agent_session/agent_session_provider.dart` — concrete `AgentSessionProvider` stub (implements `AgentSessionService` with matching NoParams signatures; bodies throw `UnimplementedError`).
- `test/data/providers/agent_session/agent_session_provider_test.dart` — 8 regression tests (5 entity + 3 clean-arch).
- `specs/032-agent-session-root/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 8 new tests pass

## Advances #1 (R2 — state & sessions)
