---
feature: 104-playbook-as-spec-steering
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: a354c15 # short SHA audited
behaviors: 37
proven: 28
likely: 9
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 6
criteria_covered: 6
mutation_score: null # no mutation tool in the profile; 9 deliberate mutants run, 9 killed; 4 remediation revert-reds additionally recorded
mutants_survived: 0
suite: 1197 passed, 2 skipped, ~40s
---

# TDD Verification: Playbook-as-spec behavior steering (R5#4)

**Verdict: PASS.** Every behavior is PROVEN or LIKELY with recorded red
evidence, every acceptance criterion has an end-to-end test through the real
entry point, no HIGH smells, and every deliberate mutant was killed. The
first audit (`ff0fc90`, kept in git history) failed on four pass-first pins
(U17/U26/U27/U30); remediation T019 drove genuine red-first evidence for
each (behavior reverted, verbatim red, restored, green) and T020 pinned the
at-limit truncation boundary at the acceptance level — both remediations are
recorded as cycles in `tdd/cycle-log.md` and committed (`a354c15`).

This audit was run by the same session that wrote the tests (no fresh-context
subagent available); every file was re-read from disk for the smell pass
rather than recalled from memory, per Hard Rule 2. The first audit's FAIL
and its remediation are part of this report's evidence, not hidden by the
overwrite: git history keeps the earlier report at `ff0fc90`.

## Test-first evidence

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| U1–U9 | PROVEN | cycles 1–3: reds recorded verbatim; `6970007`/`012027d`/`41f859c` add test + source together |
| U10–U16 | PROVEN | cycles 4–6: reds recorded; `eac91c9`/`dbcc33e`/`420b5c9` add test + source together |
| U18–U25 | PROVEN | cycles 8–10: reds recorded; `2772fa9`/`91c8360`/`b94be29` add test + source together |
| U28, U29 | PROVEN | cycle 12: reds recorded; `6cf2472` adds test + source together |
| A1, A2 | PROVEN | the loader tests ARE the acceptance tests (library entry point, 081 precedent); reds recorded at cycles 4–6 |
| A3–A6 | LIKELY | staged reds recorded verbatim at cycle 7 BEFORE any runtime implementation existed (UnimplementedError x4); git history cannot corroborate the order — the staged red file was parked outside the tree during the inner cycles (every commit must stay green), so the tests landed at the close (`ff0fc90`) after the source |
| U17 | LIKELY | originally pass-first (rule red-proven at the aggregate by U6, cycle 3); remediation T019 recorded a genuine red (rule reverted -> U17 failed verbatim -> restored -> green) |
| U26, U27 | LIKELY | originally pass-first (behavior shipped with cycle 10's exhaustive enum switch / full interface); remediation T019 recorded genuine reds (blocklist-disabled and batch-bypass reverts -> verbatim failures -> restored -> green) |
| U30 | LIKELY | originally pass-first (clock read landed with cycle 8); remediation T019 recorded a genuine red (construction-captured clock -> verbatim timestamp failure -> restored -> green) |
| A7 | PROVEN (gates) | run during this audit: purity clean (no `dart:io` in the spec-104 files), `dart analyze --fatal-infos` zero findings on all changed files, full suite 1197 passed / 2 skipped |

Existing tests touched by the feature: one — U2's equality fixture was
legalized in cycle 3 (its blocklist-mutant kept the reference's non-empty
`allowed` list, which U6's new rule rejects). Assertion strength unchanged
(same equality semantics, legal fixture variant); justification recorded in
the cycle log at the time and re-checked in this audit. Not a weakening.

## Findings

Ordered by severity. Finding 1 (the audit's FAIL reason) and finding 2 are
REMEDIATED (`a354c15`); findings 3–4 are accepted notes.

| # | Severity | Finding | Status |
| - | -------- | ------- | ------ |
| 1 | HIGH | U17/U26/U27/U30 were TEST_AFTER (pass-first pins on behavior that shipped with adjacent cycles' greens) | REMEDIATED — T019 red-first cycles recorded in the log; classifications now LIKELY |
| 2 | MED | A5 pinned only the over-limit truncation path (the off-by-one audit mutant escaped it) | REMEDIATED — T020 at-limit pin added; the mutant now fails A5 too |
| 3 | LOW | Germany reference fixture duplicated across `playbook_test.dart` and `playbook_loader_test.dart` (value-object level vs document level — different shapes, same data) | accepted — the two files pin different levels (081 house pattern mirrors fixtures per level) |
| 4 | LOW | U2 packs six equality-mutation expects into one test (all the same behavior; the failure output names the failing expect) | accepted — one behavior, one reason to fail |

## Mutation results

No mutation tool in the stack profile (none in `dev_dependencies`; none
installed — setup Hard Rule 2). Deliberate mutants, one at a time, restored
and verified after each:

| Mutant | Behaviors sampled | Killed by | Judgment |
| ------ | ----------------- | --------- | -------- |
| Reject empty `allowed` on allowlist gates (cycle 3) | U7 | U7 | boundary pin proven |
| Drop allowlist/blocked inconsistency rule (cycle 6 + remediation) | U17, U6 | both | rule pinned at both levels |
| Blocklist refuses nothing (cycle 11 + remediation) | U26 | U26 | blocklist semantics pinned |
| `dispatchBatch` bypasses the gate (cycle 11 + remediation) | U27 | U27 | per-call gating pinned |
| Clock captured at construction (cycle 12 + remediation) | U30 | U30 | call-time read pinned |
| Gate ignored entirely (audit 1) | A6 | A6 | the acceptance depends on the gate |
| Truncation `<=` to `<` (audit 1 + T020 re-check) | U28, A5 | both | at-limit boundary pinned at both levels |
| Seeding reversed to LIFO (audit 1) | U21, A3 | both | FIFO order pinned at both levels |

9 distinct mutants, 9 killed, 0 survivors — including two mutants killed at
BOTH the unit and acceptance levels. Highest-risk behaviors sampled: the A6
acceptance criterion (the R5#4 property itself), the tool gate, the
truncation boundary, and the steering order. Not sampled: loader field
preservation (A1/U10) — covered by the full-equality pin against a
hand-constructed playbook.

## Traceability

| Criterion | Tests | End to end |
| --------- | ----- | ---------- |
| SC-001 | A1, A2 (U1–U17) | Yes — the loader is the real entry point (081 precedent) |
| SC-002 | A3 (U18–U22) | Yes — through `MissionRunner.run` with real events |
| SC-003 | A4 (U23–U27) | Yes — through a running mission (`ToolCallCompleted`, transcript, untouched inner dispatcher) |
| SC-004 | A5 (U28–U30) | Yes — through a running mission (directive + capped summary + at-limit pass-through) |
| SC-005 (R5#4) | A6 | Yes — Germany/Japan/France documents through the IDENTICAL composed code path: per-document steering, opposite tool refusals on the same planned calls, per-document caps |
| SC-006 | A7 | Yes — gates run in this report |

Untested criteria: none. Tests tracing to nothing: none (every test's
`traces` value resolves to a criterion or FR in spec.md; the test list's
quality bar was re-checked).

## What was not audited

- No mutation TOOL exists in this stack; mutation strength was measured by
  9 deliberate mutants (sampled, not exhaustive). The un-sampled branches
  (loader field preservation, toString, no-op paths) rely on example pins.
- Coverage was not measured (the profile's coverage capability produces
  VM-format JSON; no threshold gate is configured — corroboration only).
- The audit was not independent: no fresh-context subagent was available;
  the same session wrote the tests, performed the remediation, and graded
  them, re-reading every file from disk instead (Hard Rule 2 disclosure).
  The first-audit FAIL and its remediation trail mitigate, not eliminate,
  this.
- Performance/load behavior: no criterion, no test, not assessed.
- The constitution-principle proposal from `/speckit.tdd.setup` (a TDD
  principle for `.specify/memory/constitution.md`) remains unapplied — the
  constitution is the user's document and no approval was given; the text
  is reported in the session log for later adoption.
