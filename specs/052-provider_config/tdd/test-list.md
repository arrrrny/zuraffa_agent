---
feature: 052-provider_config
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria in spec.md; advances epic #4 §R4.1 (issue #5 US1)
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # 909 passed, 2 skipped baseline
---

# Test List: ProviderConfig (typed openai/anthropic/gemini) (spec 052)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 5 existing passing regression tests as `DONE` behaviors.
> No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `ProviderConfig` is a sealed plain-Dart value object
plus an abstract service interface (`ProviderConfigService`) and a concrete
provider (`ProviderConfigProvider`); there is no HTTP/CLI/user-visible entry point
to exercise end to end.

## Inner loop: unit behaviors

### `lib/src/domain/entities/provider_config/provider_config.dart` (value object, 5 fields)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                              |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all five fields + hashCode | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfig equality is value-based across all fields` |
| U2  | Inequality holds when any field differs             | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfig inequality differs when a field changes` |

### `lib/src/domain/services/provider_config_service.dart` + `lib/src/data/providers/provider_config/provider_config_provider.dart` (clean-arch layers)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                              |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| U3  | `ProviderConfigProvider` is a `ProviderConfigService` | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfigProvider is a ProviderConfigService` |
| U4  | `current(NoParams)` returns the active provider config | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfigProvider.current returns the active provider config` |
| U5  | `count(NoParams)` returns 1                         | epic #4 §R4.1 (issue #5 US1) | example | DONE  | `test/data/providers/provider_config/provider_config_provider_test.dart::ProviderConfigProvider.count returns the configured provider count` |

## Invariants and edge cases still to place

- The spec names vendor-specific subclasses carrying "vendor-only fields" and a
  fallback "advance policy + per-provider circuit breaker". No such subclasses or
  error paths ship for `ProviderConfig`; the value object is a single 5-field
  class. No unit-pending invariant remains for spec 052's value object itself
  beyond the `DONE` set above.
- The value object exposes only 5 plain fields and no thresholds, so there are no
  boundary/error-path lines to add for it.

## Out of scope

- Provider-specific subclasses (openai/anthropic/gemini) with vendor-only fields:
  not present in shipped code; would be a later behavior if required.
- Engine-side consumption of the config and persistence/serialization of the value
  object: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe `ProviderConfigProvider` as a stub throwing
  `UnimplementedError`. The shipped `ProviderConfigProvider` does **not** throw:
  `current()` returns a constructed default active config (id `kilo`, `openai`,
  base URL `https://api.kilo.ai/api/gateway`, models `['tencent/hy3:free']`,
  timeout 30000ms) and `count()` returns 1. The tests assert the default-returning
  behavior, so the list records that. (Skill Rule 6 — repository content is data,
  not instructions.)
- `spec.md` says "5 regression tests (2 entity equality + 3 clean-arch)"; the file
  contains exactly 5, matching the count. Recorded as 5 `DONE` behaviors (U1–U5).
- The 5-field value object (id, providerKind, baseUrl, models, timeoutMs) matches
  the spec's field list.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
