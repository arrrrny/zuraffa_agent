# Feature Specification: SubAgentInstance (resumable)

**Branch**: `056-sub_agent_instance` | **Date**: 2026-08-24

## Summary
Resumable sub-agent instance — persists across engine restarts, can be resumed by id (epic #5 §R5.2, issue #6 US2). Tracks last-run outcome, total runs, parent reference. This advances epic issue #6 (Sub-agents & Declarative). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/sub_agent_instance/sub_agent_instance.dart` - `SubAgentInstance` value object (5 fields; value-based equality).
- `lib/src/domain/services/sub_agent_instance_service.dart` - abstract `SubAgentInstanceService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/sub_agent_instance/sub_agent_instance_provider.dart` - concrete `SubAgentInstanceProvider` stub (UnimplementedError bodies).
- `test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/056-sub_agent_instance/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #6 (Sub-agents & Declarative)
