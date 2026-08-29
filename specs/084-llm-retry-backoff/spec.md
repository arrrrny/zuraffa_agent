# Feature Specification: R4: LLM Client Retry & Backoff — transient-error resilience

**Branch**: `084-llm-retry-backoff` (off master `29b7fef`) | **Date**: 2026-08-29

**Status**: Draft → implemented on this branch

**Input**: User description: "R4: LLM Client Retry & Backoff —
transient-error resilience. Retry on 429 / 5xx / network errors with
exponential backoff + a cap; Retry-After is honored unclamped; a
deterministic clock is used for tests. Parent epic: R4 providers & fallback
(issue #5). Scope: wrap LLM client calls so transient failures are retried
with exponential backoff up to a cap. Honor the server's Retry-After header
without clamping. Use a deterministic clock (injectable) so backoff timing
is testable. Define which errors are retryable and cap total attempts;
surface a clear final error when exhausted."

## Summary

`sendWithRetry` / `openStreamWithRetry` (lib/src/llm/retry.dart, spec 007
FR-006) already retry 429/5xx with capped exponential backoff behind an
injectable `LlmClock`, and `test/llm/retry_test.dart` (U4–U9) pins that
core. What the R4 contract (issue #95) asks for that the tree does not yet
satisfy:

1. **Retry-After is clamped.** `_retryAfterMs` silently caps the header at
   3600 seconds (`if (seconds > 3600) return 3600000;`). A server that says
   "come back in 2 hours" gets retried in 1 hour — the opposite of honoring
   the directive. The R4 contract: the header is used as-is, bounded by
   nothing except arithmetic (not by `maxDelayMs`, not by any fixed
   ceiling).
2. **The final error is not clear about exhaustion.** When retries run
   out, the caller receives the last `LlmHttpException` (no attempt count)
   or the raw rethrown `LlmNetworkException` — nothing distinguishes "one
   500" from "eight 500s in a row, budget spent". The contract: the final
   error names the attempt count so operators and fallback logic can tell a
   blip from an outage.
3. **The network-error path is untested.** The retryable set is documented
   as 429/5xx/network, but no test drives `LlmNetworkException` through
   either a recovery or an exhaustion — the highest-risk half of the
   transient-failure surface ships on faith.

This spec closes all three: the 3600s ceiling is removed, both exception
types carry an `attempts` field (set on the exhaustion path, defaulted
elsewhere), network exhaustion throws a terminal `LlmNetworkException`
with the original cause and the attempt count, and the network path gets
first-class tests alongside the Retry-After and determinism pins.

**Out of scope**: HTTP-date-form `Retry-After` (the seconds form is the
contract; date-form parsing is a provider-client concern); mid-stream
restart policy (spec 008 owns it); fallback-chain behavior (spec 053);
jitter strategy changes (the injectable jitter seam stays).

## Files

- `lib/src/llm/retry.dart` — EDIT: `_retryAfterMs` drops the 3600s
  ceiling; both throw sites propagate `attempts`; network exhaustion
  throws a terminal `LlmNetworkException` (same type, original cause,
  attempts set) instead of a bare rethrow.
- `lib/src/llm/llm_client.dart` — EDIT: `LlmHttpException` and
  `LlmNetworkException` gain `attempts` (default 1) and
  exhaustion-aware `toString`.
- `test/llm/retry_084_test.dart` — NEW: the RED behaviors (unclamped
  Retry-After, attempts propagation, network exhaustion) and the pins
  (network recovery, Retry-After over maxDelay, negative header,
  openStream parity, cross-run determinism).
- `specs/084-llm-retry-backoff/` — this artifact set.

## User scenarios

### US1 — Respect the server's patience signal (P1)

As an LLM client, when a 429/5xx response carries `Retry-After: <seconds>`,
I wait exactly that long before the next attempt — whether it is larger
than my backoff cap, larger than my cap by orders of magnitude, or larger
than an hour. My policy cap governs MY computed delays, never the server's
directive.

**Why this priority**: retrying earlier than directed guarantees another
429 (wasted budget, possible penalty escalation); the current 1-hour
ceiling silently disobeys long directives.

**Independent test**: `Retry-After: 7200` with `maxDelayMs: 250` → the
recorded sleep is exactly 7200000 ms.

### US2 — Read the final error and know what happened (P1)

As fallback/budget logic, when retries are exhausted I receive a typed
final error that says how many attempts were made — `LlmHttpException`
(status, body, headers, `attempts`) or terminal `LlmNetworkException`
(cause, `attempts`) — so a blip and an outage are distinguishable without
counting logs.

**Why this priority**: exhaustion is the moment the caller must act
(fail over, shed load, alert); an error that hides the attempt count
forces log forensics.

**Independent test**: three scripted 503s with `maxAttempts: 3` → the
thrown `LlmHttpException.attempts == 3` and its `toString` names
exhaustion; the network path mirrors it.

### US3 — Trust the transient-failure surface (P2)

As an operator, the retryable set (429, 5xx, network) is fully covered:
network errors recover with the same backoff, exhaustion is terminal, the
clock is injectable so timing is deterministic run-to-run, and the stream
path (`openStreamWithRetry`) follows the same policy on the initial
exchange.

**Why this priority**: the network path is half of "transient" failures
and had zero tests; determinism is what makes every other assertion
trustworthy.

**Independent test**: a scripted network error followed by 200 recovers
with one backoff delay; two identical runs record identical sleep
sequences.

## Requirements

### Functional requirements

- **FR-001**: The retryable set is exactly: HTTP 429, HTTP 5xx, and
  `LlmNetworkException` (connection-level). Non-retryable statuses (other
  4xx) throw `LlmHttpException` immediately with zero retries (existing
  U7 pin; network recovery/exhaustion now first-class tested).
- **FR-002**: Backoff for computed delays is exponential
  (`base << (attempt-1)` plus injectable jitter) capped at
  `maxDelayMs`; total attempts are capped at `maxAttempts` (existing U8
  pin, cited).
- **FR-003**: A `Retry-After` header in seconds form is honored UNCLAMPED:
  the sleep equals the header value in ms, regardless of `maxDelayMs` or
  any fixed ceiling (the 3600s cap is removed). Negative values are
  treated as 0; absent/unparseable headers fall back to the computed
  backoff.
- **FR-004**: Network errors (`LlmNetworkException`) are retried under the
  same policy (same backoff, same `maxAttempts`).
- **FR-005**: On exhaustion the final error is typed and
  attempt-annotated: the HTTP path throws `LlmHttpException` with
  `attempts == maxAttempts`; the network path throws a terminal
  `LlmNetworkException` (same type as the cause chain, original `cause`,
  `attempts == maxAttempts`); both `toString` forms name the attempt
  count. Outside the retry loop the exceptions default to `attempts: 1`
  (single-shot semantics, e.g. provider clients).
- **FR-006**: Timing is deterministic under the injected clock: the same
  script + the same jitter function produce byte-identical sleep
  sequences across runs (`LlmClock` seam, existing; now pinned
  cross-run).
- **FR-007**: `openStreamWithRetry` follows the identical policy on the
  initial HTTP exchange (retryable statuses, Retry-After, attempts on the
  final error).
- **FR-008**: Gates — `dart analyze` reports no new issues relative to the
  master baseline (3 pre-existing, out of scope); the full `dart test`
  suite is green, including the unmodified spec-007 `test/llm/retry_test.dart`.

### Key entities

- `RetryConfig` — `maxAttempts`, `baseDelayMs`, `maxDelayMs` (unchanged).
- `LlmHttpException` / `LlmNetworkException` — gain `attempts`.
- `LlmClock` — injectable clock/sleep seam (unchanged).
- `sendWithRetry` / `openStreamWithRetry` — policy unchanged except
  FR-003/FR-005.

## Success criteria

- **SC-001**: `Retry-After: 7200` with `maxDelayMs: 250` → sleep exactly
  7200000 ms; `Retry-After: 90` with `maxDelayMs: 250` → 90000 ms (US1).
- **SC-002**: HTTP exhaustion → `LlmHttpException.attempts == maxAttempts`
  with exhaustion named in `toString`; network exhaustion → terminal
  `LlmNetworkException` with original cause and `attempts ==
  maxAttempts` (US2).
- **SC-003**: Network error → recovery with the standard backoff; two
  identical runs → identical sleep sequences; `openStreamWithRetry`
  honors Retry-After on the initial exchange (US3).
- **SC-004**: Gates green; spec-007 retry tests pass unmodified.

## Dependencies

- Builds on: spec 007 FR-006 (retry/backoff core, `LlmClock` seam) and
  the spec-007 test fixtures (`FakeLlmTransport`, `FakeLlmClock`).
- Independent of: fallback chain (053), circuit breaker (035), MCP
  (082), ledger (083) — different files.
