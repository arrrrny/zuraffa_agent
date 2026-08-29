---
feature: 004-providers-and-fallback
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 7
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 7
criteria_covered: 7 # every acceptance behavior has a real passing behavioral test (mostly in spec 008's suite)
mutation_score: 100 # scope: A2 (characterization mutant) + A6 (relies on U16/U17), 0 survived
mutants_survived: 0 # A2 mutant killed; A6 covered by spec 008's U16/U17
suite: 936 passed, 2 skipped (baseline from A2 cycle log; A2 mutant re-run green)
---

# TDD Verification: Providers & Fallback Chain (spec 004)

**Verdict: FAIL.** Six of seven acceptance behaviors (A1, A3, A4, A5, A6, A7) carry no
red-cycle evidence in this feature's loop — they were credited to sibling specs'
existing tests (A6 explicitly to spec 008's `U16`/`U17`), and A2 is a characterization
baseline. The rubric fails closed on any `TEST_AFTER` behavior, so the verdict is FAIL
even though **every one of the seven acceptance criteria is exercised by a real, passing,
behavioral test** and no HIGH smell, no untested criterion, and no surviving mutant exist.
The failure is a discipline-evidence gap (the TDD loop was not driven here), not a
coverage or quality gap — and the `test-list.md` `traces` are mis-cited (see finding F1).

## Test-first evidence

| Behavior | Class          | Evidence                                                                                              |
| -------- | -------------- | ----------------------------------------------------------------------------------------------------- |
| A1       | TEST_AFTER     | Credited to `llm_client_provider_test.dart` (entity-only); real streaming test in `llm_client_contract_test.dart:90` |
| A2       | NOT_APPLICABLE | Characterization/acceptance test `spec_004_a2_dart_agent_core_test.dart`; first run passed; deliberate mutant killed |
| A3       | TEST_AFTER     | Credited to `llm_client_provider_test.dart` (entity-only); usage-ledger behavior in `usage_ledger_test.dart` + datasource/usecase tests |
| A4       | TEST_AFTER     | Credited to `fallback_chain_provider_test.dart` (entity-only); real behavior in `fallback_chain_client_test.dart:31` (U10) |
| A5       | TEST_AFTER     | Credited to `circuit_breaker_test.dart`; half-open probe IS behaviorally tested there (`shouldProbe` recovery readiness) |
| A6       | TEST_AFTER     | Credited to existing `fallback_chain_client_test.dart` U16/U17 (spec 008's suite); no new red in 004 |
| A7       | TEST_AFTER     | Credited to `health_snapshot_provider_test.dart` (entity-only); real behavior in `fallback_chain_client_test.dart:292` (U18) |

## Findings

| #   | Severity | Finding                                                                                                                                                          | Evidence                                                                                  |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| 1   | MED      | Every `traces` value in `test-list.md` points at an entity/codegen/clean-arch provider test that does **not** exercise the acceptance behavior; the real behavioral tests live in sibling suites (mostly spec 008's `fallback_chain_client_test.dart` U10/U15/U16/U17/U18, `circuit_breaker_test.dart`, `llm_client_contract_test.dart`, `usage_ledger_test.dart`, `spec_004_a2_dart_agent_core_test.dart`). Coverage exists; the trace labels are wrong and should be re-pointed. | `test/data/providers/**/*_provider_test.dart` (value-equality/clean-arch only); real tests cited per behavior above |

No HIGH *smell* (tautology / doubled subject / assertion-free) was found in the tests
that exist, and no acceptance criterion is untested. The cited provider tests verify
value equality and clean-arch wiring; the behavioral assertions that actually pin the
acceptance criteria live in the sibling suites and were spot-read via grep (they assert
real values: provider B serving after A fails, half-open probe timing, stream
reconstruction, and `healthSnapshot()` matching live breaker states).

## Mutation results

| Mutant                                          | Behavior | Survived | Judgment                                                       |
| ----------------------------------------------- | -------- | -------- | -------------------------------------------------------------- |
| `expect(violations, isEmpty)` → `isNotEmpty`    | A2       | No       | A2 failed (`Actual: []`); restored via `git checkout`          |
| (A6 relies on `U16`/`U17` from spec 008's suite) | A6       | n/a      | Covered by spec 008's own disciplined tests; not re-mutated here |

Scope: A2 characterized + killed; A6 credited to spec 008. Mutants survived: 0.

## Traceability

| Criterion | Real test (vs cited)                                                                                       | End to end |
| --------- | ---------------------------------------------------------------------------------------------------------- | ---------- |
| A1        | `llm_client_contract_test.dart:90` (stream emits canonical deltas + tool call + usage) — cited entity test  | Yes        |
| A2        | `spec_004_a2_dart_agent_core_test.dart` (characterization, mutant-killed)                                   | Yes        |
| A3        | `usage_ledger_test.dart` + `usage_ledger_entry` datasource/usecase tests — cited entity test                | Yes        |
| A4        | `fallback_chain_client_test.dart:31` (U10: B serves when A fails) — cited entity test                      | Yes        |
| A5        | `circuit_breaker_test.dart` (`shouldProbe` recovery readiness) — cited correctly                           | Yes        |
| A6        | `fallback_chain_client_test.dart:231,263` (U16/U17) — credited to existing                                  | Yes        |
| A7        | `fallback_chain_client_test.dart:292` (U18: snapshot matches live breaker states) — cited entity test       | Yes        |

Untested criteria: none. Tests tracing to nothing: none — but all seven `traces` are
mis-cited to entity/codegen tests that do not exercise the behavior (finding F1).

## What was not audited

- The full suite was not re-run end to end; only A2's mutant test was executed (re-run
  green after restore). Baseline green is taken from the A2 cycle log (936 passed, 2 skipped).
- The sibling behavioral tests (spec 008's `fallback_chain_client_test.dart`,
  `circuit_breaker_test.dart`, `llm_client_contract_test.dart`, `usage_ledger_test.dart`)
  were identified and spot-read via grep, not fully re-read line by line.
- Inner-loop unit behaviors are deferred (`plan.md` absent for this feature).
- `dart analyze` was not re-run; the merged `master` baseline is assumed clean.
