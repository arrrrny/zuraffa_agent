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
