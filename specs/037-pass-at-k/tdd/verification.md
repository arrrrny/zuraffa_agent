---
feature: 037-pass-at-k
verdict: PASS
verified_at: 627d7c2
behaviors_total: 13
behaviors_done: 13
test_first: 4 PROVEN (U1..U4, compile + stub-signal reds in cycle log), 1 pinned (U5, mutant-killed), 3 baseline (U6..U8 pre-existing)
mutation: 3/3 killed (MUTANT-C estimator ratio, M3 count inversion, M4 strict-inequality)
criteria_covered: 5/5 acceptance criteria, 5/5 FRs
suite: 716 passed, 0 failed
analyze: 5 pre-existing issues, 0 new
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
---

# TDD Verification: PassAtK unbiased estimator (eval-run + threshold slice)

## Verdict

**PASS WITH DISCLOSED INCIDENT** — `fromResults` (eval-run sampling semantics)
and `meetsThreshold` (inclusive threshold decisions) are traced to red-first
tests whose failure evidence is recorded verbatim; the k-monotonicity invariant
is pinned and mutant-proven; the 13 pre-existing estimator/clean-arch tests
pass unchanged; the full suite is green at 716 with zero new analyzer findings.
One process misfire (a red-suite commit caused by a pipe-masked exit code plus a
miscounted fixture) was disclosed, postmortemed in-commit per constitution IV,
and remediated before this audit; the incident is part of the record, not
something this verdict hides.

Independence note: same-session audit (no fresh-context subagent available);
findings re-derived from the files as they stand.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | U1..U4 | cycle-log cycles 1-2: compile reds (`Member not found: 'PassAtK.fromResults'`, `The method 'meetsThreshold' isn't defined`) followed by stub-driven `UnimplementedError` reds, all before implementation; commits `e8b6e9a`, `8e0580a` |
| PINNED (brownfield) | U5 | pass-first sweep pin (`627d7c2`) with MUTANT-C kill evidence; the pin's own first-run failure (certainty boundary at k=n-c vs n-c+1) was a fixture math error, fixed before the mutant runs |
| BASELINE (pre-existing) | U6, U7, U8 | 13 provider-suite tests green in every full-suite run; file byte-identical to `57412fe` |

Changes to pre-existing tests: NONE.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| MUTANT-C | estimator product ratio inverted (`(n-i)/(n-c-i)`) | U5 pin | KILLED — `pass@k decreased from k=1 to k=2` |
| M3 | `fromResults` counts falses (`!passed`) | U1 | KILLED — `Expected: <6> / Actual: <4>` |
| M4 | `meetsThreshold` `>=` -> `>` | U3 equality case | KILLED — `Expected: true` |

All mutants applied alone, restored exactly (`git diff --stat lib/` = 0), file
re-run green after each restore.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 fromResults equals compute | A1 (U1; M3 killed) | PROVED |
| AC US1-2 fromResults input errors + order independence | A2 (U2) | PROVED |
| AC US2-1 inclusive threshold boundary | A3 (U3; M4 killed) | PROVED |
| AC US2-2 threshold range/NaN errors | A4 (U4) | PROVED |
| AC US3-1 k-monotonicity sweep | A5 (U5; MUTANT-C killed) | PROVED |

FR-001..FR-005 traced (FR-004/005 by the untouched green provider tests);
SC-001..SC-005 proved — SC-005 via the final gates below.

## Final gates

- `dart test` -> **716 passed, 0 failed** (`All tests passed!`, pipefail-gated)
- `dart analyze` -> 5 issues, all pre-existing and unrelated. Zero new issues.

## Findings

- **MEDIUM (process, remediated)** — misfire #3: commit `e8b6e9a` landed while
  U1 was red (pipe-masked exit code + miscounted fixture; false green claim in
  the message). Postmortem + fixture precondition + pipefail gate discipline
  committed in `ffeb0b6`; every subsequent commit in this feature was gated on
  literal `All tests passed!` output.
- **LOW** — test-after exposure on green commits (test+impl in one commit per
  cycle, playbook cadence): cold git history alone would grade LIKELY; the
  cycle log's verbatim reds are the evidence class.
- **INFO** — threshold equality for a double metric is only meaningfully tested
  against the derived value (`t = result.value`); decimal literals are not
  bit-exact. Recorded in the test comment and cycle log for future gate
  authors.
- **INFO** — the U5 pin's first-run failure was the pin's own math error
  (certainty at k = n-c vs n-c+1), caught by running the pin, not by review;
  the estimator was never wrong. Evidence that pass-first pins still earn
  their keep as executable specs.

No HIGH findings on the deliverable. No criteria without tests. No tests
tracing to nothing.
