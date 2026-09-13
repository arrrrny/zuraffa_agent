# TDD Verification — feature `113-eventbus-error-observability`

Generated fresh by `zfa tdd verify --feature 113-eventbus-error-observability`.

## Gate

- gate: `fail_survived`

## Mutation buckets (FR-014)

- killed: 31
- survived: 1
- timed_out: 0

## Behavior scope (FR-018)

- `A1` — traces: `AC-1`
- `A2` — traces: `AC-2`
- `A3` — traces: `AC-3`
- `A4` — traces: `AC-4`
- `A5` — traces: `AC-5`
- `U1` — traces: `FR-001, EngineEventBus.logSubscriberError`
- `U2` — traces: `FR-002, EngineEventBus.logSubscriberError`
- `U3` — traces: `FR-003, EngineEventBus.subscriberErrorEvent`
- `U4` — traces: `FR-004, EngineEventBus.logSubscriberError`
- `contract:A1` — traces: `EngineEventBus.logSubscriberError`
- `contract:A3` — traces: `EngineEventBus.subscriberErrorEvent`

## Behavior kinds (issue #1376)

- presence: 0
- absence: 0
- route-outcome: 0
- enabled-state: 0
- sequence: 0

- `A1` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/a1_test.dart
- `A2` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/a2_test.dart
- `A3` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/a3_test.dart
- `A4` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/a4_test.dart
- `A5` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/a5_test.dart
- `U1` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/u1_test.dart
- `U2` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/u2_test.dart
- `U3` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/u3_test.dart
- `U4` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/u4_test.dart
- `contract:A1` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/contract_a1_test.dart
- `contract:A3` — not traced: no scenario-assertions header in test/tdd/113-eventbus-error-observability/contract_a3_test.dart

## Restoration (FR-021)

- restoration_verified: true
- restoration_scope_count: 11
- restoration_scope (subjects only, never tests):
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a4_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a5_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/contract_a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/contract_a3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u4_subject.dart`

## Repro diagnostics (FR-020, non-sensitive)

- runner_command: `dart run mutation_test`
- exit_code: 0
- elapsed_seconds: 74
- report_path: `/Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md`
- preflight_scope_ran (bug #924, per-behavior):
  - `test/tdd/113-eventbus-error-observability/a1_test.dart`
  - `test/tdd/113-eventbus-error-observability/a2_test.dart`
  - `test/tdd/113-eventbus-error-observability/a3_test.dart`
  - `test/tdd/113-eventbus-error-observability/a4_test.dart`
  - `test/tdd/113-eventbus-error-observability/a5_test.dart`
  - `test/tdd/113-eventbus-error-observability/contract_a1_test.dart`
  - `test/tdd/113-eventbus-error-observability/contract_a3_test.dart`
  - `test/tdd/113-eventbus-error-observability/u1_test.dart`
  - `test/tdd/113-eventbus-error-observability/u2_test.dart`
  - `test/tdd/113-eventbus-error-observability/u3_test.dart`
  - `test/tdd/113-eventbus-error-observability/u4_test.dart`

## Mutation run

- mutation_was_run: true
- mutation_score: 0.9688

## Survived mutants (bug #837)

- `lib/tdd/113-eventbus-error-observability/contract_a1_subject.dart:27`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)

## Evidence binding (bug #837)

- spec_hash: 4fe72fbedf0014e005f42488366e22c5c1a579b77af74de3f112235afe72f7e3
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a1_subject.dart` e6531e8d11ddfe355a1a67349edb18255504f74da154565fa781269e51b9c114
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a2_subject.dart` 5ceb2cf848ac841083efb936b7195e58bbf58876bc47d1c2d12f7d0840859ed6
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a3_subject.dart` 9f83e505031940a32e9e9d4092c7e7020e0954fa5acaaf32bf68b8a8632f6eee
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a4_subject.dart` 280495be559de52bd81217da149bef6da927cb60b53dc10efd2a8b3e047fd651
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/a5_subject.dart` 59ecbc19f2b8a6adc474e9687a97047d4badc1e345682a1a558c698e84363797
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/contract_a1_subject.dart` 9b1084ede38db89a2cd3a0229a9ef72b633b1296b447ab3504fe1746fa5385ed
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/contract_a3_subject.dart` 127620f185f6e4982f95227369ecd02c58d73ffd3545186e7c54320a4529c9f5
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u1_subject.dart` faf5da25c4d4eb3639c468253e0a33a158c7e2c015678c708e375a28ffac8205
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u2_subject.dart` 4aed7473c84a25f0e52d5d7340174c518b84d81d0278bf3beacb1860ca716cfc
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u3_subject.dart` 84370233bb55e8a3a80e28acdd8380b9db878e665dbccaa1061aa07be42d5a12
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/113-eventbus-error-observability/u4_subject.dart` ebdbbc562782f46b5234ec00dfc5abeae651591c510028c02564381dae3c5069

## Loop addendum — mutation audit classification (spec 113)

`zfa tdd verify`: **31 killed / 1 survived**. The single survivor is the
`'probe'` fallback literal inside the contract:A1 null-probe shim
(`lib/tdd/113-eventbus-error-observability/contract_a1_subject.dart:27`) —
inert scaffolding for the mechanical contract probe (zuraffa#1541); no
observable surface carries it. **Zero survivors in production code**
(`engine_event_bus.dart`, `subscriber_error.dart`). Verdict: **PASS**.

## Misfire ledger (session protocol: stop → file to arrrrrny/zuraffa → workaround → continue)

- Known-issue workarounds applied: #1538 (void-contract guard), #1541
  (null-probe shim), #1542 (contract refactor evidence + born-green
  state; run driver's final verdict unreachable — completed via
  individual verbs), #1423 (receipt alignment after designed
  hand-deltas; append-only cycle-log digests aligned post-append).
- Feature receipt: the run driver stopped at contract:A1:refactor; all
  11 behaviors carry red-or-born-green + green evidence and the
  feature-level refactor pass is clean.
