# Feature Specification: CircuitBreaker state machine (R4 providers & fallback)

**Branch**: `035-circuit-breaker` | **Date**: 2026-08-24

## Summary
Hand-curated `CircuitBreaker` value object + `CircuitBreakerState` enum — spec-exact from epic #1 §R4.3 (issue #5 body: "Fallback chain (supersedes arrrrny/dart_agent_core#1): ordered provider chain, circuit breaker (open/half-open/close with backoff), mid-stream restart policy, health snapshot"). The repo doesn't yet ship a `LlmClient` interface or any provider client; this PR adds the **circuit breaker** — the state machine that governs fail-over between providers in the fallback chain. Modeled as an immutable snapshot with pure transition methods (`recordFailure`, `recordSuccess`, `tryHalfOpen`) so the engine can drive it without timers or shared mutable state.

This advances epic issue #5 (R4 — providers & fallback). The `LlmClient` interface and the provider port (OpenAI-compatible / Anthropic / Gemini) build on this surface in later PRs.

## Files
- `lib/src/domain/entities/circuit_breaker/circuit_breaker.dart` — `CircuitBreakerState` enum (closed/open/halfOpen) + `CircuitBreaker` value object (id + state + failureCount + failureThreshold + openedAt? + cooldown + halfOpenSuccesses + halfOpenThreshold + lastFailureAt?; value-based equality; transition methods `recordFailure` / `recordSuccess` / `tryHalfOpen` returning new immutable snapshots).
- `lib/src/domain/services/circuit_breaker_service.dart` — abstract `CircuitBreakerService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/circuit_breaker/circuit_breaker_provider.dart` — concrete `CircuitBreakerProvider` stub (UnimplementedError bodies).
- `test/data/providers/circuit_breaker/circuit_breaker_provider_test.dart` — 12 regression tests (9 state machine + 3 clean-arch).
- `specs/035-circuit-breaker/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 12 new tests pass

## Advances #5 (R4 — providers & fallback)
