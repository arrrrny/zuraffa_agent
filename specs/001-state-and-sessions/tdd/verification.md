---
feature: 001-state-and-sessions
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 14
proven: 0
likely: 0
test_after: 12
no_test: 2
high_smells: 3
criteria_total: 10
criteria_covered: 8 # US2-AC4 Hive side partial; US4-AC1/AC2 untested
mutation_score: 100 # scope: 2 highest-risk behaviors sampled (U8,U11), 0 survived
mutants_survived: 0 # both deliberate mutants killed
suite: 909 passed, 2 skipped (baseline; full re-run not performed — targeted mutant tests re-run green)
---

# TDD Verification: State & Sessions (spec 001)

**Verdict: FAIL.** The feature is a pure-Dart library merged before any TDD loop ran
here: the test-list is an explicit *test-after* plan, the cycle log records no red,
and git history shows source+tests landed in one squashed commit (`12b9032`). Every
unit behavior (U1–U12) is therefore `TEST_AFTER`, and the two US4 acceptance criteria
(U13/U14) have **no dedicated test at all** — both are `NO_TEST` characterization
claims satisfied only by a green suite and code review. That alone fails the rubric
(any `TEST_AFTER` or `NO_TEST` behavior), and it is compounded by an untested
acceptance path (the Hive store, US2-AC4).

## Test-first evidence

| Behavior | Class      | Evidence                                                                              |
| -------- | ---------- | ------------------------------------------------------------------------------------- |
| U1–U12   | TEST_AFTER | test-list.md states "test-after plan … No RED cycles were driven"; cycle-log.md holds baseline only; `12b9032` adds source+tests together (squashed) |
| U13      | NO_TEST    | test-list.md: "no dedicated regression test file in repo"; verified by green suite + presence of `lib/src/skills.dart` |
| U14      | NO_TEST    | test-list.md: "no dedicated test"; verified by code review + green suite             |

## Findings

| #   | Severity | Finding                                                                                                                            | Evidence                                                  |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| 1   | HIGH     | US4-AC1 (pi_agent seed merged with attribution + passes the suite) has no dedicated test; covered only by the green suite and the existence of `lib/src/skills.dart`. Acceptance criterion untested. | `test-list.md` U13 / `tasks.md` T016–T018                 |
| 2   | HIGH     | US4-AC2 (no stub code ships) has no dedicated test; verified only by code review. Acceptance criterion untested (a regression could ship a stub and stay green). | `test-list.md` U14                                        |
| 3   | HIGH     | US2-AC4 Hive↔JSONL round-trip equivalence: `lib/src/hive_session_store.dart` exists but `test/hive_store_test.dart` does not — the Hive reload path is implemented yet untested, so "both stores yield identical branch structure" is unverified on the Hive side. | `test-list.md` "Invariants … still to place"; `grep` confirms store present, test absent |
| 4   | MED      | U4 fork test asserts only `heads.length >= 1` — it does not verify the AC content (shared ancestry entries 1..N with the original, clean divergence after N, both branches resumable). | `test/session_storage_test.dart:242`                       |
| 5   | MED      | U9 deleteBranch test asserts only `forkHead.isNotEmpty` — it does not verify refcount pruning of unreferenced entries while shared ancestry is retained (the AC content). | `test/session_storage_test.dart:267`                       |
| 6   | MED      | U11 findCutPoint test bounds the result only with `greaterThan(0)` / `lessThan(10)` — it does not pin the exact cut index, so a one-entry-off boundary error would not be caught. | `test/compaction_test.dart:166-168`                        |

No HIGH *smell* (tautology / doubled subject / assertion-free) was found in the test
files; the unit assertions in `types_test.dart`, `roundtrip_test.dart`,
`usage_ledger_test.dart`, `session_storage_test.dart` and `compaction_test.dart` are
real value checks. The HIGH findings are untested acceptance criteria, not weak tests.

## Mutation results

No mutation tool is available; deliberate mutants were run on the two highest-risk
behaviors (persistence / budget boundary). Each was restored exactly and the mutant
test re-run green before moving on.

| Mutant                                                        | Behavior | Survived | Judgment                              |
| ------------------------------------------------------------- | -------- | -------- | ------------------------------------- |
| `jsonl_session_storage.dart` dropped the tear-report assignment (kept `break`) | U8       | No       | `corrupt-tail tear recovery` failed (`Expected: not null Actual: <null>` at `:163`); restored via `git checkout` |
| `compaction.dart` inverted `>` to `<` in `shouldCompact`      | U11      | No       | `returns true when above threshold` failed (`Actual: <false>` at `:97`); restored via `git checkout` |

Scope: 2 of 14 behaviors sampled (the only ones with no mutant evidence in the repo).

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| US1-AC1   | U1,U2,U3,U12 | Yes (unit) |
| US1-AC2   | U3    | Yes (unit) |
| US2-AC1   | U4    | Yes (unit) |
| US2-AC2   | U5    | Yes (unit) |
| US2-AC3   | U6    | Yes (unit) |
| US2-AC4   | U7 (JSONL only) | Partial — Hive side untested (F3) |
| US3-AC1   | U10   | Yes (unit) |
| US3-AC2   | U11   | Yes (unit) |
| US4-AC1   | none (U13) | **No test** (F1) |
| US4-AC2   | none (U14) | **No test** (F2) |

Untested criteria: US4-AC1, US4-AC2 (no test at all); US2-AC4 Hive side (no test).
Tests tracing to nothing: none — every claimed test exists and runs.

## What was not audited

- The full 909-test suite was not re-run end to end; only the two mutant tests were
  executed (and re-run green after restore). The baseline green is taken from the
  cycle log.
- Inner-loop timing/ordering properties of compaction (e.g. "compaction only at turn
  boundaries, never mid-tool-batch", noted as an unplaced edge case) were not
  asserted by any unit test and were not exercised.
- `dart analyze` was not re-run; pre-existing baseline is assumed clean per the log.
