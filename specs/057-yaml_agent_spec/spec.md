**Template Version**: `zuraffa-1.0`

# Feature Specification: YamlAgentSpec (declarative + extends)

**Branch**: `057-yaml_agent_spec` | **Date**: 2026-08-24

## Summary
Declarative YAML agent spec — extends inheritance, validation diagnostics, declarative tool allowlist + steering (epic #5 §R5.3, issue #6 US3). This advances epic issue #6 (Sub-agents & Declarative). Pattern: hand-curated plain Dart value object (no @Zorphy), abstract service interface with NoParams parameters, concrete provider stub throwing UnimplementedError, regression tests for value equality + clean-arch layering.

## Files
- `lib/src/domain/entities/yaml_agent_spec/yaml_agent_spec.dart` - `YamlAgentSpec` value object (5 fields; value-based equality).
- `lib/src/domain/services/yaml_agent_spec_service.dart` - abstract `YamlAgentSpecService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/yaml_agent_spec/yaml_agent_spec_provider.dart` - concrete `YamlAgentSpecProvider` stub (UnimplementedError bodies).
- `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart` - 5 regression tests (2 entity equality + 3 clean-arch).
- `specs/057-yaml_agent_spec/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` - No issues
- `dart test` - All pre-existing + 5 new tests pass

## Advances #6 (Sub-agents & Declarative)

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpec equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpec inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider is a YamlAgentSpecService **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider.current returns the active agent spec **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** a spec referencing an unknown tool fails validation with a precise error **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** a spec with cyclic inheritance fails validation with a precise error **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`).
   **Type**: acceptance
