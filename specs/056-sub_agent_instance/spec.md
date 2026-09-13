**Template Version**: `zuraffa-1.0`

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

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstance equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstance inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider is a SubAgentInstanceService **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider.current returns the active instance **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider.current returns a supplied active instance **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`).
   **Type**: acceptance
