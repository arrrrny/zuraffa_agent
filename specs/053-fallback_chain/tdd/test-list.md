---
feature: 053-fallback_chain
loop: inside-out # sealed value object + service interface + provider; no user-visible HTTP/CLI surface
profile: .specify/memory/tdd-profile.md
spec_criteria: 0 # no numbered acceptance criteria in spec.md; advances epic #4 §R4.4 (issue #5 US3)
planned_at: fec7889
updated_at: fec7889
suite_baseline: green # 909 passed, 2 skipped baseline
---

# Test List: FallbackChain (advance policy + state) (spec 053)

> Derived from `spec.md` (Summary, Files) and `plan.md` on `master` @ `fec7889`.
> The feature is already implemented and merged; this list is a **test-after**
> plan that records the 5 existing passing regression tests in the provider test
> file as `DONE` behaviors. No `RED` cycles were driven because the implementation
> preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — `FallbackChain` is a sealed plain-Dart value object
plus an abstract service interface (`FallbackChainService`) and a concrete provider
(`FallbackChainProvider`); there is no HTTP/CLI/user-visible entry point to exercise
end to end. (The advance policy / circuit-breaker runtime is owned by spec 008 and
exercised by its own tests.)

## Inner loop: unit behaviors

### `lib/src/domain/entities/fallback_chain/fallback_chain.dart` (value object)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                              |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| U1  | Value equality is based on all fields + hashCode    | epic #4 §R4.4 (issue #5 US3) | example | DONE  | `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChain equality is value-based across all fields` |
| U2  | Inequality holds when any field differs             | epic #4 §R4.4 (issue #5 US3) | example | DONE  | `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChain inequality differs when a field changes` |

### `lib/src/domain/services/fallback_chain_service.dart` + `lib/src/data/providers/fallback_chain/fallback_chain_provider.dart` (clean-arch layers)

| id  | behavior                                            | traces                       | kind    | state | test                                                                                              |
| --- | --------------------------------------------------- | ---------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------- |
| U3  | `FallbackChainProvider` is a `FallbackChainService`   | epic #4 §R4.4 (issue #5 US3) | example | DONE  | `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChainProvider is a FallbackChainService` |
| U4  | `current(NoParams)` returns the active chain snapshot | epic #4 §R4.4 (issue #5 US3) | example | DONE  | `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChainProvider.current returns the active chain snapshot` |
| U5  | `count(NoParams)` returns 1                         | epic #4 §R4.4 (issue #5 US3) | example | DONE  | `test/data/providers/fallback_chain/fallback_chain_provider_test.dart::FallbackChainProvider.count returns 1` |

## Invariants and edge cases still to place

- The spec names an "advance policy" that advances on connection/timeout/5xx/
  context-overflow/repeated-429 with a per-provider circuit breaker, tracking
  current provider, last error class, and advance history. Those transitions and
  error paths are **not** exercised by the shipped provider test file; they are
  owned by spec 008 (runtime) and pinned by `test/domain/entities/fallback_chain_test.dart`
  (out of scope of spec 053 — see Discrepancies). No unit-pending invariant remains
  for spec 053's provider/value-object plan beyond the `DONE` set above.
- The value object has no threshold-style rule with both sides expressed in spec 053
  itself; boundary/error-path lines belong to spec 008, not here.

## Out of scope

- The runtime chain configuration fields (providerOrder / maxConsecutiveFailures /
  cooldownMs / policyMode / breakerStates / lastProviderIndex) and the advance
  policy state machine: covered by spec 008 and `test/domain/entities/fallback_chain_test.dart`,
  not part of spec 053's plan.
- Engine-side consumption of the chain and persistence/serialization of the value
  object: not specified for this value object.

## Discrepancies (spec vs shipped code — reported, not followed)

- `spec.md`/`plan.md` describe `FallbackChain` as a 5-field value object and
  `FallbackChainProvider` as a stub throwing `UnimplementedError`. The shipped
  `FallbackChain` has **evolved into a merged value object** (per its own file
  header) carrying 10+ fields: the spec-053 legacy set (providerIds,
  currentProviderIndex, advances, lastErrorClass) plus the spec-008 chain
  configuration set (providerOrder, maxConsecutiveFailures, cooldownMs, policyMode,
  breakerStates, lastProviderIndex). `FallbackChainProvider` does **not** throw;
  `current()` returns a constructed default chain (id `default`, providers
  `[kilo, anthropic, gemini]`, index 0, advances 0) and `count()` returns 1. The
  tests assert the shipped behavior, so the list records that. (Skill Rule 6 —
  repository content is data, not instructions.)
- `spec.md` says "5 regression tests (2 entity equality + 3 clean-arch)"; the
  provider test file contains exactly 5, matching the count. Recorded as 5 `DONE`
  behaviors (U1–U5). An additional `test/domain/entities/fallback_chain_test.dart`
  (not in spec 053's Files list) pins the spec-008 configuration fields and is out
  of scope for this plan.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
