---
feature: 011-artifact-provider-noparams-list
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: a1fb738 # short SHA audited
behaviors: 8
proven: 0
likely: 0
test_after: 8
no_test: 0
high_smells: 0
criteria_total: 4
criteria_covered: 4
mutation_score: 100 # deliberate-mutant sampling: 2/2 killed (stub-returns-value; drop-NoParams = the exact issue-#11 shape, killed at compile time)
mutants_survived: 0
suite: 379 passed, 8 failed (all 8 pre-date the feature on master: unrelated loading failures), 13s
---

# TDD Verification: ArtifactProvider.list NoParams override fix

**Verdict: FAIL** — by the strict test-first rubric, and honestly so: the
implementation landed via PR #32 (squash `861362d`) together with its tests
BEFORE this spec cycle existed (the spec draft post-dates the merged fix),
so no behavior can show a genuine red. What this cycle adds is real but
different: the build is unblocked off-machine (pubspec duplicate-key fix),
all four acceptance criteria are re-proven against the current tree, and
the contract is mutation-hardened — including re-introducing the exact
issue-#11 bug shape and watching the compiler catch it.

## Test-first evidence

| Behavior | Class      | Evidence |
| -------- | ---------- | -------- |
| U1-U5    | TEST_AFTER | impl + tests squashed together in `861362d` (PR #32); green re-run this cycle (+5) |
| A1       | TEST_AFTER | analyze gate re-run this cycle: pair → No issues found |
| A2       | TEST_AFTER | contract suite green re-run |
| A3       | TEST_AFTER | full suite +379/-8 = master baseline exactly; analyze 162 = baseline |

## Findings

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | MED | Zero test-first evidence is possible: code merged before the spec cycle ran (spec draft dated after PR #32) | git history: single squash commit for impl+tests |
| 2 | LOW | The draft's SC-002 counts (129 pre-existing tests) describe the tree at draft time; re-anchored to the current master baseline (+379/-8) in the refined spec | spec.md Status note |

## Mutation testing summary

| Mutant | Applied to | Result |
| ------ | ---------- | ------ |
| `list` stub returns `<ArtifactRef>[]` instead of throwing | provider stub body | KILLED (+4 -1) |
| drop `NoParams params` from `list` override (the #11 bug shape) | provider parameter list | KILLED at compile time (`invalid_override`) |

## Gates

- `dart analyze` — 162 issues, all pre-existing master baseline; pair files:
  zero issues.
- `dart test` — +379 / -8, exactly the master baseline; zero new failures.
- Constitution VII — no `dart:io` in the pair. FR-006 headers with issue
  #11 links verified present on both files.

## Remediation

- T001: none possible for this spec retroactively; the lesson is process,
  not code — future zfa-bug fixes (issues #12, #25, #27, #29 …) should run
  the spec cycle BEFORE the fix lands so the reds are genuine. The
  clone-template path (US2/AC-4) is unblocked by this cycle's artifacts.
