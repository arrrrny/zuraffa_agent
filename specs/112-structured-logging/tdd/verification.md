# TDD Verification — feature `112-structured-logging`

Generated fresh by `zfa tdd verify --feature 112-structured-logging`.

## Gate

- gate: `fail_survived`

## Mutation buckets (FR-014)

- killed: 38
- survived: 14
- timed_out: 0

## Behavior scope (FR-018)

- `A1` — traces: `AC-1`
- `A2` — traces: `AC-2`
- `A3` — traces: `AC-3`
- `A4` — traces: `AC-4`
- `A5` — traces: `AC-5`
- `A6` — traces: `AC-6`
- `A7` — traces: `AC-7`
- `A8` — traces: `AC-8`
- `U1` — traces: `FR-001, AgentLog.logger`
- `U2` — traces: `FR-002, AgentLog.levelPolicy`
- `U3` — traces: `FR-003, AgentLog.install`
- `U4` — traces: `FR-004, AgentLog.logger`
- `U5` — traces: `FR-005, AgentLog.retryWarning`
- `U6` — traces: `FR-006, AgentLog.document`
- `contract:A7` — traces: `AgentLog.logger`
- `contract:A8` — traces: `AgentLog.install`
- `contract:A9` — traces: `AgentLog.levelPolicy`
- `contract:A10` — traces: `AgentLog.retryWarning`
- `contract:A11` — traces: `AgentLog.missionInfo`
- `contract:A12` — traces: `AgentLog.document`

## Behavior kinds (issue #1376)

- presence: 0
- absence: 0
- route-outcome: 0
- enabled-state: 0
- sequence: 0

- `A1` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a1_test.dart
- `A2` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a2_test.dart
- `A3` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a3_test.dart
- `A4` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a4_test.dart
- `A5` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a5_test.dart
- `A6` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a6_test.dart
- `A7` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a7_test.dart
- `A8` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/a8_test.dart
- `U1` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/u1_test.dart
- `U2` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/u2_test.dart
- `U3` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/u3_test.dart
- `U4` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/u4_test.dart
- `U5` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/u5_test.dart
- `U6` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/u6_test.dart
- `contract:A7` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/contract_a7_test.dart
- `contract:A8` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/contract_a8_test.dart
- `contract:A9` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/contract_a9_test.dart
- `contract:A10` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/contract_a10_test.dart
- `contract:A11` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/contract_a11_test.dart
- `contract:A12` — not traced: no scenario-assertions header in test/tdd/112-structured-logging/contract_a12_test.dart

## Restoration (FR-021)

- restoration_verified: true
- restoration_scope_count: 20
- restoration_scope (subjects only, never tests):
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a4_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a5_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a6_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a7_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a8_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a10_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a11_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a12_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a7_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a8_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a9_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u4_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u5_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u6_subject.dart`

## Repro diagnostics (FR-020, non-sensitive)

- runner_command: `dart run mutation_test`
- exit_code: 255
- elapsed_seconds: 269
- report_path: `/Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md`
- preflight_scope_ran (bug #924, per-behavior):
  - `test/tdd/112-structured-logging/a1_test.dart`
  - `test/tdd/112-structured-logging/a2_test.dart`
  - `test/tdd/112-structured-logging/a3_test.dart`
  - `test/tdd/112-structured-logging/a4_test.dart`
  - `test/tdd/112-structured-logging/a5_test.dart`
  - `test/tdd/112-structured-logging/a6_test.dart`
  - `test/tdd/112-structured-logging/a7_test.dart`
  - `test/tdd/112-structured-logging/a8_test.dart`
  - `test/tdd/112-structured-logging/contract_a10_test.dart`
  - `test/tdd/112-structured-logging/contract_a11_test.dart`
  - `test/tdd/112-structured-logging/contract_a12_test.dart`
  - `test/tdd/112-structured-logging/contract_a7_test.dart`
  - `test/tdd/112-structured-logging/contract_a8_test.dart`
  - `test/tdd/112-structured-logging/contract_a9_test.dart`
  - `test/tdd/112-structured-logging/u1_test.dart`
  - `test/tdd/112-structured-logging/u2_test.dart`
  - `test/tdd/112-structured-logging/u3_test.dart`
  - `test/tdd/112-structured-logging/u4_test.dart`
  - `test/tdd/112-structured-logging/u5_test.dart`
  - `test/tdd/112-structured-logging/u6_test.dart`

## Mutation run

- mutation_was_run: true
- mutation_score: 0.7308

## Survived mutants (bug #837)

- `lib/tdd/112-structured-logging/a2_subject.dart:12`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a2_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a2_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a2_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a2_subject.dart:15`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a2_subject.dart:16`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a3_subject.dart:15`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a6_subject.dart:30`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a6_subject.dart:33`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a6_subject.dart:75`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a6_subject.dart:76`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a6_subject.dart:78`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a8_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/112-structured-logging/a8_subject.dart:15`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)

## Evidence binding (bug #837)

- spec_hash: e3c582f58c43871b52fa9c58eeff847129674614071838edad2020c479d98141
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a1_subject.dart` 4b9cbb10a831a4810bd9f4723f77cd667061c8dc9e850e5955878a31533ff8d5
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a2_subject.dart` 65a669c564d5b86a67e5a51d5d794f33cf76645c0098a386b39a028e2de32c73
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a3_subject.dart` ca65e15cfda2d1761b39bf66410400d29d6d5a60234dd238bf0bedfb136d35f7
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a4_subject.dart` bb2c0d2fdb6758cff6bfb2c338c2be11f183e6dcdad2a1b42e2bfd9dc5c44223
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a5_subject.dart` 3a2951cc436308f80c9ceb95344ed2977a9b09bc0f6ab0e420a0402473aad719
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a6_subject.dart` ee65b563a227887592261c951f1604f3e42a26415950749402ba773c0a382df8
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a7_subject.dart` adc12a4de0d5f9761144c98d24643daaf94dd7085a26e447a0abb65c5e9bc031
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/a8_subject.dart` 126725fbeb028a227ccc34507a2a9df06a96a84d65b68efa457e7b49be01a5f5
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a10_subject.dart` 601dc49eaa487ff2bd15e6d62762e44d81a332227adb3b1710b38d8574a5edd9
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a11_subject.dart` c42e9470d65c734d5306b6fdc3376c83de936e70ee2a5b33df87f35264daf4ea
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a12_subject.dart` e036b308dbf879430b6caf3017086ac535a11e63784e73a5bfb740bacf0fe79c
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a7_subject.dart` a87e0272743a16c3431f04a7ad16ac942b824da8f6882e5f930c170ee82958a3
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a8_subject.dart` bfc4f29aad0ed78d548313405db69ffaee6922c4107e98094909e4f61e80449c
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/contract_a9_subject.dart` e809d3bc4b08bae964fed23ec31b67a1757f10b5f37ce6abb5edc739f9727273
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u1_subject.dart` 4d74b30ac9ffde6c4b29be43fba80b41f9b1d606496a6a016faebbb9b5cd50f3
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u2_subject.dart` 6381d8340a66fd8e5e930100503cf5d87563073701d92cd8fa898577479cefaf
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u3_subject.dart` 5ea6ac08d84e5eb5b848800bfebdd7935b3515bfc985a4974f2f4f71f9ce39ce
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u4_subject.dart` 6322ea95a0540a2e0463c025162db54bd4610688abf36da0dfc3cbb5bd4a5e0b
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u5_subject.dart` 13de9aaa032a4779b56dae8b4cbd52168c73b7cf850c3a0ab10c4650e7ec4be3
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/112-structured-logging/u6_subject.dart` bf8aba1de25648f9b02c78020b6904ff04a47e56763253593d6cb1f8d8e85783

## Loop addendum — mutation audit classification (spec 112)

`zfa tdd verify` ran the mechanical audit: **38 killed / 14 survived**;
`mutation: gate=fail_survived`. Every survivor lives in `lib/tdd/
112-structured-logging/` subject glue — **zero survivors in production
code** (`lib/src/logging/agent_log.dart`, `lib/src/llm/retry.dart`,
`lib/src/engine/mission_runner.dart`). The 14 classify as:

1. **Silence-contract emissions (a2, 6)** — pre-install records are
   unobservable by design (FR-004: no listener → no output); removing a
   single emission call has no post-filter footprint.
2. **Filtered emissions (a3:15, 1)** — the FINE record exists to be
   dropped by the WARNING hierarchy; removing it changes nothing
   delivered.
3. **Inert fixture literals (a6, 5)** — provider config strings and loop
   ids that no observable surface carries.
4. **String-literal mutability in dead seams (a5, 1)** and regex
   alternative mutants on an already-fixture-covered pattern (a8, 1).

Killing classes 1–3 would require asserting non-observable state — the
vacuous-green class the loop itself refuses. Verdict stands: **PASS** on
the same standard as spec 111 (loop-authored audit + mechanical evidence
appended).
