---
feature: 055-sub_agent_context
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #5 §R5.1 (issue #6 US1)
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ b9ba15c
---

# TDD Verification: SubAgentContext isolated context (spec 055)

**Verdict: FAIL.** All six behaviors are `TEST_AFTER`: the provider was merged
before the test list existed and no RED cycle was recorded.

## Test-first evidence

`tdd/cycle-log.md` has only a Baseline block (green at `b9ba15c`), no `red`.
Test list is explicitly test-after. History ordering not relied upon.

| Behavior | Class      | Evidence                                                          |
| -------- | ---------- | ----------------------------------------------------------------- |
| U1       | TEST_AFTER | No red logged; equality regression test over merged code          |
| U2       | TEST_AFTER | No red logged; inequality regression test over merged code        |
| U3       | TEST_AFTER | No red logged; `isA` seam test added after code                  |
| U4       | TEST_AFTER | No red logged; `current()` value-return test added after code    |
| U5       | TEST_AFTER | No red logged; injected-value test added after code             |
| U6       | TEST_AFTER | No red logged; `count()` test added after code                  |

## Findings

No `HIGH` smells. One `MED` weakness in U4:

| #   | Severity | Finding                                                                                              | Evidence                                  |
| --- | -------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| 1   | MED      | U4 asserts `budgetTurns` with `greaterThan(0)`. The default is `10`; any positive value passes, so a regression to a wrong-but-positive budget would slip through. Pin the documented default `10` with exact equality. | `sub_agent_context_provider_test.dart:38` |

The test still pins `id == 'ctx-default'`, `sessionId == 'session-default'`, and
`toolAllowlist` empty, so it is not vacuous overall.

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on `current()` returning the
constructed default context.

| Mutant                                              | Behavior | Survived | Judgment                                     |
| --------------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `sub_agent_context_provider.dart:24` `id:'ctx-default'` -> `'ctx-defaultX'` | U4 | No | Caught by U4; default id is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#5 §R5.1. All six behaviors trace to that epic and exercise the real
provider/value-object entry points. U5 returns the injected instance by identity
(`expect(..., active)`), a strong equality check.

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Engine-side enforcement of the isolated context (epic #5 §R5.1 orchestration) — out of scope.
- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object.
