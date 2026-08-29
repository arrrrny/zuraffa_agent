---
feature: 013-event-bus
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 4
proven: 3
likely: 0
test_after: 1
no_test: 0
high_smells: 1
criteria_total: 5 # FR-001..FR-005 (4 numbered acceptance scenarios map onto FR-001..FR-004)
criteria_covered: 4
mutation_score: null # no mutation tool in the lockfile (profile: mutation = null)
mutants_survived: 0 # was 1 (M1 in A3); CLEARED 2026-08-29 — A3 now pins the caller's args round-trip
suite: 1072 passed, 2 skipped, 0 failed, 81s (`dart test`)
---

# TDD Verification: Event Bus

**Verdict: FAIL.** A deliberate mutant that makes `EventBus.request` discard the
caller's event entirely survives behavior A3 — the A3 test asserts a field
(`BeforeToolCallResponse.approved`) that defaults to `true`, so it proves the
handler's response was *used* only in the weak sense that something of the right
type came back. A2 additionally lands as `TEST_AFTER`: its source (`emit`'s
subscriber loop) shipped one commit before the test that claims it.

## Test-first evidence

Cycle log: `specs/013-event-bus/tdd/cycle-log.md`. Note that the commit SHAs the
cycle log records (`1a737f1`, `7155247`, `bbac0ce`, `3dd8459`) are **not** in
`HEAD`'s history; the equivalent commits that are ancestors of `01618f3` are
`ae151c1`, `ed3e757`, `5cf6314`, `7fa7e82` (same messages, same stats), so the
branch was rebased after the log was written. Ordering was corroborated against
those.

| Behavior | Class      | Evidence                                                                                                                                                   |
| -------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A1       | PROVEN     | cycle 1 red recorded with output (`Expected: ['hello', 'world'] Actual: []`); `ae151c1` adds `test/events/event_bus_test.dart` and `lib/src/events/event_bus.dart` together |
| A2       | TEST_AFTER | cycle 2 records **no natural red** — the log states the test "passed on first run"; the red is a self-administered mutant. `emit`'s loop landed in `ae151c1`, the A2 test only in `ed3e757` (test-only commit, source unchanged) |
| A3       | PROVEN     | cycle 3 red recorded (`Bad state: request/response not yet implemented`); `5cf6314` adds test + `_handlers`/`registerHandler`/`request` together            |
| A4       | PROVEN     | cycle 4 red recorded (`Expected: ['hi'] Actual: []`); `7fa7e82` adds test + `AgentController.publish`/`listen` together                                     |

No pre-existing test was weakened, renamed, or skipped by these commits: every
diff to `test/events/event_bus_test.dart` is pure addition (15/10/11/8 inserted
lines, 0 deletions).

## Findings

| #   | Severity | Finding                                                                                                                                                                                                                                                   | Evidence                                                                          |
| --- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 1   | CLEARED  | **[CLEARED 2026-08-29] Vacuous assertion on the request/response behavior.** A3 asserted only `resp.approved`, which `BeforeToolCallResponse` defaults to `true` (`lib/src/events/event_bus.dart:19`). The handler's actual contribution — the merged `{...req.args, 'approved': true}` map — is never asserted, so the test passes for any `BeforeToolCallResponse` the bus returns. Confirmed by surviving mutant M1. Should assert `resp.args` equals `{'url': 'x', 'approved': true}` (proving the caller's payload reached the handler and the handler's value came back) and construct the response with `approved: false` in a second case so the flag is not free. | `test/events/event_bus_test.dart:33`                                              |
| 2   | HIGH     | **A2 is `TEST_AFTER`.** FR-003 (synchronous delivery in registration order) is pinned by a test written after the code that satisfies it; the cycle log substitutes a self-administered mutant for the red step. The behavior is genuinely guarded today (mutant M2 is caught), but the discipline evidence is absent. Re-classify A2 in `test-list.md` or record it honestly as characterization. | `specs/013-event-bus/tdd/cycle-log.md:22-32`; `test/events/event_bus_test.dart:15` |
| 3   | MED      | **Cycle-log commit SHAs are unresolvable.** All four recorded SHAs are absent from `HEAD`'s history (rebase). Evidence pointers in the log cannot be followed without guessing at the replacement commits.                                                   | `specs/013-event-bus/tdd/cycle-log.md:20,32,44,55`                                |
| 4   | MED      | **FR-005 has no test.** "The engine MUST emit lifecycle events through the bus" is declared out of scope (depends on spec 002) but is still an unsatisfied functional requirement of this spec. Nothing in `lib/` wires the bus into the engine loop.        | `specs/013-event-bus/spec.md:58`; `test-list.md:58`                               |
| 5   | MED      | **Foreign style: no header traceability block.** Every sibling test file in this repo opens with a `// Spec NNN — ... / Traces: tdd/test-list.md ...` header (see `test/data/providers/planner/planner_provider_test.dart:1-19`, `test/data/repositories/stop_policy_repository_impl_test.dart:1-5`). This file starts straight at the imports. | `test/events/event_bus_test.dart:1`                                               |
| 6   | LOW      | **`AgentController` request/response surface is untested here.** `AgentController.request`/`on`/`bus` (`lib/src/events/event_bus.dart:75-93`) are covered by spec 078's `test/events/request_response_test.dart`, not by any 013 behavior; the 013 list claims A4 covers "identical to EventBus" but only exercises `publish`/`listen`. | `test/events/event_bus_test.dart:36`                                              |

## Mutation results

No mutation tool exists in this repository (`.specify/memory/tdd-profile.md`:
`mutation: null`), so deliberate mutants were used. **4 of 4 behaviors sampled**
(A1 via A4's controller path, A2, A3, A4). Each mutant was applied, the behavior's
test run, then the file restored byte-for-byte (`git diff --quiet` verified) and
the five audited test files re-run green (54 passed).

| Mutant                                                                                                                | Behavior | Survived | Judgment                                                                                                    |
| --------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| M1 `lib/src/events/event_bus.dart:60` — `handlers.last(event)` → `handlers.last(BeforeToolCallRequest('', {}))` (request discards the caller's event) | A3       | **No (cleared 2026-08-29)** | Was a survivor: the emitter's payload was silently dropped and A3 still passed. CLEARED — A3 now asserts `resp.args == {'url': 'x', 'approved': true}` plus a `denied.approved == false` case; mutant M1 re-applied → A3 fails (expected), source restored → green. Source `request` was already correct (`handlers.last(event)`); the assertion was the gap. |
| M2 `lib/src/events/event_bus.dart:40` — `[...subs]` → `[...subs].reversed`                                             | A2       | No       | Caught: `Expected: ['s1:x','s2:x','s3:x'] Actual: ['s3:x','s2:x','s1:x']`. Registration order is pinned.    |
| M3 `lib/src/events/event_bus.dart:79` — `publish<T>` body emptied                                                      | A4       | No       | Caught: `Expected: ['hi'] Actual: []`. The controller delegation is pinned.                                 |

## Traceability

| Criterion            | Tests                                     | End to end |
| -------------------- | ----------------------------------------- | ---------- |
| FR-001 (typed pub/sub)   | A1, A2 (`event_bus_test.dart:6,15`)   | Yes — real `EventBus`, no doubles |
| FR-002 (request/response) | A3 (`event_bus_test.dart:25`)        | Weak — real bus, but the assertion does not pin the response content (finding #1) |
| FR-003 (sync, in registration order) | A2 (`event_bus_test.dart:15`) | Yes, but `TEST_AFTER` |
| FR-004 (AgentController wrapper) | A4 (`event_bus_test.dart:36`)   | Partial — `publish`/`listen` only, not `request`/`on`/`bus` |
| FR-005 (engine emits through the bus) | **none**             | No |

Untested criteria: FR-005. Tests tracing to nothing: none — all four tests in
`test/events/event_bus_test.dart` map to A1–A4.

`tasks.md` cross-check: `[A1]`–`[A4]` are all ticked `[x]` and all four are `DONE`
in `test-list.md`. No ticked task points at a non-`DONE` behavior.

## What was not audited

- **Coverage was not collected.** No `--coverage` run was made for
  `lib/src/events/event_bus.dart`, so uncovered-branch corroboration is absent.
- **`test/events/request_response_test.dart`** (spec 078) was not graded: it
  belongs to spec 078's own verification, even though it exercises the same file.
- **FR-005 / engine wiring** was not assessed beyond confirming no test exists;
  the spec-002 engine event stream is a separate feature.
- **Concurrency and re-entrancy**: `emit` copies the subscriber list so a handler
  may (un)subscribe mid-dispatch (`event_bus.dart:40`). No behavior claims this
  and no test exercises it; not assessed.
- **Performance / event-volume behavior**: no criterion, no test, not assessed.
