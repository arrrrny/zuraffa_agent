---
feature: 044-compaction_strategy
loop: inside-out # sealed value object + service interface + provider; no user-visible surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria; advances epic #1 §R2.3 / issue #3 R1
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # green baseline: 909 passed / 2 skipped
---

# Test List: CompactionStrategy selective retain/summarize (spec 044)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `CompactionStrategy` is a plain-Dart value object
plus an abstract service interface (`CompactionStrategyService`) and a concrete
provider; there is no HTTP/CLI/user-visible entry point to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/compaction_strategy/compaction_strategy.dart` (value object, 6 fields)

| id  | behavior                                              | traces | kind    | state | test                                                                                         |
| --- | ----------------------------------------------------- | ------ | ------- | ----- | -------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all six fields + hashCode  | R1     | example | DONE  | `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart::CompactionStrategy equality is value-based across all fields` |
| U2  | Inequality holds when any field differs               | R1     | example | DONE  | `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart::CompactionStrategy inequality differs when a field changes` |

### `lib/src/domain/services/compaction_strategy_service.dart` + `.../compaction_strategy_provider.dart` (clean-arch layers)

| id  | behavior                                                        | traces | kind    | state | test                                                                                         |
| --- | --------------------------------------------------------------- | ------ | ------- | ----- | -------------------------------------------------------------------------------------------- |
| U3  | `CompactionStrategyProvider` is a `CompactionStrategyService`   | R1     | example | DONE  | `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart::CompactionStrategyProvider is a CompactionStrategyService` |
| U4  | `current()` returns the default active strategy when none given | R1     | example | DONE  | `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart::CompactionStrategyProvider.current returns the active strategy` |
| U5  | `current()` returns the injected active strategy               | R1     | example | DONE  | `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart::CompactionStrategyProvider honors an injected active strategy` |
| U6  | `count()` returns 1                                             | R1     | example | DONE  | `test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart::CompactionStrategyProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec describes the *policy* of selective compaction (retain decisions/tool
  names/key results/plan state verbatim; summarize verbose outputs referencing
  artifacts). The shipped value object only holds the strategy snapshot (id/
  sessionId/retainEntryIds/summarizeEntryIds/artifactRefs/compactedAt) and a
  default-returning provider; no retain/summarize selection logic is implemented
  or tested. That logic belongs to the engine's compaction pass, out of scope of
  the current shipped code.
- `current()` is async (returns `Future<CompactionStrategy>`); the provider
  resolves immediately. No error path is exercised by the shipped tests.

## Out of scope

- Engine-side compaction execution (actual retain/summarize of a transcript):
  engine feature.
- Persistence/serialization of the strategy: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe the provider as a "stub throwing
  `UnimplementedError`". The shipped `CompactionStrategyProvider` does **not**
  throw; `current()` returns the active strategy (default or injected) and
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
