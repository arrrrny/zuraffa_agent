---
feature: 005-subagents-and-declarative
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 8
proven: 4
likely: 0
test_after: 4
no_test: 0
high_smells: 2
criteria_total: 8
criteria_covered: 6 # A1,A2,A3,A4,A6,A8 have a real passing test; A5,A7 do not
mutation_score: 100 # scope: 4 genuine cycles (A2/A3,A4,A6), 0 survived
mutants_survived: 0 # all deliberate mutants killed
suite: 942 passed, 2 skipped (baseline from A4 cycle log; targeted mutant tests re-run green)
---

# TDD Verification: Sub-agents & Declarative Agent Specs (spec 005)

**Verdict: FAIL.** Two acceptance criteria (A5, A7) are exercised by **no test at all**,
and their `traces` in `test-list.md` point at `yaml_agent_spec_provider_test.dart`,
which only validates the parent-chain (the A6 behavior) — it never resolves/merges an
`extends` hierarchy nor loads a YAML playbook. Four behaviors (A2/A3, A4, A6) are genuine
red→green cycles with killed mutants, so the real dispatch/spec machinery is well tested;
the gap is specifically the declarative-resolution path. Two more (A1, A8) are sibling-
credited but actually covered by `sub_agent_dispatch_test.dart` (mis-cited, not untested).

## Test-first evidence

| Behavior | Class      | Evidence                                                                                              |
| -------- | ---------- | ----------------------------------------------------------------------------------------------------- |
| A1       | TEST_AFTER | Credited to `sub_agent_instance_provider_test.dart` (entity-only); real dispatch covered in `sub_agent_dispatch_test.dart` |
| A2       | PROVEN     | cycle A2/A3 red (compile: `SubAgentResult` undefined); added entity; deliberate mutant killed           |
| A3       | PROVEN     | same cycle as A2; `failure.ok = true` mutant failed; restored                                          |
| A4       | PROVEN     | cycle A4 red (`SubAgentInstanceStore` not found); added store + fromJson/toJson; deliberate mutant killed |
| A5       | TEST_AFTER | Credited to `yaml_agent_spec_provider_test.dart`; that file only validates the parent-chain (A6). No `extends`-resolution/merge test exists anywhere |
| A6       | PROVEN     | cycle A6 red (compile: `validate` undefined); added `YamlAgentSpec.validate`; cycle-guard mutant killed |
| A7       | TEST_AFTER | Credited to `yaml_agent_spec_provider_test.dart`; no YAML-loading/playbook test exists in the repo      |
| A8       | TEST_AFTER | Credited to `dispatch_tool_provider_test.dart` (entity-only); dispatch execution covered in `sub_agent_dispatch_test.dart` |

## Findings

| #   | Severity | Finding                                                                                                                                                      | Evidence                                                                                          |
| --- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| 1   | HIGH     | A5 (Spec B `extends` A: B inherits unspecified fields and overrides specified ones) is marked DONE but exercised by **no test**. The cited `yaml_agent_spec_provider_test.dart` only validates the parent-chain (unknown-parent / cyclic checks); no test resolves/merges an `extends` hierarchy, and no merge implementation exists in `lib` (`extendsSpecId` is read only by `validate()` for cycle detection). Acceptance criterion untested (and appears unimplemented). | `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart:63-95` (A6 only); `grep resolve/merge` in `lib/**` and `test/**` returns nothing |
| 2   | HIGH     | A7 (a country playbook YAML loaded as a spec changes agent behavior with no code change) is marked DONE but exercised by **no test**. No YAML-loading implementation or test exists in the repo (`grep loadYaml/fromYaml/playbook` across `lib` and `test` returns nothing); the only YAML test is the entity/validation file. Acceptance criterion untested (and appears unimplemented). | `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart` (entity/validation only); no `playbook` fixture or loader test anywhere |
| 3   | MED      | A1 (dispatched with own session/allowlist/budget) mis-cited to an entity test; the behavior is genuinely covered by `test/engine/sub_agent_dispatch_test.dart` (isolation, budget cap, allowlist enforcement). Re-point the trace. | `sub_agent_instance_provider_test.dart:11-46` (entity only); behavior in `sub_agent_dispatch_test.dart:233,265,306` |
| 4   | MED      | A8 (dispatch-tool creates/resumes instance + awaits result) mis-cited to an entity test; the dispatch execution is covered by `sub_agent_dispatch_test.dart` (instance bookkeeping, isolation, await summary). Re-point the trace. | `dispatch_tool_provider_test.dart:11-46` (entity only); behavior in `sub_agent_dispatch_test.dart` |

No HIGH *test smell* (tautology / doubled subject / assertion-free) was found in the
tests that exist. The genuine cycles (A2/A3, A4, A6) contain real, value-bearing
assertions and killed mutants; the failures here are missing tests for the declarative
resolution path (F1, F2), not weak assertions.

## Mutation results

| Mutant                                                          | Behavior | Survived | Judgment                                                       |
| -------------------------------------------------------------- | -------- | -------- | -------------------------------------------------------------- |
| removed `chain.contains(current)` guard in `validate()`         | A6       | No       | A6 cyclic test failed; restored via `git checkout`             |
| `SubAgentResult.failure` set `ok = true`                       | A3       | No       | A3 test failed (`ok` expected false); restored                 |
| `toJson` `parentSessionId` → `'mutant'`                        | A4       | No       | A4 resumed-leaf assertion failed; restored                    |

Scope: 3 of 8 behaviors mutated (A2/A3 share a cycle, A4, A6); A6's mutant ran from the
cycle log. Mutants survived: 0.

## Traceability

| Criterion | Tests (cited → real)                                                                        | End to end |
| --------- | ------------------------------------------------------------------------------------------- | ---------- |
| A1        | cited entity test → `sub_agent_dispatch_test.dart:233,265,306` (real)                         | Yes        |
| A2        | `sub_agent_result_test.dart` "spec 005 A2/A3" (real, mutant-killed)                          | Yes        |
| A3        | `sub_agent_result_test.dart` "spec 005 A2/A3" (real, mutant-killed)                          | Yes        |
| A4        | `sub_agent_instance_store_test.dart` "A4: a persisted instance id resumes…" (real, mutant-killed) | Yes   |
| A5        | cited `yaml_agent_spec_provider_test.dart` → **no resolution/merge test anywhere**            | **No** (F1) |
| A6        | `yaml_agent_spec_provider_test.dart` "spec 005 A6" (real, mutant-killed)                      | Yes        |
| A7        | cited `yaml_agent_spec_provider_test.dart` → **no YAML-load/playbook test anywhere**          | **No** (F2) |
| A8        | cited entity test → `sub_agent_dispatch_test.dart` (real)                                     | Yes        |

Untested criteria: A5, A7 (no test exercises the real entry point). Tests tracing to
nothing: none — but two `traces` (A5, A7) point at a test that does not test the
behavior they claim (the rubric's "list is lying about coverage" condition).

## What was not audited

- The full suite was not re-run end to end; only the A6/A3/A4 mutant tests were executed
  (re-run green after restore). Baseline green is taken from the A4 cycle log (942 passed, 2 skipped).
- `sub_agent_dispatch_test.dart` was identified and spot-read via grep, not fully re-read.
- Inner-loop unit behaviors are deferred (`plan.md` absent for this feature).
- `dart analyze` was not re-run; the merged `master` baseline is assumed clean.
