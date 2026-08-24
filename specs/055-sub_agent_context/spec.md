# Feature Specification: SubAgentContext (isolated context)

**Branch**: `055-sub_agent_context` | **Date**: 2026-08-24

## Summary
Isolated sub-agent execution context — own session, own tool allowlist, own budget; the parent receives result summaries only, never raw context (epic #5 §R5.1, issue #6 US1). This advances epic issue #6 (Sub-agents & Declarative). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/sub_agent_context/sub_agent_context.dart` - `SubAgentContext` value object (5 fields; value-based equality).
- `lib/src/domain/services/sub_agent_context_service.dart` - abstract `SubAgentContextService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/sub_agent_context/sub_agent_context_provider.dart` - concrete `SubAgentContextProvider` stub (UnimplementedError bodies).
- `test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/055-sub_agent_context/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #6 (Sub-agents & Declarative)
