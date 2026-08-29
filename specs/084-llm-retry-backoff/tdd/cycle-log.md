# TDD Cycle Log: LLM Client Retry & Backoff (spec 084)

Append-only record of the red-green-refactor cycles. RED evidence quoted
verbatim from the failing runs.

## Cycle 1 — unclamped Retry-After + attempt-annotated final errors (U1–U3)

**Scope**: delete the 3600s ceiling, propagate `attempts` at both
exhaustion throw sites, terminal network typing. Tests T1–T9 written
FIRST, in full, before any production edit.

### RED

Step 1 — the test file alone (production untouched):

```
$ dart test test/llm/retry_084_test.dart
test/llm/retry_084_test.dart:83:22: Error: The getter 'attempts' isn't
  defined for the type 'LlmNetworkException'.
test/llm/retry_084_test.dart:112:30: Error: The getter 'attempts' isn't
  defined for the type 'LlmHttpException'.
```

Step 2 — `attempts` fields added to both exception types (defaulted to 1),
retry loop NOT yet propagating, ceiling NOT yet removed:

```
$ dart test test/llm/retry_084_test.dart
00:00 +5 -3: Some tests failed.

Failing tests:
  ... T2: network exhaustion → terminal typed error with attempts
  ... T3: HTTP exhaustion → LlmHttpException with attempts
  ... T5: Retry-After: 7200 with maxDelayMs: 250 → sleep exactly 7200000
```

3 failing (the new behaviors), 6 passing (the pins T1/T6/T7/T8/T9).

Test-bug note (honesty): the first run of this stage also failed T9 with
`Expected: [133, 233, 250, 250]` — an arithmetic error in the test's own
literal (attempt 2 is 200+66=266, which the cap reduces to 250). The
expectation was corrected to `[133, 250, 250, 250]` BEFORE any production
edit; T9 then passed against unmodified master behavior, as a pin should.

### GREEN

Delete `if (seconds > 3600) return 3600000;`, pass `attempts: attempt` at
both HTTP throw sites, replace the network `rethrow` with a terminal
`LlmNetworkException(provider, cause: e.cause, attempts: attempt)`:

```
$ dart test test/llm/retry_084_test.dart
00:00 +8: All tests passed!
$ dart test test/llm/retry_test.dart    # spec-007 suite, UNMODIFIED
00:00 +6: All tests passed!
$ dart test test/llm/                    # whole llm directory
00:02 +105: All tests passed!
```

### REFACTOR

Reviewed; the two functions remain parallel by design (the 007 file's
structure). Doc comments tie the new fields to FR-005. No behavior change
beyond the spec'd deltas.

## Cycle 2 — pins (U4–U8)

T1 (network recovery), T6 (90s directive over cap), T7 (negative → 0),
T8 (stream parity), T9 (cross-run determinism) pin behavior that ships on
master unguarded; they pass by design and are justified by the mutation
kills below (M4 guards the directive handling; the determinism pin guards
the clock seam).

## Mutations (deliberate, one at a time, cp-restored)

| id  | mutant | result | evidence |
| --- | ------ | ------ | -------- |
| M1  | 3600s ceiling reinstated in `_retryAfterMs` | KILLED by T5 | sleep 3600000 ≠ 7200000 → `[E]` |
| M2  | HTTP exhaustion throw drops `attempts` | KILLED by T3 | attempts stayed 1 → `[E]` |
| M3  | network exhaustion reverts to bare `rethrow` | KILLED by T2 | attempts missing on the terminal error → `[E]` |
| M4  | sleep expression ignores Retry-After (always `_delayFor`) | KILLED by T5 + T6 + T7 | 3 failures — directive handling gone |

After each restore the target file returned to 8/8 green.

## Gates

```
$ dart analyze            # 3 issues — identical to master baseline (out of scope)
$ dart test               # 00:40 +1081 ~2: All tests passed!
```

Baseline at master `29b7fef` was 1073 passed / 2 skipped; +8 new tests
(the spec-007 retry suite passes unmodified).
