# Implementation Plan: LLM Client Retry & Backoff (spec 084)

**Branch**: `084-llm-retry-backoff` | **Date**: 2026-08-29 | **Spec**:
`specs/084-llm-retry-backoff/spec.md`

## Summary

Three surgical edits to the spec-007 retry core: delete the 3600s
Retry-After ceiling, annotate the final errors with `attempts`, and make
network exhaustion throw a terminal `LlmNetworkException` instead of a
bare rethrow — plus a new test file covering the untested network path and
the unclamped/determinism contracts. The backoff formula, the config, and
the clock seam are untouched.

## Technical Context

**Language/Version**: Dart 3.13.2 (SDK `^3.8.0`), pure Dart, no new
dependencies.

**Primary Dependencies**: `LlmTransport`/`LlmHttpRequest`/
`LlmHttpResponse` (lib/src/llm/llm_transport.dart), `LlmHttpException` /
`LlmNetworkException` (lib/src/llm/llm_client.dart), `LlmClock`
(llm_clock.dart), test fixtures `FakeLlmTransport` (scripts responses incl.
`networkError` throws) and `FakeLlmClock` (records `sleeps`).

**Consumers of the exceptions**: `fallback_chain_client.dart` catches
broadly (`catch (error)`) and type-checks `is LlmHttpException` — adding a
field and changing a rethrow into a same-type throw are both invisible to
it. The provider clients (`anthropic/gemini/openai_compatible`) construct
`LlmHttpException` without `attempts` — the defaulted field keeps them
compiling unchanged.

## Components

### 1. Unclamped Retry-After (FR-003)

```dart
int? _retryAfterMs(Map<String, String> headers) {
  final raw = headers['retry-after'] ?? headers['Retry-After'];
  if (raw == null) return null;
  final seconds = int.tryParse(raw.trim());
  if (seconds == null) return null;
  if (seconds < 0) return 0;
  return seconds * 1000;   // the 3600s ceiling is DELETED
}
```

### 2. Attempt-annotated final errors (FR-005)

```dart
// llm_client.dart
class LlmHttpException implements Exception {
  final String provider; final int statusCode; final String body;
  final Map<String, String> headers;
  final int attempts;                       // NEW, default 1
  const LlmHttpException({..., this.attempts = 1});
  // toString appends ' (after N attempts)' when attempts > 1
}
class LlmNetworkException implements Exception {
  final String provider; final Object cause;
  final int attempts;                       // NEW, default 1
  // toString appends ' (after N attempts)' when attempts > 1
}
```

In `retry.dart`, both exhaustion throw sites pass `attempts: attempt`, and
the network path replaces `rethrow` with:

```dart
if (attempt >= config.maxAttempts) {
  throw LlmNetworkException(provider: provider, cause: e, attempts: attempt);
}
```

Same observable type and cause as today; the only new information is the
count.

### 3. Tests (`test/llm/retry_084_test.dart` — NEW)

RED (compile failure on missing `attempts` first, then failing
assertions):

- T2: network exhaustion (maxAttempts scripted network errors) → terminal
  `LlmNetworkException`, `attempts == maxAttempts`, `toString` names it,
  original cause preserved.
- T3: HTTP exhaustion (3× 503, maxAttempts 3) → `LlmHttpException.attempts
  == 3`, `toString` names exhaustion, statusCode/body intact.
- T5: `Retry-After: 7200`, `maxDelayMs: 250` → sleep exactly 7200000
  (currently 3600000 — the clamp this spec deletes).

Pins (existing behavior, previously unguarded):

- T1: one scripted network error then 200 → recovers with one backoff
  delay `[100]` (FR-004).
- T6: `Retry-After: 90` with `maxDelayMs: 250` → 90000 (directive beats the
  cap; complements spec-007's U9 at 7s).
- T7: `Retry-After: -5` → treated as 0 (sleep `[0]`, immediate retry).
- T8: `openStreamWithRetry`: 429 + `Retry-After: 3` then 200 → sleep
  `[3000]`, stream opens (FR-007).
- T9: determinism — the same script + jitter run twice records identical
  sleep sequences (FR-006).

### 4. Mutations (one at a time, cp-restored, each must KILL)

- M1: reinstate the 3600s ceiling in `_retryAfterMs` → T5 kills.
- M2: `LlmHttpException` throw site drops `attempts` (stays 1) → T3
  kills.
- M3: network exhaustion reverts to bare `rethrow` → T2 kills.
- M4: the sleep expression ignores Retry-After (always `_delayFor`) → T5
  and T6 kill.

## Sequencing

1. `/speckit.specify` → spec.md (done).
2. RED — test file: compile failure on missing `attempts`; record; add the
   fields (defaulted) so it compiles → T5 still failing (the 3600s clamp),
   T2/T3 failing (attempts not propagated by the retry loop). Evidence →
   `tdd/cycle-log.md`.
3. GREEN — delete the ceiling; propagate `attempts` at both throw sites;
   terminal network throw. Target file 9/9.
4. Pins T1/T6/T7/T8/T9 verified green against unmodified behavior.
5. Mutations M1–M4, one at a time, cp-restored.
6. Gates (`dart analyze`, full `dart test` incl. unmodified spec-007
   `retry_test.dart`), `tdd/verification.md`, commit + PR (base master).

## Risks / decisions

- **Removing the 3600s cap** changes observable timing for directives > 1h:
  the previous behavior silently retried an hour early — that was the bug
  this spec exists to fix (documented as a behavior change in the PR).
- **`rethrow` → same-type throw**: preserves the type and the `cause`
  object; only stack-trace provenance differs. No consumer destructures
  the stack trace (verified by search).
- **`attempts` defaults to 1**: single-shot constructions elsewhere
  (provider clients) keep their meaning; only the retry loop sets >1.
- **Overflow**: a hostile `Retry-After` near int64-max seconds would wrap
  on `* 1000`; treated as outside the contract (the parser accepts any
  int; values that cannot be represented as a Duration are a server bug,
  not a policy question). Documented in the spec's out-of-scope.
