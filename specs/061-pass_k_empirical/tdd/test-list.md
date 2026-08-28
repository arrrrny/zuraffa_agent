---
feature: 061-pass_k_empirical
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #6 §R6.2 (Eval Harness) issue #7 US2
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped baseline; dart analyze clean
---

# Test List: PassKEmpirical pass^k metric (spec 061)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `PassKEmpirical` is a plain-Dart value object plus an
abstract service interface (`PassKEmpiricalService`) and a default provider; there
is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/pass_k_empirical/pass_k_empirical.dart` (value object, 5 fields: id, taskId, k, successCount, empiricalRate)

| id  | behavior                                              | traces | kind     | state | test                                                                                        |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + hashCode | R6.2   | example | DONE  | `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpirical equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R6.2   | example | DONE  | `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpirical inequality differs when a field changes` |

### `lib/src/domain/services/pass_k_empirical_service.dart` + `.../pass_k_empirical_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind     | state | test                                                                                                  |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | ----------------------------------------------------------------------------------------------------- |
| U3  | `PassKEmpiricalProvider` is a `PassKEmpiricalService`          | R6.2   | example | DONE  | `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider is a PassKEmpiricalService` |
| U4  | `current(NoParams)` returns the default active snapshot (id `default`, taskId `mission-1`, empiricalRate `1.0`) | R6.2 | example | DONE | `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider.current returns the active pass^k snapshot` |
| U5  | `current(NoParams)` returns the supplied/injected snapshot (same instance) | R6.2 | example | DONE | `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider.current honors an injected snapshot` |
| U6  | `count(NoParams)` returns 1                                     | R6.2   | example | DONE  | `test/data/providers/pass_k_empirical/pass_k_empirical_provider_test.dart::PassKEmpiricalProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names `PassKEmpirical` as "fraction of k independent runs that
  succeeded" (complements the unbiased pass@k estimator of spec 037). The shipped
  value object only *captures* `k`/`successCount`/`empiricalRate`; no fraction is
  computed by the provider. If the rate is ever computed, it belongs on a later
  behavior (out of scope of the current shipped code).
- No boundary is asserted for `empiricalRate` (e.g. `0.0` vs `1.0`, or
  `successCount` > `k`); the shipped default is internally consistent but
  unvalidated.

## Out of scope

- The unbiased pass@k estimator (spec 037) and any statistical computation:
  separate feature.
- Persistence/serialization of `PassKEmpirical`: not specified for this value
  object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`".
  The shipped `PassKEmpiricalProvider` does **not** throw; `current()` returns a
  constructed default snapshot and honors an injected value object. The tests
  assert the default-returning + injected behavior, so the list records that.
  (Skill Rule 6 — repository content is data, not instructions.) The provider's own
  doc comment confirms it "replaces the previous UnimplementedError stub".
- `spec.md` says "5 regression tests (2 entity equality + 3 clean-arch)"; the file
  actually contains 6 (2 equality + 4 clean-arch — an extra "current honors an
  injected snapshot" test). Recorded as 6 `DONE` behaviors above.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
