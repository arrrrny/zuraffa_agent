---
feature: 052-provider_config
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 5
proven: 0
likely: 0
test_after: 5
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #4 §R4.1 (issue #5 US1)
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ fec7889
---

# TDD Verification: ProviderConfig (typed openai/anthropic/gemini) (spec 052)

**Verdict: FAIL.** All five behaviors are `TEST_AFTER`: the provider was merged
before the test list was written and no RED cycle exists. The regression tests are
real and assert concrete values (`id`, `providerKind`, `models`); the failure is
discipline, not test quality.

## Test-first evidence

`tdd/cycle-log.md` holds only a Baseline block (suite green at `fec7889`) with no
`red` entry. The test list states the plan is test-after. History ordering was not
relied on because the list itself admits the code landed first.

| Behavior | Class      | Evidence                                                        |
| -------- | ---------- | --------------------------------------------------------------- |
| U1       | TEST_AFTER | No red logged; equality regression test over merged code        |
| U2       | TEST_AFTER | No red logged; inequality regression test over merged code      |
| U3       | TEST_AFTER | No red logged; `isA` seam test added after code                |
| U4       | TEST_AFTER | No red logged; `current()` value-return test added after code  |
| U5       | TEST_AFTER | No red logged; `count()` test added after code                 |

## Findings

No `HIGH` smells. U4 (`provider_config_provider_test.dart:31`) asserts
`config.id == 'kilo'`, `providerKind == 'openai'`, and `models` contains
`'tencent/hy3:free'` — concrete value checks, not double echoes. The U3 `isA`
check verifies the clean-arch interface seam (legitimate, not a framework-under-test
smell).

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| —   | —        | None    | —        |

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on the most behavior-bearing
contract (`current()` returning the constructed default config).

| Mutant                                          | Behavior | Survived | Judgment                                     |
| ----------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `provider_config_provider.dart:21` `id:'kilo'` -> `'kiloX'` | U4 | No | Caught by U4; default id is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#4 §R4.1. All five behaviors trace to that epic and are exercised at the real
provider/value-object entry points.

Untested criteria: none. Tests tracing to nothing: none — every test in
`provider_config_provider_test.dart` is in the list.

## What was not audited

- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run end to end; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object.
- Provider-specific subclasses (openai/anthropic/gemini) named in the spec but not
  shipped: out of scope, no test expected.
