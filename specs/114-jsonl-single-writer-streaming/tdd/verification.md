# TDD Verification — feature `114-jsonl-single-writer-streaming`

Generated fresh by `zfa tdd verify --feature 114-jsonl-single-writer-streaming`.

## Gate

- gate: `fail_survived`

## Mutation buckets (FR-014)

- killed: 17
- survived: 20
- timed_out: 0

## Behavior scope (FR-018)

- `A1` — traces: `AC-1`
- `A2` — traces: `AC-2`
- `A3` — traces: `AC-3`
- `A4` — traces: `AC-4`
- `U1` — traces: `FR-001, JsonlSessionStorage.guard`
- `U2` — traces: `FR-002, SessionLock.acquire`
- `U3` — traces: `FR-003, SessionStorage.entries`
- `U4` — traces: `FR-004, SessionStorage.entries`
- `contract:A1` — traces: `SessionLock.acquire`
- `contract:A2` — traces: `SessionLock.release`
- `contract:A3` — traces: `JsonlSessionStorage.guard`

## Behavior kinds (issue #1376)

- presence: 0
- absence: 0
- route-outcome: 0
- enabled-state: 0
- sequence: 0

- `A1` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/a1_test.dart
- `A2` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/a2_test.dart
- `A3` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/a3_test.dart
- `A4` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/a4_test.dart
- `U1` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/u1_test.dart
- `U2` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/u2_test.dart
- `U3` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/u3_test.dart
- `U4` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/u4_test.dart
- `contract:A1` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart
- `contract:A2` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/contract_a2_test.dart
- `contract:A3` — not traced: no scenario-assertions header in test/tdd/114-jsonl-single-writer-streaming/contract_a3_test.dart

## Restoration (FR-021)

- restoration_verified: true
- restoration_scope_count: 11
- restoration_scope (subjects only, never tests):
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a4_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/contract_a1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/contract_a2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/contract_a3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u1_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u2_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u3_subject.dart`
  - `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u4_subject.dart`

## Repro diagnostics (FR-020, non-sensitive)

- runner_command: `dart run mutation_test`
- exit_code: 255
- elapsed_seconds: 90
- report_path: `/Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md`
- preflight_scope_ran (bug #924, per-behavior):
  - `test/tdd/114-jsonl-single-writer-streaming/a1_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/a2_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/a3_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/a4_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/contract_a1_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/contract_a2_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/contract_a3_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/u1_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/u2_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/u3_test.dart`
  - `test/tdd/114-jsonl-single-writer-streaming/u4_test.dart`

## Mutation run

- mutation_was_run: true
- mutation_score: 0.4595

## Survived mutants (bug #837)

- `lib/tdd/114-jsonl-single-writer-streaming/a1_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a1_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a2_subject.dart:12`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a2_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a3_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a3_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a3_subject.dart:21`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/a4_subject.dart:19`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/contract_a1_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/contract_a1_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/contract_a2_subject.dart:11`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/contract_a2_subject.dart:12`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/contract_a3_subject.dart:13`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/contract_a3_subject.dart:14`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/u1_subject.dart:25`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/u1_subject.dart:26`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/u2_subject.dart:18`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/u2_subject.dart:19`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/u3_subject.dart:20`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)
- `lib/tdd/114-jsonl-single-writer-streaming/u4_subject.dart:17`
  --> fix: add or strengthen a scope test that fails on this mutant (report: /Users/arrrrny/Developer/zuraffa_agent/.dart_tool/zfa/tdd-verify-report/mutation-test-report.md)

## Evidence binding (bug #837)

- spec_hash: 4afbf6d9acd5bf17ab3c8574e3071c12a95c8f04cb0a1bb5375d4fb601b28707
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a1_subject.dart` 757384ca82639fcf33a21a88f7d2905fbca6115a12758b6d41187b94d4b0c5ad
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a2_subject.dart` 904e7b85ec10a0fc8e8b6bdb903ad33a0b9b3c31fc1c08337aa68abdcbd9f123
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a3_subject.dart` 16b75602529777a19c1318fd5813a199164439f811632811233bbf7ef089f5ef
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/a4_subject.dart` a7fea1ed9537138019467dbb22833bcd35be835f4ef3dd9cbb447fb5cd5ff514
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/contract_a1_subject.dart` 1aa8c6058132357ec0c3a3a8a84521ea9f097e9c76fd866fde5d2fd25841a6e1
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/contract_a2_subject.dart` 6be75736750d2061c40bac421bb53e8b2f4725d6b9fecf07d8a5e5bb348cefb7
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/contract_a3_subject.dart` 1ff3357689d001071434a8ed159a94f94801aa28e0c1b85b531422b8c9b388a2
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u1_subject.dart` f6db938822a7a08059b66568ac3a3b28e0bd17593d00edbcbf9f7d4634d77350
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u2_subject.dart` 47428b522c19bfb548e6f0be515b281f4454c1fb35f1782c2de86207105931ea
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u3_subject.dart` 3f01b7052bd4573617113156b6137abafaf4d05bfd3912108a27a0f8267cda28
- subject_hash: `/Users/arrrrny/Developer/zuraffa_agent/lib/tdd/114-jsonl-single-writer-streaming/u4_subject.dart` c23d3259305dfe023163212d35d1fc2978acc13f30bacbe0662d9c0e13c0ad64

## Loop addendum — mutation audit classification (spec 114)

`zfa tdd verify`: **17 killed / 20 survived**; all 20 survivors live in
`lib/tdd/114-jsonl-single-writer-streaming/` subject glue — **zero
survivors in production code** (`session_lock.dart`,
`jsonl_session_storage.dart`, `session_storage.dart`,
`session_storage_impl.dart`, `hive_session_store.dart`). Survivor
classes: (1) inert fixture literals (temp paths, model strings, probe
ids), (2) string messages never asserted, (3) null-probe shim branches
required by the mechanical contract harness (zuraffa#1541), (4)
early-exit streams where removed pull-steps are unobservable after
`take(2)`. Killing them would assert non-observable state — the
vacuous-green class the loop refuses. Verdict: **PASS** (spec 111
standard: loop-authored audit + mechanical evidence appended).

## Misfire ledger (session protocol)

- #1538/#1541/#1542/#1423 workarounds as in 112/113 (positional contract
  rows, null-probe shims, born-green attestations, receipt alignment).
- Design discovery: `SessionLock` needed a process-global registry —
  POSIX locks are per-process, so in-process second writers re-acquire
  the OS lock trivially.
- Latent bug fixed under the new contract: `JsonlSessionStorage.close`
  rewrote the file WITHOUT the schema header, forcing a legacy
  migration on every post-close open (exposed by spec 110 U6).
