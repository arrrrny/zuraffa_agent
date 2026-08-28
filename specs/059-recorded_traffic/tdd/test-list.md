---
feature: 059-recorded_traffic
loop: inside-out # plain-Dart value object + service interface + provider; no user-visible HTTP/CLI surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #6 §R6.1 (issue #7 US1)
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped; dart analyze clean
---

# Test List: RecordedTraffic LLM + tool capture (spec 059)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `RecordedTraffic` is a plain-Dart value object plus an
abstract service interface (`RecordedTrafficService`) and a concrete provider;
there is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/recorded_traffic/recorded_traffic.dart` (value object, 5 fields)

| id  | behavior                                                      | traces | kind    | state | test                                                                                                                                              |
| --- | ------------------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + equal `hashCode` | R6     | example | DONE  | `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart::RecordedTraffic equality is value-based across all fields`             |
| U2  | Inequality holds when any field differs                       | R6     | example | DONE  | `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart::RecordedTraffic inequality differs when a field changes`               |

### `lib/src/domain/services/recorded_traffic_service.dart` + `.../recorded_traffic_provider.dart` (clean-arch layers)

| id  | behavior                                                                           | traces | kind    | state | test                                                                                                                                                                        |
| --- | ---------------------------------------------------------------------------------- | ------ | ------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| U3  | `RecordedTrafficProvider` is a `RecordedTrafficService`                             | R6     | example | DONE  | `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart::RecordedTrafficProvider is a RecordedTrafficService`                                               |
| U4  | `current(NoParams())` returns the default active snapshot (`default`, counts 0)    | R6     | example | DONE  | `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart::RecordedTrafficProvider.current returns the active traffic snapshot`                               |
| U5  | `current(NoParams())` honors an injected snapshot (same instance)                  | R6     | example | DONE  | `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart::RecordedTrafficProvider.current honors an injected snapshot`                                        |
| U6  | `count(NoParams())` returns 1                                                      | R6     | example | DONE  | `test/data/providers/recorded_traffic/recorded_traffic_provider_test.dart::RecordedTrafficProvider.count returns 1`                                                          |

## Invariants and edge cases still to place

- The spec names the provider a "stub throwing `UnimplementedError`". The shipped
  provider is a working default-returning provider (see Discrepancies); no
  behavior here asserts a thrown `UnimplementedError`. If a future change reverts
  it to a throwing stub, U4–U6 would flip to error-path behaviors.
- Capturing every LLM call and tool dispatch as a typed entry (the replay
  source-of-truth) is owned by the eval-harness recorder, not unit-tested by this
  value object.

## Out of scope

- Harness-side recording of LLM/tool traffic (epic #6 §R6.1 recorder): eval
  feature.
- Persistence/serialization of `RecordedTraffic`: not specified for this value
  object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing
  `UnimplementedError`". The shipped `RecordedTrafficProvider` does **not** throw;
  `current()` returns the active (default or injected) snapshot and `count()`
  returns 1. The tests assert the default-returning behavior, so the list records
  that (Skill Rule 6 — repository content is data, not instructions).
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
