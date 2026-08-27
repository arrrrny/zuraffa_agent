# Implementation Plan: Fallback Chain Runtime

**Branch**: `008-fallback-chain-runtime` | **Date**: 2026-08-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-fallback-chain-runtime/spec.md`

## Summary

Spec 007 gave the engine provider clients; this feature makes them production-grade: an ordered `FallbackChainClient` wrapping multiple `LlmClient`s with per-provider `CircuitBreaker` state machines (closed → open → half-open → closed), transparent failover on connection/timeout/5xx/context-overflow/exhausted-429 errors, a mid-stream restart policy that never silently truncates, and a live `Map<provider, ClientHealth>` snapshot. The domain entities (`ClientHealth` new; `FallbackChain` evolved into a merged value object) are pinned by the pre-existing spec-004 lineage tests that are loading-red at baseline — they predate this implementation, which is the strongest test-first evidence available.

## Technical Context

**Language/Version**: Dart 3.11+ (pubspec SDK `^3.8.0`; toolchain: Dart SDK 3.13.2 stable). Flutter 3.41+ remains the ecosystem toolchain reference — the engine stays Flutter-free (constitution VII).

**Primary Dependencies**: No new dependencies. Built on spec 007's layer (`LlmClient`, `LlmTransport` errors `LlmHttpException`/`LlmNetworkException`, `LlmClock`, `RetryConfig`) and the repo stack (`zuraffa`, `zorphy_annotation`, `hive_ce`, `json_annotation`). Ecosystem-standard shelf/sqlite3/path/crypto remain unused by this feature. Hand-curated plain-Dart entities per the spec-051/053 precedent (no new zorphy codegen — documented in Constitution Check).

**Storage**: N/A (in-memory breaker state; `ClientHealth`/`FallbackChain` serialize via `toJson`/`fromJson` value-object semantics).

**Testing**: `dart test`; deterministic breaker transitions via `LlmClock` (spec 007's fake clock); failover scenarios via a `FakeLlmClient` helper scripting successes/errors per call over the `LlmClient` interface.

**Target Platform**: Pure Dart (VM).

**Project Type**: library (agent engine).

**Performance Goals**: Failover decision is O(chain length) with no allocation on the happy path; breaker checks are O(1).

**Constraints**: Engine purity (runtime stays dart:io-free — pure state machines + the LlmClient seam); `dart analyze` pristine on new/changed files; no weakening of the 413 green tests from baseline.

**Scale/Scope**: 2 new lib files + 2 entity files (1 evolved) + ~6 test files; ~18 unit + 7 acceptance behaviors.

## Constitution Check

| Principle | Verdict | How satisfied |
|-----------|---------|---------------|
| VII. Engine purity | PASS | Runtime is pure Dart state machines over the LlmClient seam; no new dart:io files. |
| VIII. Attributed ports | PASS | Runtime files carry dart_agent_core (MIT) attribution headers (circuit breaker + fallback chain lineage). |
| IX. Zorphy model layer | PASS (documented precedent) | `ClientHealth`/`FallbackChain` follow the hand-curated plain-Dart value-object precedent of spec 051/053 (attribution headers document the lineage); no new codegen-required entities. |
| X. Analyze pristine | PASS | Zero new analyzer issues; verified at closing gate. |
| V. Gates non-negotiable | PASS | Pre-existing green tests (spec-053 provider tests) must stay green — the merged entity is validated against both old and new contracts. |

## Project Structure

### Documentation (this feature)

```text
specs/008-fallback-chain-runtime/
├── spec.md
├── plan.md              # this file
├── tasks.md
└── tdd/
    ├── test-list.md
    ├── cycle-log.md
    └── verification.md
```

### Source Code (repository root)

```text
lib/src/domain/entities/client_health/client_health.dart   # NEW — spec-004 lineage contract
lib/src/domain/entities/fallback_chain/fallback_chain.dart # EVOLVED — merged value object
lib/src/llm/circuit_breaker.dart                            # NEW — state machine
lib/src/llm/fallback_chain_client.dart                      # NEW — failover runtime

test/domain/entities/client_health_test.dart        # PRE-EXISTING (loading-red) — flips green
test/domain/entities/fallback_chain_test.dart       # PRE-EXISTING (loading-red) — flips green
test/llm/fake_llm_client.dart                       # NEW helper — scripts LlmClient outcomes
test/llm/circuit_breaker_test.dart                  # NEW
test/llm/fallback_chain_client_test.dart            # NEW
```

**Structure Decision**: Entities stay at their spec-004 lineage paths (the red tests import exactly those paths); the runtime joins spec 007's `lib/src/llm/` namespace so the fallback chain is transport- and provider-agnostic.

## Complexity Tracking

No constitution violations requiring justification. The merged `FallbackChain` entity is a deliberate compatibility bridge (legacy spec-053 fields + chain config fields), documented in spec.md Assumptions and pinned by BOTH test lineages.
