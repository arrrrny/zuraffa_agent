---
feature: 035-circuit-breaker
verdict: PASS
verified_at: 24372dc
behaviors_total: 15
behaviors_done: 15
test_first: 14 traced (10 PROVEN compile-red — shouldProbe + serialization; 4 characterization green-on-scaffold BY DESIGN — A4..A6 + their shared loading red), 1 NOT_APPLICABLE (U6 baseline)
mutation: 3/4 killed, 1 equivalent-by-design (M2 hidden-transition — unobservable on an immutable snapshot)
criteria_covered: 9/9 acceptance criteria, 6/6 FRs
suite: 654 passed, 0 failed
analyze: 0 issues (No issues found, --fatal-infos)
---

# TDD Verification: CircuitBreaker state machine — recovery readiness + persistence contract

## Verdict

**PASS** — the `shouldProbe` recovery-readiness read (inclusive boundary,
read-only, defensive null-openedAt guard), the persistence contract
(`toJson`/`fromJson` round-tripping every state exactly, cooldown
continuing across restore, mid-probe resume), and the full-cycle recovery
regression (fresh streak after recovery, fresh-threshold re-trip,
half-open failure re-trip with reset) are traced to passing tests through
the breaker's public API; shouldProbe and serialization landed test-first
with compile-level red evidence; three of four deliberate mutants were
killed, the fourth being equivalent-by-design (structural immutability
makes a hidden internal transition unobservable); the twelve pre-existing
provider/compile-parity tests pass unchanged.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | A1..A3, A7..A9, U1..U5 | test-only commit `9b8ed3d` precedes the implementation commit `24372dc`; red recorded as compile errors (`shouldProbe`/`toJson`/`fromJson` undefined — 23 error sites, loading failure) |
| CHARACTERIZATION | A4..A6 (full-cycle recovery) | green-on-scaffold BY DESIGN — composed from existing transitions, declared in the plan and test-list as a regression pin against future refactor leakage (e.g. failureCount surviving recovery); shared the file's loading red pre-implementation |
| NOT_APPLICABLE | U6 (12 pre-existing provider/compile-parity tests) | green against untouched layers and transitions (FR-001, FR-006) |

Honest granularity note: the behavior groups share one test-first commit
(the file does not compile until the surface exists). Pre-green fixture
repairs (three incomplete malformed-input JSON fixtures) were test-side
only — recorded in the cycle log.

Changes to pre-existing tests: NONE — verified in the green run and again
after every mutant restore.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 boundary flips to exclusive | `>=` → `>` in shouldProbe | A2 | KILLED — `Expected: true, Actual: <false>` at the exact boundary tick |
| M2 hidden transition in the read | shouldProbe internally calls tryHalfOpen | U2 | SURVIVED — **equivalent-by-design**: an immutable snapshot discards the internal transition's result; the caller's reference cannot be mutated, so the mutant is unobservable by construction. Read-only discipline is structural. Documented, not remediated |
| M3 cooldown restarts at restore | fromJson sets openedAt to parse time | A8 | KILLED — `Expected: true, Actual: <false>`: shouldProbe at the original boundary went false because the cooldown restarted |
| M4 unknown state defaults to closed | throw → silent `CircuitBreakerState.closed` | U3 | KILLED — `Expected: throws ArgumentError with name: 'state', Actual: Closure` |

Every mutant was restored exactly (`git diff --stat lib/` = 0) and the
affected file re-run green (+14 passed). M3's first application was
mis-specified (an `?? DateTime.now()` fallback that only affected the
null-openedAt path); the corrected unconditional reset was killed — both
attempts recorded in the cycle log.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 shouldProbe false in closed | A1 | PROVED |
| AC US1-2 boundary pinned on both sides | A2 (+M1 killed) | PROVED |
| AC US1-3 shouldProbe false in halfOpen | A3 | PROVED |
| AC US2-1 fresh streak after recovery | A4 | PROVED (characterization pin) |
| AC US2-2 fresh-threshold re-trip | A5 | PROVED (characterization pin) |
| AC US2-3 half-open failure re-trip + reset | A6 | PROVED (characterization pin) |
| AC US3-1 every state round-trips; cooldown continues | A7, A8 (+M3 killed) | PROVED |
| AC US3-2 mid-probe resume | A9 | PROVED |
| AC US3-3 malformed JSON fails typed | U3, U4, U5 (+M4 killed) | PROVED |

FR-001..FR-006 traced (FR-002 by A1..A3/U1/U2 + M1 killed; FR-003 by
A4..A6; FR-004/005 by A7..A9/U3..U5 + M3/M4 killed; FR-001/FR-006 by the
untouched green provider tests); SC-001..SC-006 proved (SC-006 via final
gates below).

## Final gates

- `dart analyze --fatal-infos` — No issues found (0; zero new).
- `dart test` — 654 passed, 0 failed (post-034 baseline 640 + 14 new).
- Constitution VII — no `dart:io` in the new/changed files; IX —
  hand-curated plain-Dart exception documented in the file header,
  unchanged by the refinement.

## Remediation

- T020: when the fallback-chain coordinator (spec 008/053 territory)
  consumes the breaker, drive it through shouldProbe → tryHalfOpen and
  persist chain state via toJson/fromJson across restarts.
- T021: escalating backoff (cooldown doubling per re-trip) is a
  deliberate non-goal here (the epic's "backoff" is read as the fixed
  cooldown); revisit only with an explicit spec change.
