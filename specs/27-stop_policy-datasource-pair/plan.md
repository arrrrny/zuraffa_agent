# Implementation Plan: StopPolicy datasource + mock pair

**Branch**: `feat/specs-025-027-029-031` (spec dir: `27-stop_policy-datasource-pair`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/27-stop_policy-datasource-pair/spec.md`

## Summary

Complete the stop-policy clean-arch chain: extend the datasource interface from the 2-method stub to the 3-method persistence contract (`current`/`update`/`reset`), implement the mock in memory (default-seeded, full-replace update, restore-default reset), add the missing concrete repository over the datasource, and rewrite the provider from `UnimplementedError` stubs to real repository delegation. `StopPolicy.defaultPolicy` becomes the single source of truth for the documented default values.

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler` mixins, `NoParams`), `test` ^1.25.0.

**Storage**: None — the mock is the in-memory reference store; the interface is the persistence contract.

**Testing**: `dart test`; single test via `--plain-name`; gates per `.specify/memory/tdd-profile.md` (`dart analyze` 5-issue pre-existing baseline, zero new).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: Chain adds no I/O — read path is a single map/field access per layer.

**Constraints**: `Duration` field must stay hand-curated (zfa issue #13); constructor backward compatibility (FR-006); no new dependencies; no codegen.

**Scale/Scope**: 5 lib files (entity + datasource interface + mock + new repository impl + provider rewrite) + 2 test files (datasource pair; chain consumption) ≈ 25 tests.

## Constitution Check

*No `.specify/memory/constitution.md`; repo AGENTS.md rules apply. Hand-curated files keep the `HAND-CURATED — DO NOT REGENERATE VIA zfa` banner with issue references (#27/#28 for the datasource pair, #14 for the repository/service/provider). Passed.*

## Project Structure

### Documentation (this feature)

```text
specs/27-stop_policy-datasource-pair/
├── spec.md            # refined via /speckit.specify
├── plan.md            # this file
├── tasks.md           # /speckit.tasks output
└── tdd/
    ├── test-list.md   # /speckit.tdd.plan output
    ├── cycle-log.md   # red/green evidence
    └── verification.md
```

### Source Code (repository root)

```text
lib/src/domain/entities/stop_policy/stop_policy.dart                  # + defaultPolicy constant
lib/src/data/datasources/stop_policy/stop_policy_datasource.dart       # interface: + update(policy)
lib/src/data/datasources/stop_policy/stop_policy_mock_datasource.dart  # in-memory impl
lib/src/data/repositories/stop_policy_repository_impl.dart             # NEW: repo over datasource
lib/src/data/providers/stop_policy/stop_policy_provider.dart           # rewrite: real delegation
test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart # rewritten: real behavior
test/data/providers/stop_policy/stop_policy_provider_test.dart          # NEW: chain consumption
```

## Architecture / Data Flow

The repo's datasource-pair clean-architecture pattern, completed end to end:

```text
StopPolicyService (domain interface)          ◀ engine-facing
        ▲ implements
StopPolicyProvider (data layer)
        │ delegates to
StopPolicyRepository (domain interface)
        ▲ implements
StopPolicyRepositoryImpl (data layer)         ◀ NEW seam
        │ delegates to
StopPolicyDatasource (interface, data layer)  ◀ persistence contract
        ▲ implements
StopPolicyMockDatasource (in-memory)          # swap target for Hive/remote
```

Key decisions:

1. **`StopPolicy.defaultPolicy` static const** on the entity — single source of truth for `maxTurns=100, wallClockTimeout=0, repetitionThreshold=5, enabled=true, id='default'`; the mock's reset target and the provider's `defaultPolicy` both reference it.
2. **Repository raises `StateError` on id mismatch** (`getCurrent('unknown')`) — wrong-id reads are wiring bugs and must not be silently substituted (edge-1). `update` stores the policy verbatim (full replace), so a changed id makes the old id unreachable.
3. **Provider defaults its wiring** — parameterless `StopPolicyProvider()` keeps compiling (FR-006) by defaulting to a fresh `StopPolicyMockDatasource()` behind the datasource interface; constructor injection accepts any datasource for tests and backend swaps. Design correction (TDD cycle 4 red): the service surface is id-less (`NoParams`), so the provider consumes the datasource's id-less `current()` directly — an id-keyed `getCurrent(id)` delegation cannot serve an arbitrary active policy. The repository stays the id-keyed domain seam; both consume the datasource ("how the service/repository consume it").
4. **Enforcement stays out** — the pair persists and serves the policy; turn-count comparisons belong to the engine loop (spec 002/046). Tests never assert stop-condition firing.

## Meticulous Analysis / Risk Assessment

- **Risk: provider rewrite breaks existing stub tests.** Intended (documented drift remediation); the `isA<StopPolicyService>()` compile-parity check is kept, `UnimplementedError` assertions are replaced by delegation behavior.
- **Risk: repository impl placement.** The repo has no `lib/src/data/repositories/` directory yet — this feature creates it, matching the clean-arch layering already used for datasources/providers. The domain interface stays untouched (it is already correct).
- **Risk: `Duration.zero` in const context.** `Duration.zero` is a const static — `static const StopPolicy defaultPolicy = StopPolicy(...)` with `wallClockTimeout: Duration.zero` compiles const.
- **Risk: default duplication.** Three call sites (mock seed/reset, provider defaultPolicy) — all reference the one constant; drift is structurally impossible.
- **Risk: async `defaultPolicy`.** The domain interface declares it synchronous (`StopPolicy defaultPolicy(NoParams)`); the provider keeps that signature exactly — no signature change to the domain layer.

## Implementation Phases

Phase 1 — Entity: add `StopPolicy.defaultPolicy` constant (test-first: default surface + values).
Phase 2 — Datasource: extend interface with `update`; implement mock in memory.
Phase 3 — Repository: `StopPolicyRepositoryImpl` over the datasource with `StateError` on id mismatch.
Phase 4 — Provider: rewrite to consume the datasource (id-less read); keep parameterless default wiring.
Phase 5 — Tests: datasource pair behavior + full-chain consumption; green suite + clean analyze.

All behavioral phases run through the TDD loop with recorded red evidence.
