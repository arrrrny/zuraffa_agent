---
feature: 057-yaml_agent_spec
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0 # spec.md has no numbered acceptance criteria; advances epic #5 §R5.3 (issue #6 US3)
criteria_covered: 0
mutation_score: n/a # deliberate mutants only (no tool in lockfile); 1 behavior sampled, 0 survived
mutants_survived: 0
suite: per-file re-run green after mutant restore; planning-time baseline 909 passed, 2 skipped @ b9ba15c
---

# TDD Verification: YamlAgentSpec declarative + extends (spec 057)

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

No `HIGH` smells. Two `MED` items:

| #   | Severity | Finding | Evidence |
| --- | -------- | ------- | -------- |
| 1   | MED      | The test file contains two `validate()` tests (`a spec referencing an unknown tool fails validation...`, `a spec with cyclic inheritance fails validation...`) that are NOT enumerated in `tdd/test-list.md` (which lists only U1–U6, 6 behaviors). They trace to "spec 005 A6" — a foreign spec id. The list undercounts the file's tests and these behaviors have no trace entry. Record them, or drop them, so the list is truthful. | `yaml_agent_spec_provider_test.dart:64` and `:81` |
| 2   | MED      | U4 asserts `spec.systemPrompt` with `isNotEmpty`. The default is a fixed string; any non-empty value passes, so a regression to a wrong-but-non-empty prompt would slip. Pin the literal default `'You are a helpful agent operating inside zuraffa.'`. | `yaml_agent_spec_provider_test.dart:39` |

Finding 1 is a traceability/doc gap (the tests are real and useful, just undocumented
in the list); finding 2 is a decay-risk weakness, not a `HIGH`.

## Mutation results

No mutation tool in the lockfile. One deliberate mutant on `current()` returning the
constructed default spec.

| Mutant                                          | Behavior | Survived | Judgment                                     |
| ----------------------------------------------- | -------- | -------- | -------------------------------------------- |
| `yaml_agent_spec_provider.dart:20` `id:'default'` -> `'defaultX'` | U4 | No | Caught by U4; default id is pinned |

Mutant applied, single test failed, file restored via `git checkout`, test re-ran
green. No mutant left in the tree.

## Traceability

No numbered acceptance criteria in `spec.md` (`spec_criteria: 0`); advances epic
#5 §R5.3. Behaviors U1–U6 trace to that epic. **Discrepancy:** the two `validate()`
tests (finding 1) trace to no in-list behavior and reference spec 005 A6, a different
feature. They are real behavior coverage that the list omits.

Untested criteria: none. Tests tracing to nothing: the 2 `validate()` tests
(documented above as finding 1).

## What was not audited

- YAML file parsing and `extends`-chain resolution (epic #5 §R5.3 loader) — out of scope.
- Git commit ordering not used as corroboration (list admits test-after).
- Full 909-test suite not re-run; only the sampled behavior's file.
- No acceptance / end-to-end loop for this `inside-out` value object.
