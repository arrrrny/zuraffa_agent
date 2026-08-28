---
feature: 032-agent-session-root
verdict: PASS
verified_at: 8b08456
behaviors_total: 15
behaviors_done: 15
test_first: 14 PROVEN (compile-level red), 1 NOT_APPLICABLE (U6 baseline)
mutation: 4/4 killed (updatedAt stamp, fork point, branch-link serialization, parse guard)
criteria_covered: 9/9 acceptance criteria, 6/6 FRs
suite: 611 passed, 0 failed
analyze: 0 issues (No issues found, --fatal-infos)
---

# TDD Verification: AgentSession root entity — aggregate transitions + persistence contract

## Verdict

**PASS** — the cursor transition (`appendEntry`), the branch transition
(`fork`), and the persistence contract (`toJson`/`fromJson`) are traced to
passing tests through the root entity's public API; the change landed
test-first with compile-level red evidence (the entire refined surface was
absent from the scaffold); all four deliberate mutants were killed; the
eight pre-existing provider/compile-parity tests pass unchanged.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | A1..A9 + U1..U5 | test-only commit `dbfa203` precedes the implementation commit `8b08456`; red recorded as compile errors (`The method 'appendEntry'/'fork'/'toJson'/'fromJson' isn't defined for the type 'AgentSession'` — 12 error sites, loading failure) |
| NOT_APPLICABLE | U6 (8 pre-existing provider/compile-parity tests) | green against untouched layers (FR-001, FR-005) |

Honest granularity note: the three planned behavior groups share one
test-first commit because the test file does not compile until the surface
exists; behavior-level reds were not individually staged. Recorded in the
cycle log.

Changes to pre-existing tests: NONE — verified in the green run and again
after every mutant restore.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 appendEntry drops the updatedAt stamp | `updatedAt: ts` → `updatedAt: updatedAt` | A1 | KILLED — `Expected: 2026-08-24 09:05:00.000Z, Actual: 09:00:00.000Z` |
| M2 fork ignores the current head | `currentEntryId ?? rootEntryId` → `rootEntryId` | A4 | KILLED — `Expected: 'entry-3', Actual: 'entry-root'` |
| M3 toJson omits parentSessionId | branch-link serialization line dropped | A7 | KILLED — round-trip lost `parentSessionId: sess-0` |
| M4 fromJson fabricates a default for missing required keys | throw → `return ''` | A9 | KILLED — `Expected: throws ArgumentError, Actual: Closure` |

Every mutant was restored exactly (`git diff --stat lib/` = 0) and the
affected file re-run green (+14 passed).

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 fresh-session cursor init + updatedAt stamp | A1 (+M1 killed) | PROVED |
| AC US1-2 headed-session cursor advance, isHead stays true | A2 | PROVED |
| AC US1-3 empty entry id rejected | A3 | PROVED |
| AC US2-1 fork linked at current head | A4, U3 (+M2 killed) | PROVED |
| AC US2-2 fresh-session fork falls back to root anchor | A5 | PROVED |
| AC US2-3 missionId inherited | A6 | PROVED |
| AC US3-1 full round-trip | A7 (+M3 killed) | PROVED |
| AC US3-2 absent optionals restored null | A8 | PROVED |
| AC US3-3 malformed JSON → ArgumentError | A9, U5 (+M4 killed) | PROVED |

FR-001..FR-006 traced (FR-001/FR-005 by the untouched green provider tests;
FR-006 immutability by U1/U2); SC-001..SC-006 proved (SC-006 via final
gates below). Immutability (U1/U2) is asserted as a first-class behavior,
not inferred from `final` fields — a future refactor to a mutable builder
would fail them.

## Final gates

- `dart analyze --fatal-infos` — No issues found (0; baseline 0 after
  9d8b5bd, zero new).
- `dart test` — 611 passed, 0 failed (baseline 597 + 14 new).
- Constitution VII — no `dart:io` in the new/changed files (pure value
  object); IX — hand-curated plain-Dart exception documented in the file
  header, unchanged by the refinement.

## Remediation

- T014: when the session-storage specs land, wire
  `AgentSessionProvider`/the JSONL/Hive stores to consume `toJson`/
  `fromJson` and retire any hand-rolled session-root serialization they
  carry (out of scope here — FR-005 boundary).
