# Implementation Plan: CircuitBreaker state machine
**Branch**: `035-circuit-breaker` | **Date**: 2026-08-24

## Summary
Hand-curate the `CircuitBreaker` value object + `CircuitBreakerState` enum (R4.3 spec-exact) + `CircuitBreakerService` + `CircuitBreakerProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers) and PR #50 (AgentSession root entity): plain Dart value object, no `@Zorphy` codegen, compiles without `build_runner`. The repo doesn't yet ship `LlmClient` or any provider client; this PR adds the state machine that governs fail-over between providers in the fallback chain.

The breaker is modeled as an immutable snapshot: each transition (`recordFailure`, `recordSuccess`, `tryHalfOpen`) is a pure function returning a new `CircuitBreaker` instance. The engine (or a separate `FallbackChain` coordinator in a later PR) is responsible for calling the right transition at the right time — the value object itself has no timers, no I/O, no shared mutable state.

## Phase 1 — Design
- **CircuitBreakerState** (enum): `closed` (normal — requests pass through; consecutive failures increment failureCount), `open` (tripped — requests fail-fast; after cooldown elapses, transitions to `halfOpen`), `halfOpen` (probing — limited trial requests; success → `closed`, failure → `open`).
- **CircuitBreaker** (value object, immutable snapshot): `id` (String, required — names the provider the breaker guards), `state` (CircuitBreakerState, default `closed`), `failureCount` (int, default 0 — consecutive failures in `closed` state), `failureThreshold` (int, required — failures needed to trip `open`), `openedAt` (DateTime?, optional — when tripped to `open`; null when `closed`), `cooldown` (Duration, required — time in `open` before transitioning to `halfOpen`), `halfOpenSuccesses` (int, default 0 — consecutive successes in `halfOpen`), `halfOpenThreshold` (int, required — successes needed to close from `halfOpen`), `lastFailureAt` (DateTime?, optional — when the most recent failure happened, for health-snapshot reporting). Value equality across all nine fields.
- **Transition methods** (pure functions returning new snapshots):
  - `recordFailure({DateTime? at})`: closed → open (when failureCount+1 ≥ failureThreshold, sets openedAt and lastFailureAt) or closed → closed (failureCount+1, lastFailureAt updated); halfOpen → open (resets halfOpenSuccesses, sets openedAt); open → open (unchanged except lastFailureAt).
  - `recordSuccess()`: halfOpen → closed (when halfOpenSuccesses+1 ≥ halfOpenThreshold, resets failureCount, clears openedAt) or halfOpen → halfOpen (halfOpenSuccesses+1); closed → closed (resets failureCount to 0); open → open (unchanged).
  - `tryHalfOpen(DateTime now)`: open → halfOpen (when `now - openedAt ≥ cooldown`, resets nothing — failureCount stays for context); halfOpen → halfOpen (unchanged); closed → closed (unchanged).
- **Service** (`CircuitBreakerService`): abstract, two `NoParams`-param methods — `current(NoParams)` returns the current breaker snapshot, `count(NoParams)` returns the count of breakers in the fallback chain.
- **Provider** (`CircuitBreakerProvider`): concrete stub implementing `CircuitBreakerService` with matching `NoParams` signatures; bodies throw `UnimplementedError`.

## Phase 2 — Tasks
See `tasks.md`.
