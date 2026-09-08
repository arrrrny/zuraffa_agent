**Template Version**: `zuraffa-1.0`

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

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** U10: StopPolicyProvider is a StopPolicyService **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** U11: parameterless StopPolicyProvider() keeps compiling (default wiring) **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** A1: a fresh chain returns the default policy from current() **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** A2 + A5: a policy seeded into the datasource is served by current(NoParams()) **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** A4: reset() restores the documented default through the whole chain **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** U12: defaultPolicy(NoParams) returns the canonical constant **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** A5: the provider serves reads through the datasource seam **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`).
   **Type**: acceptance
