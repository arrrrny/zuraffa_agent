# Implementation Plan: CircuitBreaker state machine — recovery readiness + persistence contract

**Branch**: `feat/specs-032-033-034-035` (spec dir: `035-circuit-breaker`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/035-circuit-breaker/spec.md`

## Summary

Complete the recovery semantics the task names: add the `shouldProbe(DateTime)` read (recovery readiness — the coordinator's "when is the half-open probe due" question, currently re-derived by hand from `openedAt` and `cooldown`), add the persistence contract (`toJson`/`fromJson` round-tripping all nine fields exactly — a restored open breaker continues its cooldown, a mid-probe breaker resumes with partial counters), and pin the full recovery cycle as a composed regression test (recovery resets the failure streak; re-trip needs a fresh threshold; half-open failure re-trips with reset). The transition methods, reads, and equality are untouched (compile parity pinned by the 12 existing tests).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler`/`NoParams` for the service surface), `test` ^1.25.0. No new dependencies.

**Storage**: N/A in this feature — the value object defines the JSON contract the chain-state persistence consumes; no store is rewired.

**Testing**: `dart test`; single test via `dart test <file> -n "<name>"` (mind regex-special characters — 033 lesson); gates per `.specify/memory/tdd-profile.md` (`dart analyze --fatal-infos` clean; full suite post-034 baseline 640 passed).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: `shouldProbe` is O(1) arithmetic; `toJson` is a single pass; transitions unchanged (one snapshot allocation each).

**Constraints**: Hand-curated plain Dart value object (no `@Zorphy` codegen — established pattern for this entity family). No `dart:io` (constitution VII). Existing constructor, transitions, reads, equality unchanged; all additions additive.

**Scale/Scope**: 1 lib file enriched + 1 new test file (~13 tests) + spec/plan/tasks/tdd artifacts.

## Constitution Check

`.specify/memory/constitution.md` read. IX (Zorphy model layer): this entity family ships as HAND-CURATED plain Dart by explicit repo precedent (header: "Pattern: plain Dart value object (no @Zorphy annotation)... same as AgentSession (PR #50)") — the refinement stays inside that documented exception. VII (engine purity): no dart:io. X (pristine analysis): gate is `dart analyze --fatal-infos` zero findings. Passed.

## Project Structure

### Documentation (this feature)

```text
specs/035-circuit-breaker/
├── spec.md            # refined via /speckit.specify
├── plan.md            # this file
├── tasks.md           # /speckit.tasks output
└── tdd/
    ├── test-list.md
    ├── cycle-log.md
    └── verification.md
```

### Source Code (repository root)

```text
lib/src/domain/entities/circuit_breaker/circuit_breaker.dart        # + shouldProbe + toJson/fromJson
test/domain/entities/circuit_breaker/circuit_breaker_test.dart      # NEW: recovery semantics (the deliverable)
test/data/providers/circuit_breaker/circuit_breaker_provider_test.dart # existing: compile parity + transitions keep passing
```

## Architecture / Data Flow

```text
fallback-chain coordinator (later PR)
   │ shouldProbe(now)?                ← read-only: "is the half-open probe due?"
   ├── false in closed / halfOpen / open-not-elapsed  → skip or wait
   └── true in open-elapsed           → tryHalfOpen(now) (the coordinator's call)
                                          ▼
CircuitBreaker (immutable snapshot)
   · state (closed | open | halfOpen)          # existing transitions pinned:
   · failureCount / failureThreshold           #   recordFailure: closed→open at threshold,
   · openedAt? / cooldown                      #                 halfOpen→open (reset probes)
   · halfOpenSuccesses / halfOpenThreshold     #   recordSuccess: halfOpen→closed at threshold
   · lastFailureAt?                            #   tryHalfOpen:   open→halfOpen when elapsed
   · shouldProbe(now)                          #   NEW read (FR-002)
   · toJson/fromJson                           #   NEW persistence (FR-004/005)
   ▼
CircuitBreakerService <- CircuitBreakerProvider (unchanged stubs, compile parity)

restart boundary: fromJson(toJson(open breaker)) → cooldown continues from original openedAt
```

Key decisions:

1. **`shouldProbe` is a read, not a transition** — the scaffold's doc assigns the coordinator the transition call; the read closes the documented-but-missing decision surface without taking over the coordinator's job. Inclusive boundary (`elapsed >= cooldown`) matches `tryHalfOpen`'s own check.
2. **Full-cycle regression as characterization** — the cycle (trip → cooldown → probe → close → fresh streak → re-trip) composes existing transitions; it lands green-on-scaffold by design (a pin against future refactor leakage, e.g. failureCount surviving recovery). The genuinely red surfaces are `shouldProbe` + serialization.
3. **JSON shape** — `{id, state, failureCount, failureThreshold, cooldown (µs int), halfOpenSuccesses, halfOpenThreshold, openedAt?, lastFailureAt?}` camelCase, state as its name, nulls omitted, `Duration` as exact microseconds — the house shape from 031-034 extended with the duration rule.
4. **Parse-time threshold validation** — the scaffold's docs say thresholds "must be > 0" and cooldown "must be > Duration.zero" but the constructor does not enforce; `fromJson` is the enforcement point for parsed input (documented; constructor validation stays out of scope to avoid breaking existing construction paths).
5. **Layers untouched behaviorally** — FR-006: the provider's UnimplementedError stubs are the current contract.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the 12 existing tests.** All additions are additive; transitions, reads, equality, and the constructor are untouched. Verified in the green run.
- **Risk: `lib/src/llm/circuit_breaker.dart` confusion.** The repo has TWO breaker files — the LLM-runtime breaker (llm/, spec 007/008 family, has its own tests) and the domain value object (this spec's file list centers on it; the repo's spec.md Files section names only the domain entity/service/provider). This feature touches ONLY the domain value object. The task's file list mentions the llm/ file as context; the repo spec.md governs scope.
- **Risk: boundary semantics divergence.** `tryHalfOpen` transitions when `elapsed >= cooldown` (inclusive); `shouldProbe` must agree exactly or a coordinator would probe-ask true and transition-fail false. The boundary test pins both sides with the same clock values.
- **Risk: Duration round-trip drift.** Serializing as seconds/millis loses sub-ms precision; microseconds as int is exact (`Duration(microseconds: n)`).
- **Risk: fromJson type coercion.** Counters must be non-negative ints, thresholds >= 1, cooldown > 0, state must route through a name→enum parse with typed failure; timestamps ISO-8601 with tryParse guard.

## Implementation Phases

Phase 1 — `shouldProbe` read (test-first: AC US1-1..3 — compile red).
Phase 2 — full-cycle recovery regression (characterization: AC US2-1..3 — green-on-scaffold by design, documented).
Phase 3 — persistence contract (test-first: AC US3-1..3 — compile red).
Phase 4 — Gates: full suite + analyze; existing provider tests untouched and passing; mutation spot-checks.

All behavioral phases run through the TDD loop with recorded red evidence; the characterization phase's green-on-scaffold status is recorded honestly in the cycle log.
