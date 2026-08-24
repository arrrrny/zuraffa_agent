# Feature Specification: StopPolicy clean-architecture layers (repository, service, provider)

**Branch**: `014-stop-policy-clean-arch-layers` | **Date**: 2026-08-24

## Summary
Hand-curated `StopPolicyRepository` interface, `StopPolicyService` interface, and `StopPolicyProvider` stub class for the StopPolicy value object. Issue #14 surfaces the zfa v6.0.0 bug where `zfa make <Entity> repository usecase di mock provider service datasource` crashes for every entity with `type 'bool' is not a subtype of type 'String?' in type cast`. As a result no clean-architecture layers are emitted for any spec-002 entity, and the entire `zfa make` workflow is non-functional in v6.0.0.

This PR ships a working set of clean-arch layers for one spec-002 value object (StopPolicy) ahead of the upstream zfa fix, demonstrating the pattern that sibling PRs will replicate for the other spec-002/spec-003 value objects (RepetitionTracker, ToolCallSignature, ToolResult, etc.).

## Files
- `lib/src/domain/repositories/stop_policy_repository.dart` — abstract `StopPolicyRepository` (getCurrent, update, reset).
- `lib/src/domain/services/stop_policy_service.dart` — abstract `StopPolicyService` (current, defaultPolicy — both NoParams-param parameterless methods, mirroring PR #32's ArtifactService).
- `lib/src/data/providers/stop_policy/stop_policy_provider.dart` — concrete `StopPolicyProvider` stub (implements StopPolicyService with matching NoParams signatures).
- `test/data/providers/stop_policy/stop_policy_provider_test.dart` — 5 regression tests (is-A, UnimplementedError bodies, type-bound sentinels).
- `specs/014-stop-policy-clean-arch-layers/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 5 new tests pass

## Closes #14
