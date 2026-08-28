---
feature: 062-grader_sealed
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #6 §R6.3 (Eval Harness) issue #7 US3
planned_at: b9ba15c
updated_at: b9ba15c
suite_baseline: green # 909 passed, 2 skipped baseline; dart analyze clean
---

# Test List: GraderSealed exact/schema/model-judge (spec 062)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `b9ba15c`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `GraderSealed` is a plain-Dart value object plus an
abstract service interface (`GraderSealedService`) and a default provider; there is
no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/grader_sealed/grader_sealed.dart` (value object, 4 fields: id, graderType, expectedHash, schemaId)

| id  | behavior                                              | traces | kind     | state | test                                                                                  |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | ------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all four fields + hashCode | R6.3   | example | DONE  | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealed equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R6.3   | example | DONE  | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealed inequality differs when a field changes` |

### `lib/src/domain/services/grader_sealed_service.dart` + `.../grader_sealed_provider.dart` (clean-arch layers)

| id  | behavior                                                       | traces | kind     | state | test                                                                                                |
| --- | -------------------------------------------------------------- | ------ | ------- | ----- | --------------------------------------------------------------------------------------------------- |
| U3  | `GraderSealedProvider` is a `GraderSealedService`              | R6.3   | example | DONE  | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider is a GraderSealedService` |
| U4  | `current(NoParams)` returns the default active snapshot (id `default`, graderType `exact`) | R6.3 | example | DONE | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider.current returns the active grader snapshot` |
| U5  | `current(NoParams)` returns the supplied/injected snapshot (same instance) | R6.3 | example | DONE | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider.current honors an injected snapshot` |
| U6  | `count(NoParams)` returns 1                                     | R6.3   | example | DONE  | `test/data/providers/grader_sealed/grader_sealed_provider_test.dart::GraderSealedProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names a sealed union of grader subtypes (ExactGrader / SchemaGrader /
  ModelJudgeGrader) "with one `grade(output, expected)` method per subtype". The
  shipped value object is a single 4-field class discriminated by a `graderType`
  string; no sealed subtypes and no `grade()` method exist. If a sealed hierarchy
  with `grade()` is intended, that belongs on a later behavior (out of scope of the
  current shipped code).
- `expectedHash` and `schemaId` are nullable; equality treats `null` as a normal
  field value. No per-subtype dispatch is asserted beyond `U1`/`U2`.

## Out of scope

- Actual grading logic (`grade(output, expected)`) for any subtype: engine/eval
  feature.
- Persistence/serialization of `GraderSealed`: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing `UnimplementedError`".
  The shipped `GraderSealedProvider` does **not** throw; `current()` returns a
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
