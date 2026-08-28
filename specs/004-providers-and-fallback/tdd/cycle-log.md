# Cycle Log: Providers & Fallback Chain (spec 004)

Append only. Newest last. This file currently holds only the Baseline entry; no
cycles have been driven yet because `plan.md` is absent and the outer-only TDD
plan is being recorded before any change.

## Baseline

- suite: `dart test` -> 909 passed, 2 skipped (0 failed)
- commit: `fce207d`
- recorded: cycle 0, before any change

## Cycle A2 — no dart_agent_core dependency; ported files attributed (red -> green)

- test: `test/integration/spec_004_a2_dart_agent_core_test.dart` :: "spec 004 A2 -
  engine has no dart_agent_core dependency; vendored files attributed"
- RED/GREEN: repo-invariant acceptance test. Scans `lib/` for an `import
  'package:dart_agent_core'` and asserts ported files carry MIT attribution +
  state the dependency is absent. First run PASSED (the repo already satisfies
  it) — a characterization/acceptance test, not a feature build.
- Deliberate mutant: changed `expect(violations, isEmpty)` to `isNotEmpty` ->
  test FAILED (`Actual: []`), proving it really checks the invariant. Restored;
  green.
- No refactor needed (no implementation change — the behavior is a repo posture).
- suite after: `dart test` -> 936 passed, 2 skipped (0 failed).

## Cycle: A6 — mid-stream failure restarts or surfaces, never truncates

- No new test written: A6 was already covered, and the playbook's Phase 1 says to
  credit an existing passing test rather than rewrite it. The earlier BLOCKED note
  was a false negative from a keyword scan of the wrong file
  (`test/data/providers/fallback_chain/…` instead of `test/llm/…`).
- Both halves of the behavior are asserted in
  `test/llm/fallback_chain_client_test.dart`:
  - "or restarts": U16 — provider A emits `'partial-'` then throws
    `LlmNetworkException`; the consumer receives `['partial-', 'full-', 'answer']`
    with `isComplete: true`, so the partial chunks are kept and B's stream
    completes the response.
  - "or surfaces, never silently truncates": U17 — with `policyMode: 'skip'` the
    consumer sees `['partial-']` and then the `LlmNetworkException`, with
    `b.streamCalls == 0` and `isComplete: false` — no phantom completion.
- Verified: `dart test test/llm/fallback_chain_client_test.dart --name "U16|U17"`
  -> `+2: All tests passed!`
- commit: (this cycle)
