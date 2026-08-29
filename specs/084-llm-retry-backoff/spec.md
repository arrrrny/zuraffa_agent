# Feature Specification: LLM Client Retry & Backoff

**Feature Branch**: `084-llm-retry-backoff`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for the LLM client retry & backoff layer — retryable status/network handling, exponential backoff with cap, and Retry-After honoring — that is not yet covered by an existing spec (R4)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Survive a transient 429/5xx or network blip (Priority: P1)

When the LLM HTTP transport returns a 429 (rate limit) or 5xx, or throws a network exception, the client retries up to `maxAttempts` with exponential backoff (base, capped), then surfaces a typed `LlmHttpException` rather than a raw transport error.

**Why this priority**: Transient provider errors are the dominant real-world failure; without retry the engine aborts on the first hiccup.

**Independent Test**: Can be fully tested with a fake transport that fails the first N attempts then succeeds, asserting the call eventually returns and the backoff sequence is applied via an injected clock.

**Acceptance Scenarios**:

1. **Given** a transport that fails the first attempt with a 503 then succeeds, **When** `sendWithRetry` is called with `maxAttempts=4`, **Then** the response is returned (retry succeeded).
2. **Given** a transport that always returns 500, **When** attempts are exhausted, **Then** an `LlmHttpException` is thrown with the provider, status code, and body.

---

### User Story 2 - Honor the server's Retry-After (Priority: P2)

When the server replies 429 with a `Retry-After` header (seconds), the client waits that long before the next attempt. The server directive is authoritative and is NOT clamped by the configured `maxDelayMs`.

**Why this priority**: A provider may know its own cooldown; clamping it would retry too early and get rate-limited again.

**Independent Test**: Can be fully tested by having the fake transport return a `retry-after: 120` header and asserting the next delay equals 120000ms regardless of `maxDelayMs`.

**Acceptance Scenarios**:

1. **Given** a 429 with `Retry-After: 120`, **When** the next backoff is computed, **Then** the delay is exactly 120000ms (not clamped to `maxDelayMs`).
2. **Given** a 429 with no `Retry-After`, **When** the next backoff is computed, **Then** the delay follows the exponential policy capped at `maxDelayMs`.

---

### Edge Cases

- Only 429 and `>=500` statuses are retryable; 4xx (e.g. 400/401/403) are non-retryable and throw immediately.
- Exhausting `maxAttempts` on a retryable status throws `LlmHttpException` (never silently returns a failed response).
- A network exception on the final attempt is rethrown (not swallowed).
- Backoff must be deterministic under test: an injected `LlmClock` + optional `jitter` function make the delay sequence observable without wall-clock sleeps (constitution fixtures-only rule).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `sendWithRetry` / `openStreamWithRetry` MUST retry on `LlmNetworkException` and on 429 / `>=500` responses, up to `maxAttempts` (default 4).
- **FR-002**: Backoff MUST be exponential from `baseDelayMs` (default 500ms), capped at `maxDelayMs` (default 30000ms).
- **FR-003**: A `Retry-After` header (seconds form) MUST be honored as-is and MUST NOT be clamped by `maxDelayMs`.
- **FR-004**: Non-retryable statuses, or exhausting attempts, MUST throw `LlmHttpException` (never return a failed response or rethrow a raw transport error as-is).
- **FR-005**: An injected `LlmClock` and optional `jitter` function MUST make the backoff sequence deterministic and testable without real sleeps.

### Key Entities

- **RetryConfig**: `{ maxAttempts, baseDelayMs, maxDelayMs }` — the retry policy.
- **sendWithRetry / openStreamWithRetry**: the retry-driving functions over an `LlmTransport`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A transient network blip on attempt N succeeds on the next attempt (no data loss, correct response returned).
- **SC-002**: A `Retry-After` directive is honored unclamped; an absent header falls back to the capped exponential policy.
- **SC-003**: Exhausting `maxAttempts` on a retryable status always throws `LlmHttpException` (no silent success, no raw rethrow).

## Assumptions

- Mid-stream failures during an open stream propagate to the caller; only the initial HTTP exchange is retried (restart-on-next-provider is spec 008's policy decision).
- `RetryConfig` defaults match spec 007 FR-006; they are overridable per call.
- This feature maps to **R4 (providers & fallback, issue #5)** — production reliability for ported LLM clients.
