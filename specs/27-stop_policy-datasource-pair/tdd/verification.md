---
feature: 27-stop_policy-datasource-pair
verdict: PASS
verified_at: 658a3d0
behaviors_total: 18
behaviors_done: 18
test_first: 16 PROVEN, 2 NOT_APPLICABLE (U4/U10 baselines)
mutation: 4/4 killed (deliberate hand-mutants, one after redirecting to the literal-assertion test)
criteria_covered: 6/6 acceptance criteria, 6/6 FRs
suite: 551 passed, 0 failed
analyze: 5 pre-existing issues, 0 new
---

# TDD Verification: StopPolicy datasource + mock pair

## Verdict

**PASS** — the full chain (datasource pair, repository seam, provider/service
consumption) is traced to passing tests, every behavioral change landed
test-first with recorded red evidence, one real design defect was caught by the
loop and corrected mid-cycle with the spec amended in the same commit, and all
four deliberate mutants were killed.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | U1..U3 (cycle 1), A3+U5..U7 (cycle 2), A6+U8..U9 (cycle 3), A1/A2/A4/A5+U11/U12 (cycle 4) | cycle-log red blocks + git ordering (test-only commits before implementation commits in every cycle) |
| NOT_APPLICABLE | U4, U10 (compile-parity characterizations) | green against pre-existing surface |

Red-phase failure modes recorded: compile errors (`Member not found:
'defaultPolicy'`, `The method 'update' isn't defined`, `No named parameter with
the name 'repository'`, missing file for `StopPolicyRepositoryImpl`) for missing
surface; assertion failures for behavior (cycle 4's `Bad state: No StopPolicy
stored for id "default" (stored: "strict")` — the decisive red that drove the
provider design correction).

Changes to pre-existing tests: 8 datasource tests and 5 provider tests
asserting `UnimplementedError` stubs (plus entity-surface assertions) were
superseded by behavior tests. Coverage check: the 5 entity-surface semantics
from the old datasource file (Duration field, int fields, enabled default,
five-field equality, Duration.zero wall-clock) are all retained in the new
entity test file (U1..U3) — no coverage regression. Intent documented in
spec.md Assumptions as drift remediation.

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 default drift | `defaultPolicy.maxTurns` 100 → 101 | A1 first, then U1 | A1 SURVIVED (tautology: both sides read the same mutated constant — see findings), U1 KILLED — `Expected: <100> Actual: <101>` (literal assertions) |
| M2 dropped guard | `getCurrent` returns stored policy without id check | A6 | KILLED — `Expected: throws <StateError>, Actual: <Future<StopPolicy>>` |
| M3 no-op update | mock `update` keeps old policy | A3/U6 | KILLED — `Expected: strict, Actual: default` |
| M4 seam bypass | provider `current()` returns the constant instead of reading the datasource | A2/A5 | KILLED — `Expected: strict, Actual: default` |

Every mutant was restored exactly (`git diff --stat lib/` = 0 lines) and the
affected files re-run green afterwards.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 default served by fresh chain | A1 (+U1 literal pin) | PROVED |
| AC US1-2 seeded policy served by current(NoParams) | A2 (+M4 killed) | PROVED |
| AC US2-1 update read-after-write | A3/U6 (+M3 killed) | PROVED |
| AC US2-2 reset restores default through chain | A4 | PROVED |
| AC US3-1 reads served by the datasource seam | A5 (+M4 killed) | PROVED |
| AC US3-2 unknown id raises StateError | A6 (+M2 killed) | PROVED |

FR-001..FR-006 all traced (test-list traces column); SC-001..SC-005 proved
(SC-005 via the final gates below).

## Final gates

- `dart test` -> **551 passed, 0 failed** (post-25 baseline 544; net +7)
- `dart analyze` -> 5 issues, all pre-existing and unrelated to this feature.
  Zero new issues.

## Findings

- **LOW** — M1 initially survived against A1 because A1's equality is
  tautological (`current()` equals `defaultPolicy` — both sides mutate
  together). The default's literal values are pinned by U1's literal
  assertions, so the composite coverage is sound; A1 alone must not be read as
  pinning the values. No remediation needed (U1 exists); recorded so a future
  deletion of U1 is flagged.
- **LOW** — cycle-4 design correction changed spec text mid-loop (provider
  binds to the datasource's id-less read instead of the id-keyed repository).
  Red evidence for both the original and corrected designs is in git history;
  spec/plan amendments landed in the same commit as the fix (`658a3d0`).
- **INFO** — cycle-3's import-depth slip reproduced the `uri_does_not_exist`
  error class from issue #27 in new code; caught by `dart analyze` within the
  same green step. A reminder that the hand-curated banner exists for a reason.

No HIGH findings. No criteria without tests. No tests tracing to nothing.
