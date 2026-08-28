---
feature: 033-steering-queue
verdict: PASS
verified_at: cd6c12b
behaviors_total: 16
behaviors_done: 16
test_first: 15 PROVEN (compile-level red), 1 NOT_APPLICABLE (U7 baseline)
mutation: 4/4 killed (enqueue stamp, pop count, defensive copy, FIFO order)
criteria_covered: 9/9 acceptance criteria, 6/6 FRs
suite: 626 passed, 0 failed
analyze: 0 issues (No issues found, --fatal-infos)
---

# TDD Verification: SteeringQueue + SteeringMessage — enqueue/dispatch/inject semantics

## Verdict

**PASS** — the enqueue transition (FIFO append + `lastInjectedAt` stamp),
the pop dispatch transition (`({message, queue})` record, `processedCount`
increment, `StateError` on empty), the defensive-immutability hardening
(`List.unmodifiable`), and the persistence contract on both value objects
are traced to passing tests through the queue's public API; the change
landed test-first with compile-level red evidence (the entire refined
surface was absent from the scaffold); all four deliberate mutants were
killed; the nine pre-existing provider/compile-parity tests pass
unchanged.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | A1..A9 + U1..U6 | test-only commit `7652487` precedes the implementation commit `cd6c12b`; red recorded as compile errors (`The method 'enqueue'/'pop'/'toJson'/'fromJson' isn't defined for the type 'SteeringQueue'/'SteeringMessage'` — 17 error sites, loading failure) |
| NOT_APPLICABLE | U7 (9 pre-existing provider/compile-parity tests) | green against untouched layers (FR-005, FR-006) |

Honest granularity note: the three planned behavior groups share one
test-first commit because the test file does not compile until the
surface exists. Recorded in the cycle log.

Changes to pre-existing tests: NONE — verified in the green run and again
after every mutant restore.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 enqueue drops the lastInjectedAt stamp | `message.injectedAt` → `lastInjectedAt` | A1 | KILLED — `Expected: 09:00:00.000Z, Actual: null` |
| M2 pop drops the processedCount increment | `processedCount + 1` → `processedCount` | A4 | KILLED — `Expected: <4>, Actual: <3>` |
| M3 constructor stores the caller's reference (scaffold behavior) | `List.unmodifiable(pending)` → `pending` | U1 | KILLED — smuggled source-list mutation leaked in, `Expected: <1>, Actual: <2>` |
| M4 pop drains LIFO (last instead of first) | `pending.first` → `pending.last` | A4 | KILLED — `Expected: m-1 'first', Actual: m-2 'second'` |

Every mutant was restored exactly (`git diff --stat lib/` = 0) and the
affected file re-run green (+15 passed).

Audit note (recorded in the cycle log): the first M2 run was initially
misread as a survivor — `dart test -n "<full name containing '+'>"`
matched nothing because `+` is a regex quantifier, and the runner exits 0
with "No tests ran." (the exact trap the stack profile warns about).
Re-run with a regex-safe filter: mutant properly KILLED. The lesson
(already in the profile) is re-validated by evidence: read the matched
count, never the exit code.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 empty-queue enqueue shape | A1 (+M1 killed) | PROVED |
| AC US1-2 FIFO append, head stays first | A2 | PROVED |
| AC US1-3 source unchanged (no state lost) | A3, U4 | PROVED |
| AC US2-1 pop head + drained queue + count | A4, U3 (+M2 killed) | PROVED |
| AC US2-2 empty pop → StateError with queue id | A5 | PROVED |
| AC US2-3 double-pop FIFO drain | A6 (+M4 killed) | PROVED |
| AC US3-1 populated queue round-trip incl. order | A7 | PROVED |
| AC US3-2 empty queue omits lastInjectedAt | A8 | PROVED |
| AC US3-3 message round-trip | A9 | PROVED |

FR-001..FR-006 traced (FR-001 by U1/U2 + M3 killed; FR-005/FR-006 by the
untouched green provider tests); SC-001..SC-007 proved (SC-007 via final
gates below). The defensive-copy behaviors (U1/U2) are the ones whose
absence the scaffold silently tolerated — M3 demonstrates the test
catches the scaffold's own hole.

## Final gates

- `dart analyze --fatal-infos` — No issues found (0; zero new).
- `dart test` — 626 passed, 0 failed (post-032 baseline 611 + 15 new).
- Constitution VII — no `dart:io` in the new/changed files; IX —
  hand-curated plain-Dart exception documented in both file headers,
  unchanged by the refinement.

## Remediation

- T015: when the engine-loop spec (002) wires steering, port the pop
  contract: one `SteeringInjected` event per popped message, content and
  injectedAt taken from the popped `SteeringMessage` (out of scope here —
  FR-003 boundary).
- T016: when a between-turns store spec lands, consume
  `SteeringQueue.toJson`/`fromJson` rather than hand-rolling queue
  serialization.
