# TDD Verification — feature `116-runnable-example`

Generated fresh by `zfa tdd verify --feature 116-runnable-example`.

## Gate

- gate: `fail_survived`

## Mutation buckets (FR-014)

- killed: 7
- survived: 6
- timed_out: 0

## Behavior scope (FR-018)

- `A1` — traces: `AC-1`
- `A2` — traces: `AC-2`
- `U1` — traces: `FR-001, MinimalAgent.run`
- `U2` — traces: `FR-002, MinimalAgent.transcript`
- `U3` — traces: `FR-003, MinimalAgent.subprocess`
- `contract:A1` — traces: `MinimalAgent.run`
- `contract:A2` — traces: `MinimalAgent.transcript`
- `contract:A3` — traces: `MinimalAgent.subprocess`

## Behavior kinds (issue #1376)

- presence: 0
- absence: 0
- route-outcome: 0
- enabled-state: 0
- sequence: 0

- `A1` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/a1_test.dart
- `A2` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/a2_test.dart
- `U1` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/u1_test.dart
- `U2` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/u2_test.dart
- `U3` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/u3_test.dart
- `contract:A1` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/contract_a1_test.dart
- `contract:A2` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/contract_a2_test.dart
- `contract:A3` — not traced: no scenario-assertions header in test/tdd/116-runnable-example/contract_a3_test.dart

## Restoration (FR-021)

- restoration_verified: true
- restoration_scope_count: 8
- restoration_scope (subjects only, never tests):
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/a2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u3_subject.dart`

## Repro diagnostics (FR-020, non-sensitive)

- runner_command: `dart run mutation_test`
- exit_code: 255
- elapsed_seconds: 666
- report_path: `/Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md`
- preflight_scope_ran (bug #924, per-behavior):
  - `test/tdd/116-runnable-example/a1_test.dart`
  - `test/tdd/116-runnable-example/a2_test.dart`
  - `test/tdd/116-runnable-example/contract_a1_test.dart`
  - `test/tdd/116-runnable-example/contract_a2_test.dart`
  - `test/tdd/116-runnable-example/contract_a3_test.dart`
  - `test/tdd/116-runnable-example/u1_test.dart`
  - `test/tdd/116-runnable-example/u2_test.dart`
  - `test/tdd/116-runnable-example/u3_test.dart`

## Mutation run

- mutation_was_run: true
- mutation_score: 0.5385

## Survived mutants (bug #837)

- `lib/tdd/116-runnable-example/a2_subject.dart:9`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/116-runnable-example/a2_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/116-runnable-example/a2_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/116-runnable-example/contract_a1_subject.dart:28`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/116-runnable-example/contract_a3_subject.dart:26`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/116-runnable-example/contract_a3_subject.dart:26`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)

## Evidence binding (bug #837)

- spec_hash: 137d599abac1237a42a9afafaa2bd42206270ee76038c11a8607044aeee923ae
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/a1_subject.dart` 84941dddb272b60a99b029032901e8d28e0c0423f799e371de3320caabfba7a2
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/a2_subject.dart` 54815b8e02ae793b604d7b2f32dcec2a3f38142e5c24f78cdd3da49611fb7f1d
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a1_subject.dart` 79f6260f7ec50c5431ee72cbd409c064c5c344f2af2ca8dbc94adc2aa5e1ed9c
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a2_subject.dart` 73d9055080159547e2075a7b098c45c54973ae32f6d9348db6c715a271da2f30
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/contract_a3_subject.dart` 3b1b3cd97f15b1d14d3391b17d4b1f36bfc363a055b7ca75293d340f68e3aff1
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u1_subject.dart` ecb620a155269381270379855a5bca1a62a954443173e02c2d9f017868fac726
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u2_subject.dart` cd48d52712ecf6a3daec2ef53f46cf4fb074624f8fe8b32ef753b24268cdec93
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/116-runnable-example/u3_subject.dart` 8e65c1983a51f7386b976dd81214fef944febdabd9076c2e869269353ca9b2ca
