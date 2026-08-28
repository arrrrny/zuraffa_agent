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
