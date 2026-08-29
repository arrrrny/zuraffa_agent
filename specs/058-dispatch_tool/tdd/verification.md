---
feature: 058-dispatch_tool
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #5 §R5.4 (issue #6 US4)
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ b9ba15c
---

# TDD Verification: DispatchTool built-in (spec 058)

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

No `HIGH` smells. U4 (`dispatch_tool_provider_test.dart:32`) asserts
`toolName == 'dispatch'`, `riskTier == 'safe'`, and `subAgentSpecId` non-empty —
all concrete value checks (including the security-relevant `riskTier`). U5 returns
the injected tool by identity. The suite is clean for this spec.

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| —   | —        | None    | —        |

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on the security-relevant
default (`riskTier: 'safe'` -> `'unsafe'`), the only asserted constant in U4 beyond
`toolName`.

| Mutant                                          | Behavior | Survived | Judgment                                     |
| ----------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `dispatch_tool_provider.dart:25` `riskTier:'safe'` -> `'unsafe'` | U4 | No | Caught by U4; default riskTier is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#5 §R5.4. All six behaviors trace to that epic and exercise the real entry points.

Untested criteria: none. Tests tracing to nothing: none.

## What was not audited

- Engine-side sub-agent spawn orchestration (epic #5 §R5.4) — out of scope.
- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object.
