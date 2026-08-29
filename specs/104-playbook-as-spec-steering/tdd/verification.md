---
feature: 104-playbook-as-spec-steering
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: ff0fc90 # short SHA audited
behaviors: 37
proven: 28
likely: 4
test_after: 4
no_test: 0
high_smells: 0
criteria_total: 6
criteria_covered: 6
mutation_score: null # no mutation tool in the profile; 10 deliberate mutants run, 10 killed (5 during cycles, 5 during this audit)
mutants_survived: 0
suite: 1197 passed, 2 skipped, ~34s
---

# TDD Verification: Playbook-as-spec behavior steering (R5#4)

**Verdict: FAIL.** Four unit behaviors (U17, U26, U27, U30) are TEST_AFTER:
their tests were written after the behavior had already shipped with an
adjacent cycle's implementation (pass-first, admitted in the cycle log and
mutant-checked at the time — strength is proven; test-first order is not).
Every acceptance criterion is covered end to end, no HIGH smells were found,
and every one of the ten deliberate mutants was killed — the FAIL is solely
the four write-order violations of the rubric's evidence classes.

This audit was run by the same session that wrote the tests (no fresh-context
subagent available); every file was re-read from disk for the smell pass
rather than recalled from memory, per Hard Rule 2.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| U1–U9 | PROVEN | cycles 1–3: reds recorded verbatim; `6970007`/`012027d`/`41f859c` add test + source together |
| U10–U16 | PROVEN | cycles 4–6: reds recorded; `eac91c9`/`dbcc33e`/`420b5c9` add test + source together |
| U18–U25 | PROVEN | cycles 8–10: reds recorded; `2772fa9`/`91c8360`/`b94be29` add test + source together |
| U28, U29 | PROVEN | cycle 12: reds recorded; `6cf2472` adds test + source together |
| A1, A2 | PROVEN | A1/A2's tests are the loader tests (U10, U12–U15) — library entry point, reds recorded (081 precedent) |
| A3–A6 | LIKELY | staged reds recorded verbatim at cycle 7 BEFORE any runtime implementation existed (UnimplementedError x4); git history cannot corroborate — the staged red file was parked outside the tree during inner cycles (every commit must be green), so the tests landed at the close (`ff0fc90`) after the source |
| U17 | TEST_AFTER | test written at cycle 6 AFTER the rule shipped (cycle 3, `41f859c`); passed first-run; mutant check recorded (rule dropped -> U17 failed) — strength proven, order not |
| U26, U27 | TEST_AFTER | tests written at cycle 11 AFTER the behavior shipped with cycle 10's exhaustive enum switch / full interface implementation (`b94be29`); passed first-run; mutant checks recorded (blocklist-disable, batch-bypass) — strength proven, order not |
| U30 | TEST_AFTER | test written at cycle 12 AFTER clock-reading shipped with cycle 8's `steeringMessages` (`2772fa9`); passed first-run; mutant check recorded (clock captured at construction) — strength proven, order not |
| A7 | PROVEN (gates) | run during this audit: purity clean, `dart analyze --fatal-infos` zero findings on changed files, full suite 1197 passed / 2 skipped |

Existing tests touched by the feature: one — U2's equality fixture was
legalized in cycle 3 (its blocklist-mutant kept the reference's non-empty
`allowed` list, which U6's new rule rejects). Assertion strength unchanged
(same equality semantics, legal fixture variant); justification recorded in
the cycle log at the time. Reported here because a changed pre-existing test
deserves a read, not because it is a weakening.

## Findings

Ordered by severity, each with evidence and the fix.

| # | Severity | Finding | Evidence |
| - | -------- | ------- | -------- |
| 1 | HIGH (blocking) | U17/U26/U27/U30 are TEST_AFTER — tests written after the behavior shipped with an adjacent cycle's green (exhaustive switch, interface completeness, shared clock read). Pass-first was admitted and mutant-checked in the log; the rubric has no pass-first evidence class, so they classify TEST_AFTER and force the verdict | cycle-log cycles 6, 11, 12; commits `41f859c`/`b94be29`/`2772fa9` (source) precede `420b5c9`/`845e2de`/`6cf2472` (tests) |
| 2 | MED | A5 pins only the over-limit truncation path; the at-limit boundary is pinned solely by U28 (which killed the audit's off-by-one mutant — `<=` to `<` left A5 green, U28 red) | `test/engine/playbook_runtime_test.dart` A5 vs U28 |
| 3 | LOW | The Germany reference fixture is duplicated across `playbook_test.dart` and `playbook_loader_test.dart` (value-object level vs document level — different shapes, same data) | both files |
| 4 | LOW | U2 packs six equality-mutation expects into one test (all the same behavior; the failure output names the failing expect) | `test/domain/entities/playbook/playbook_test.dart` U2 |

## Mutation results

No mutation tool in the stack profile (none in `dev_dependencies`; none
installed — Hard Rule 2 of setup). Deliberate mutants, one at a time,
restored and verified after each:

| Mutant | Behaviors sampled | Killed by | Judgment |
| ------ | ----------------- | --------- | -------- |
| Reject empty `allowed` on allowlist gates (cycle 3) | U7 | U7 | boundary pin proven |
| Drop allowlist/blocked inconsistency rule (cycle 6) | U17, U6 | both | rule pinned at both levels |
| Blocklist refuses nothing (cycle 11) | U26 | U26 | blocklist semantics pinned |
| `dispatchBatch` bypasses the gate (cycle 11) | U27 | U27 | per-call gating pinned |
| Clock captured at construction (cycle 12) | U30 | U30 | call-time read pinned |
| Gate ignored entirely (audit) | A6 | A6 | the acceptance depends on the gate |
| Truncation `<=` to `<` (audit) | U28 | U28 (A5 passes — see finding 2) | at-limit boundary pinned at unit level |
| Seeding reversed to LIFO (audit) | U21, A3 | both | FIFO order pinned at both levels |

10 mutants, 10 killed, 0 survivors. Highest-risk behaviors sampled: the A6
acceptance criterion (the R5#4 property), the gate, the truncation boundary,
and the steering order. Not sampled: loader field preservation (A1/U10) —
covered by the full-equality pin against a hand-constructed playbook.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| SC-001 | A1, A2 (U1–U17) | Yes — the loader is the real entry point (081 precedent) |
| SC-002 | A3 (U18–U22) | Yes — through `MissionRunner.run` with real events |
| SC-003 | A4 (U23–U27) | Yes — through a running mission (`ToolCallCompleted`, transcript) |
| SC-004 | A5 (U28–U30) | Yes — through a running mission (directive + capped summary) |
| SC-005 (R5#4) | A6 | Yes — three documents through the identical composed code path |
| SC-006 | A7 | Yes — gates run in this report |

Untested criteria: none. Tests tracing to nothing: none (every test's
`traces` value resolves to a criterion or FR in spec.md).

## What was not audited

- No mutation TOOL exists in this stack; mutation strength was measured by
  10 deliberate mutants (sampled, not exhaustive) — the un-sampled branches
  (loader field preservation, toString, no-op paths) rely on example pins.
- Coverage was not measured (the profile's coverage capability produces
  VM-format JSON; no threshold gate is configured — corroboration only, not
  run for this audit).
- The audit was not independent: no fresh-context subagent was available;
  the same session wrote the tests and graded them, re-reading every file
  from disk instead (Hard Rule 2 disclosure).
- Performance/load behavior: no criterion, no test, not assessed.
