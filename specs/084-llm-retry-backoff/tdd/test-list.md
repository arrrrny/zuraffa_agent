# Test List: LLM Client Retry & Backoff (spec 084)

---
feature: 084-llm-retry-backoff
loop: outside-in
profile: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: master (29b7fef)
updated_at: 084-llm-retry-backoff
suite_baseline: green # 1073 passed / 2 skipped at 29b7fef
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | A transient failure is survived or clearly terminal: a network error recovers with standard backoff; exhaustion surfaces a typed, attempt-annotated final error; the server's Retry-After directive is obeyed exactly, however large | FR-003, FR-004, FR-005, SC-001..SC-003 | example | PLANNED | `test/llm/retry_084_test.dart` (T1–T8) |
| A2  | Gates: `dart analyze` clean vs baseline; full `dart test` green including the unmodified spec-007 `test/llm/retry_test.dart` | FR-008 | gate | PLANNED | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### New surface (RED)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Network exhaustion → terminal `LlmNetworkException` with the original cause, `attempts == maxAttempts`, and a toString naming the attempt count | FR-005 | unit | PLANNED | T2 |
| U2  | HTTP exhaustion → `LlmHttpException` with `attempts == maxAttempts`, exhaustion named in toString, status/body intact | FR-005 | unit | PLANNED | T3 |
| U3  | `Retry-After: 7200` with `maxDelayMs: 250` → sleep exactly 7200000 ms (no fixed ceiling; not bounded by the cap) | FR-003 | unit | PLANNED | T5 |

### Pins (existing behavior, previously unguarded)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | One network error then 200 → recovers with one backoff delay `[100]` | FR-001, FR-004 | pin | PLANNED | T1 |
| U5  | `Retry-After: 90` with `maxDelayMs: 250` → 90000 ms (directive beats the cap) | FR-003 | pin | PLANNED | T6 |
| U6  | Negative `Retry-After: -5` → treated as 0 (immediate retry, `[0]`) | FR-003 | pin | PLANNED | T7 |
| U7  | `openStreamWithRetry`: 429 + `Retry-After: 3` then 200 → sleep `[3000]`, stream opens | FR-007 | pin | PLANNED | T8 |
| U8  | Determinism: same script + same jitter run twice → identical sleep sequences | FR-006 | pin | PLANNED | T9 |

> **Pin honesty**: U4–U8 pin behavior that ships on master (the spec-007
> core) but was untested on the network/stream/determinism axes; U5's
> small-value case complements spec-007's U9 (7s). The genuinely new
> behavior — the unclamped ceiling, attempt annotation, terminal network
> typing — is RED-first (U1–U3).

## Edge cases & invariants

- Retry-After larger than maxDelayMs by 2+ orders of magnitude (7200 vs
  250) — the exact-unclamped case.
- The final HTTP error keeps statusCode/body/headers (operators still see
  the server's answer).
- The terminal network exception keeps the original `cause` object.
- `attempts` defaults to 1 outside the retry loop (single-shot provider
  clients unchanged — compile-compat).

## Out of scope

- HTTP-date-form Retry-After (seconds form is the contract).
- Mid-stream restart policy (spec 008), fallback chain (053), circuit
  breaker (035).
- Jitter strategy changes (the injectable seam stays as spec 007 built it).
- Spec-007's own U4–U9 tests (kept unmodified as the regression guard).

## Verification commands

```bash
dart analyze
dart test test/llm/retry_084_test.dart
dart test test/llm/retry_test.dart
dart test
```
