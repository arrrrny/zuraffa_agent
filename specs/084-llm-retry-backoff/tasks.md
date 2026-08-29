# Tasks: LLM Client Retry & Backoff (spec 084)

**Input**: spec.md + plan.md under `specs/084-llm-retry-backoff/`

**Baseline**: master `29b7fef` — `dart test` 1073 passed / 2 skipped / 0
failed; `dart analyze` 3 pre-existing issues (all out of scope).

- [x] 1. RED — write `test/llm/retry_084_test.dart` (T1–T9: network-error
       recovery pin; network exhaustion with attempts + terminal typing;
       HTTP exhaustion with attempts + exhaustion-naming toString;
       unclamped Retry-After (7200s > any ceiling); Retry-After 90s over
       maxDelayMs pin; negative Retry-After → 0 pin; openStreamWithRetry
       Retry-After parity pin; cross-run determinism pin). First red is the
       compile failure on the missing `attempts` members, then failing
       assertions (T2/T3/T5) with the fields defaulted but not propagated.
       Evidence → `tdd/cycle-log.md`.
- [x] 2. GREEN — delete the 3600s Retry-After ceiling; propagate
       `attempts` at both exhaustion throw sites; network exhaustion
       throws a terminal `LlmNetworkException` (same type, original cause,
       attempts set). Target file 9/9.
- [x] 3. Pins — T1/T6/T7/T8/T9 verified against unmodified behavior; the
       pre-existing `test/llm/retry_test.dart` stays green UNMODIFIED.
- [x] 4. Mutations — M1 3600s ceiling reinstated; M2 HTTP attempts dropped;
       M3 bare rethrow restored; M4 Retry-After ignored in the sleep
       expression. One at a time, cp-restored, each must KILL.
- [x] 5. Gates — `dart analyze` (no new issues vs baseline), full `dart
       test` green (baseline 1073/2 + new).
- [x] 6. `tdd/verification.md` — evidence classification, FR table,
       mutation results verbatim, gates, verdict.
- [x] 7. Commit (artifacts + code together) and open PR base `master`
       (closes #95).
