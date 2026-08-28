---
feature: 064-dart_io_free_gate
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #6 §R6.5 (Eval Harness) issue #7 US5
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped baseline; dart analyze clean
---

# Test List: DartIoFreeGate static gate (spec 064)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `DartIoFreeGate` is a plain-Dart value object plus an
abstract service interface (`DartIoFreeGateService`) and a default provider; there
is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/dart_io_free_gate/dart_io_free_gate.dart` (value object, 4 fields: id, gateName, enforcedPaths, violationCount)

| id  | behavior                                              | traces | kind     | state | test                                                                                  |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + hashCode | R6.5   | example | DONE  | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGate equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R6.5   | example | DONE  | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGate inequality differs when a field changes` |

### `lib/src/domain/services/dart_io_free_gate_service.dart` + `.../dart_io_free_gate_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind     | state | test                                                                                                |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | --------------------------------------------------------------------------------------------------- |
| U3  | `DartIoFreeGateProvider` is a `DartIoFreeGateService`          | R6.5   | example | DONE  | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider is a DartIoFreeGateService` |
| U4  | `current(NoParams)` returns the default active gate (id `default`, gateName `dart-io-free`, enforcedPaths contains `lib/src`, violationCount `0`) | R6.5 | example | DONE | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider.current returns the active gate` |
| U5  | `current(NoParams)` returns the supplied/injected value object | R6.5   | example | DONE  | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider honours an injected value object` |
| U6  | `count(NoParams)` returns 1                                     | R6.5   | example | DONE  | `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart::DartIoFreeGateProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names `DartIoFreeGate` as a "static gate that fails the build if the eval
  runtime imports the platform IO module". The shipped value object only *captures*
  `gateName`/`enforcedPaths`/`violationCount`; no static-analysis gate that scans
  imports or fails the build is exercised. If the gate is ever implemented, it
  belongs on a later behavior (out of scope of the current shipped code).
- `enforcedPaths` is a `List<String>`; equality treats the list by value. No
  empty-vs-nonempty boundary is asserted beyond `U1`/`U2`/`U5`.

## Out of scope

- The actual import-scanning / build-failing static analyzer: engine/build feature.
- Persistence/serialization of `DartIoFreeGate`: not specified for this value
  object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`".
  The shipped `DartIoFreeGateProvider` does **not** throw; `current()` returns a
  constructed default snapshot and honors an injected value object. The tests
  assert the default-returning + injected behavior, so the list records that.
  (Skill Rule 6 — repository content is data, not instructions.)
- `spec.md` says "5 regression tests (2 entity equality + 3 clean-arch)"; the file
  actually contains 6 (2 equality + 4 clean-arch — an extra "honours an injected
  value object" test). Recorded as 6 `DONE` behaviors above.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
