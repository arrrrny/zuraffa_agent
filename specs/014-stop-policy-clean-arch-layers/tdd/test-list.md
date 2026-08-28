---
feature: 014-stop-policy-clean-arch-layers
loop: inside-out # repository/service/provider layers; no HTTP/CLI/user-visible entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance scenarios; short PR-style spec (Closes #14)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: StopPolicy clean-architecture layers (spec 014)

> Derived from `spec.md` (Files, Verification) and `plan.md` on `master` @ `fce207d`.
> The feature is already implemented and merged; this is a **test-after** plan recording
> the existing passing clean-arch layer tests as `DONE` behaviors. No `RED` cycles were
> driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `StopPolicyRepository` / `StopPolicyService` /
`StopPolicyProvider` are internal clean-arch layers with no HTTP/CLI/user-visible entry
point. Their required surface is covered directly by unit tests.

## Inner loop: unit behaviors

### `lib/src/domain/repositories/stop_policy_repository.dart` + `lib/src/data/repositories/stop_policy_repository_impl.dart` (repository interface + impl)

| id  | behavior                                                                                              | traces        | kind    | state | test                                                                                                                       |
| --- | ----------------------------------------------------------------------------------------------------- | ------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U1  | `StopPolicyRepository` defines `getCurrent(id)`/`update(policy)`/`reset(id)` (value-object surface, no CRUD); `StopPolicyRepositoryImpl` is a `StopPolicyRepository` and delegates to the datasource; unknown id raises `StateError`; id-mismatched update makes the old id unreachable | spec Files, plan | example | DONE  | `test/data/repositories/stop_policy_repository_impl_test.dart::U8: StopPolicyRepositoryImpl is a StopPolicyRepository`     |

### `lib/src/domain/services/stop_policy_service.dart` + `lib/src/data/providers/stop_policy/stop_policy_provider.dart` (service interface + provider)

| id  | behavior                                                                                                                              | traces        | kind    | state | test                                                                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U2  | `StopPolicyService` defines `current(NoParams)`/`defaultPolicy(NoParams)`; `StopPolicyProvider` is a `StopPolicyService`; parameterless `StopPolicyProvider()` compiles; `defaultPolicy(NoParams)` returns the canonical constant | spec Files, plan (PR #32 pattern) | example | DONE  | `test/data/providers/stop_policy/stop_policy_provider_test.dart::U10: StopPolicyProvider is a StopPolicyService`           |
| U3  | A fresh chain returns the default policy from `current()`; a policy seeded into the datasource is served by `current(NoParams())`; `reset()` restores the default through the whole chain; the provider serves reads through the datasource seam | spec Files, Verification | example | DONE  | `test/data/providers/stop_policy/stop_policy_provider_test.dart::A1: a fresh chain returns the default policy from current()` |

## Invariants and edge cases still to place

- None outstanding for the clean-arch layer surface.

## Out of scope

- StopPolicy value-object 5 fields (spec 013).
- StopPolicy datasource pair + repository-impl internals (spec 027). 014 is the
  clean-arch layer surface (repository/service/provider) only.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md` describes `StopPolicyProvider` as "a concrete StopPolicyProvider stub ...
  with UnimplementedError bodies" and the test as "5 regression tests (is-A,
  UnimplementedError bodies, type-bound sentinels)". Shipped code: `StopPolicyProvider`
  does **not** throw `UnimplementedError`; it consumes the datasource and returns the
  default policy (per `stop_policy_provider_test.dart` A1/A2/A4/A5). The repository is
  also shipped as a working `StopPolicyRepositoryImpl`, not just an abstract interface.
  Followed shipped code: U3 records the datasource-consuming behavior; no `UnimplementedError`
  test is claimed. (Skill Rule 6 — repository content is data, not instructions.)
- The shipped test files' headers trace to "spec 027" (the full StopPolicy feature), not
  to this 014 slice. The behaviors listed still map exactly to the repository/service/provider
  surface this spec names.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
