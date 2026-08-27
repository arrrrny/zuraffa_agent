---
feature: 036-sub-agent-spec
verdict: PASS
verified_at: ca10fd6
behaviors_total: 21
behaviors_done: 21
test_first: 9 PROVEN (U1..U9, red evidence in cycle log), 5 pinned-as-baseline (U10..U14 incl. 2 new pins), 7 acceptance behaviors green
mutation: 4/4 killed (MUTANT-A isRoot inversion, MUTANT-B identical-compare, M1 budget boundary, M2 self-extends disabled)
criteria_covered: 7/7 acceptance criteria, 7/7 FRs
suite: 709 passed, 0 failed
analyze: 5 pre-existing issues, 0 new
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
---

# TDD Verification: SubAgentSpec value object (validation + pinned semantics)

## Verdict

**PASS** — construction-time validation (identity fields, allowlist ids,
budgets, the extendsSpec 1-cycle) is traced to red-first tests with verbatim
failure evidence in the cycle log; the shipped getters and equality are pinned
by characterization tests whose strength is proven by four killed deliberate
mutants; the 11 pre-existing clean-arch tests pass unchanged; the full suite is
green at 709 with zero new analyzer findings.

Independence note: the audit was performed in the same session that wrote the
tests (no fresh-context subagent available for the smell pass); findings below
were re-derived from the files as they stand, not from memory of intent.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | U1..U9 | reds recorded verbatim in cycle-log cycles 1-4 (assertion failures: `Expected: throws <Instance of 'ArgumentError'> ... Actual: <Closure: () => SubAgentSpec>`), each individually runnable via `--plain-name`; tests and implementation committed together at green per playbook cadence (`1eb07a2`, `9391515`, `d6062c0`, `953a0cd`) |
| PINNED (brownfield) | U10, U12 | pass-first characterization pins (`ca10fd6`), distinct-instance precondition asserted for U12; strength proven by killed mutants A and B |
| BASELINE (pre-existing) | U11, U13, U14 | green in the pre-feature suite and in every full-suite run since; provider suite untouched |

Changes to pre-existing tests: NONE — the 11-test provider file is byte-identical
to `7da6902` (verified `git diff 7da6902 -- test/data/providers/sub_agent_spec/` is
empty).

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| MUTANT-A | `isRoot => extendsSpec != null` (inverted) | U10 pin | KILLED — `Expected: true / Actual: <false>` |
| MUTANT-B | `_listEq(tools, other.tools)` -> `identical(...)` | U12 pin | KILLED — equality failure on distinct-but-equal list instances |
| M1 | `maxTurns! < 1` -> `maxTurns! < 0` (boundary off-by-one) | U6 | KILLED — `Expected: throws ... contains 'maxTurns' / Actual: <Closure>` |
| M2 | `extendsSpec == name` -> `extendsSpec == null` (check disabled) | U9 | KILLED — same shape, `contains 'extendsSpec'` |

Every mutant was restored exactly (`git diff --stat lib/` = 0 after each) and
the affected file re-run green (14/14). One process incident (blanket
`git stash` briefly stashing uncommitted pins) is recorded in the cycle log
with its remediation; no code was lost in the final history.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 empty identity fields rejected | A1 (U1,U2,U3) | PROVED |
| AC US1-2 blank allowlist ids rejected | A2 (U4,U5) | PROVED |
| AC US1-3 invalid budgets rejected, boundaries valid | A3 (U6,U7,U8; M1 killed) | PROVED |
| AC US2-1 self-extends rejected | A4 (U9; M2 killed) | PROVED |
| AC US2-2 four canonical shapes | A5 (U10 + 3 pre-existing; MUTANT-A killed) | PROVED |
| AC US3-1 non-const-list equality | A6 (U12; MUTANT-B killed) | PROVED |
| AC US3-2 single-field inequality | A7 (U13 pre-existing) | PROVED (baseline-pinned) |

FR-001..FR-007 all traced (FR-007 by the untouched green provider tests);
SC-001..SC-004 proved — SC-004 via the final gates below.

## Final gates

- `dart test` -> **709 passed, 0 failed** (baseline 695; +14: 4+3+3+2 new
  behavior tests + 2 characterization pins)
- `dart analyze` -> 5 issues, all pre-existing and unrelated. Zero new issues.

## Findings

- **LOW** — test-after exposure on the green commits: reds were recorded in the
  cycle log before implementation, but the repository received test+impl in one
  commit per cycle (playbook cadence). A cold git-archaeology audit would see
  LIKELY rather than PROVEN from history alone; the cycle log's verbatim red
  lines are the evidence class, per the rubric.
- **LOW** — U11/U13/U14 credit pre-existing tests without new pins; the rubric
  allows BASELINE for shipped behavior and the pre-existing tests demonstrably
  assert these behaviors (verified by reading them, not assumed).
- **INFO** — validation ordering across multiple simultaneous violations is
  deliberately unspecified; tests use single-violation inputs (recorded in the
  list's invariants section).

No HIGH findings. No criteria without tests. No tests tracing to nothing.
