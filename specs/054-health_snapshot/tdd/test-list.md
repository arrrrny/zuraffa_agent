---
feature: 054-health_snapshot
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria in spec.md; advances epic #4 §R4.5 (issue #5 US4)
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # 909 passed, 2 skipped baseline
---

# Test List: HealthSnapshot (chain state) (spec 054)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 6 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `HealthSnapshot` is a sealed plain-Dart value object
plus an abstract service interface (`HealthSnapshotService`) and a concrete provider
(`HealthSnapshotProvider`); there is no HTTP/CLI/user-visible entry point to exercise
end to end. (The snapshot is surfaced by ops dashboards / the engine preflight, which
are owned by other features.)

## Inner loop: unit behaviors

### `lib/src/domain/entities/health_snapshot/health_snapshot.dart` (value object, 5 fields)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                              |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + hashCode | epic #4 §R4.5 (issue #5 US4) | example | DONE  | `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshot equality is value-based across all fields` |
| U2  | Inequality holds when any field differs             | epic #4 §R4.5 (issue #5 US4) | example | DONE  | `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshot inequality differs when a field changes` |

### `lib/src/domain/services/health_snapshot_service.dart` + `lib/src/data/providers/health_snapshot/health_snapshot_provider.dart` (clean-arch layers)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                              |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| U3  | `HealthSnapshotProvider` is a `HealthSnapshotService` | epic #4 §R4.5 (issue #5 US4) | example | DONE  | `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider is a HealthSnapshotService` |
| U4  | `current(NoParams)` returns the active chain snapshot | epic #4 §R4.5 (issue #5 US4) | example | DONE  | `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider.current returns the active chain snapshot` |
| U5  | `count(NoParams)` returns 1                         | epic #4 §R4.5 (issue #5 US4) | example | DONE  | `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider.count returns 1` |
| U6  | `current(NoParams)` honours an injected value object | epic #4 §R4.5 (issue #5 US4) | example | DONE  | `test/data/providers/health_snapshot/health_snapshot_provider_test.dart::HealthSnapshotProvider honours an injected value object` |

## Invariants and edge cases still to place

- The spec names per-provider open/closed/half-open state and a last-success
  timestamp surfaced for ops dashboards and the engine preflight. The shipped
  `HealthSnapshot` is a single 5-field snapshot (id, chainId, capturedAt,
  healthyProviders, trippedProviders); the per-provider breaker enumeration is
  owned by specs 053/008, not unit-tested here. No unit-pending invariant remains
  for spec 054's value object itself beyond the `DONE` set above.
- The value object exposes only 5 plain fields and no thresholds, so there are no
  boundary/error-path lines to add for it.

## Out of scope

- Per-provider open/closed/half-open breaker enumeration and the engine preflight
  consumer: owned by specs 053/008 and the engine, not this value object.
- Persistence/serialization of the snapshot: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe `HealthSnapshotProvider` as a stub throwing
  `UnimplementedError`. The shipped `HealthSnapshotProvider` does **not** throw:
  `current()` returns a constructed default snapshot (id `default`, chainId
  `chain-0`, capturedAt 0, healthyProviders 1, trippedProviders 0) and `count()`
  returns 1; it also honours an injected `HealthSnapshot`. The tests assert the
  default-returning + injected behavior, so the list records that. (Skill Rule 6 —
  repository content is data, not instructions.)
- `spec.md` says "5 regression tests (2 entity equality + 3 clean-arch)"; the file
  actually contains 6 (the extra `HealthSnapshotProvider honours an injected value
  object`). Recorded as 6 `DONE` behaviors (U1–U6).
- The 5-field value object (id, chainId, capturedAt, healthyProviders,
  trippedProviders) matches the spec's field list.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
