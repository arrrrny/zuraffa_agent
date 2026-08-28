---
feature: 050-oversized_result_policy
loop: inside-out # sealed value object + service interface + provider; no user-visible surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #3 §R3.4 / issue #4 R3
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # green baseline: 909 passed / 2 skipped
---

# Test List: OversizedResultPolicy summarize+artifactRef (spec 050)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `OversizedResultPolicy` is a plain-Dart value object
plus an abstract service interface (`OversizedResultPolicyService`) and a
concrete provider; there is no HTTP/CLI/user-visible entry point to exercise end
to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/oversized_result_policy/oversized_result_policy.dart` (value object, 4 fields)

| id  | behavior                                              | traces | kind    | state | test                                                                                           |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ---------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + hashCode | R3     | example | DONE  | `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart::OversizedResultPolicy equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R3     | example | DONE  | `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart::OversizedResultPolicy inequality differs when a field changes` |

### `lib/src/domain/services/oversized_result_policy_service.dart` + `.../oversized_result_policy_provider.dart` (clean-arch layers)

| id  | behavior                                                         | traces | kind    | state | test                                                                                           |
| --- | ---------------------------------------------------------------- | ------ | ------- | ----- | ---------------------------------------------------------------------------------------------- |
| U3  | `OversizedResultPolicyProvider` is a `OversizedResultPolicyService` | R3   | example | DONE  | `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart::OversizedResultPolicyProvider is a OversizedResultPolicyService` |
| U4  | `current()` returns the default active policy when none given    | R3     | example | DONE  | `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart::OversizedResultPolicyProvider.current returns the active policy` |
| U5  | `current()` returns the injected active policy                   | R3     | example | DONE  | `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart::OversizedResultPolicyProvider honors an injected active policy` |
| U6  | `count()` returns 1                                              | R3     | example | DONE  | `test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart::OversizedResultPolicyProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec describes the *policy* (summarize + artifactRef before entering model
  context) that keeps the context budget under control. The shipped value object
  only holds the policy snapshot (id/thresholdBytes/summaryMaxChars/artifactStore)
  and a default-returning provider; no summarize/artifactRef transformation is
  implemented or tested. That logic belongs to the engine's result-handling
  pass, out of scope of the current shipped code.
- The default policy uses `thresholdBytes: 65536` and `summaryMaxChars: 2000`;
  tests assert only `greaterThan(0)` / `isNotEmpty`. No test pins the exact
  default thresholds or the at-threshold boundary behavior.
- `current()` is async (returns `Future<OversizedResultPolicy>`); the provider
  resolves immediately. No error path is exercised by the shipped tests.

## Out of scope

- Engine-side summarize + artifactRef transformation of an oversized result:
  engine feature (epic #3 §R3.4).
- Persistence/serialization of the policy: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing
  `UnimplementedError`". The shipped `OversizedResultPolicyProvider` does
  **not** throw; `current()` returns the active policy (default or injected) and
  `count()` returns 1. The tests assert the default-returning behavior, so the
  list records that. (Skill Rule 6 — repository content is data, not
  instructions.)
- `spec.md` says "5 regression tests"; the file actually contains 6 (2 equality +
  4 clean-arch). Recorded as 6 `DONE` behaviors above.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
