# Cycle Log: PassAtK unbiased estimator (eval-run + threshold slice)

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 709 passed, 0 failed (2026-08-27, post-spec-036)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged list)
- commit: `57412fe`
- recorded: cycle 0, before any spec-037 change

## Cycle 1 — U1/U2 fromResults (FR-001)

- test: `test/domain/entities/pass_at_k/pass_at_k_test.dart` (group
  `spec 037 — PassAtK.fromResults (FR-001)`, 4 tests)
- red: compile error first —
  `test/domain/entities/pass_at_k/pass_at_k_test.dart:20:30: Error: Member not found: 'PassAtK.fromResults'.`
  then, per playbook, the minimal stub was added and the recorded red is its
  driven signal: `UnimplementedError: fromResults` /
  `Which: threw UnimplementedError:<UnimplementedError: fromResults>`
- green: `fromResults` validates non-empty outcomes (ArgumentError naming
  `outcomes`), counts trues, delegates to `compute` (single validation source).
  Suite -> 713 green (`All tests passed!`).
- MISFIRE #3 (recorded per constitution IV, remediation commit `ffeb0b6`):
  the U1 fixture held 5 trues against a "6 true" comment AND the first green
  attempt committed through `dart test | tail -1 && git commit` — the pipe
  masked the runner's exit code, so commit `e8b6e9a` landed with the suite red
  and a false "Suite 713 green" message. Fix: fixture corrected + explicit
  count precondition; all later gates require literal `All tests passed!`
  output with `set -o pipefail`.
- refactor: none.
- commits: `e8b6e9a` (implementation), `ffeb0b6` (postmortem fix)

## Cycle 2 — U3/U4 meetsThreshold (FR-002)

- test: same file, group `spec 037 — PassAtK.meetsThreshold (FR-002)` (2 tests)
- red: compile error —
  `Error: The method 'meetsThreshold' isn't defined for the type 'PassAtK'.`
  then stub signal `UnimplementedError: meetsThreshold`
- green: range+NaN validation (ArgumentError naming `threshold`), inclusive
  `value >= threshold`. Fixture lesson: the equality boundary is derived from
  `result.value` — decimal 0.4 is not bit-equal to the estimator's 0.3999...
  (first green attempt failed U3 for exactly this reason; test design fixed,
  not weakened — the derived-t form asserts real equality).
  Suite -> 715 green.
- refactor: none.
- commit: `8e0580a`

## Cycle 3 — U5 k-monotonicity pin (FR-003, characterization)

- test: same file, group `spec 037 — estimator invariants` (1 sweep test)
- pass-first against shipped code — after one fixture correction: the pin's
  original final assertion claimed certainty at k = n-c = 16, but the correct
  value there is 1 - 1/C(20,16) ~= 0.99979; certainty begins at k = n-c+1 = 17
  (the k-th product term hits zero). The pin caught its own math error on the
  first run — the shipped estimator was never wrong.
- mutants:
  - MUTANT-C product ratio inverted (`(n-i)/(n-c-i)`) -> pin failed:
    `Expected: true / Actual: <false>` /
    `pass@k decreased from k=1 to k=2` -> KILLED; exact restore verified.
  - M3 (verify phase) `where((passed) => !passed)` (counts falses) -> U1:
    `Expected: <6> / Actual: <4>` -> KILLED.
  - M4 (verify phase) `>=` -> `>` -> U3 equality case: `Expected: true` ->
    KILLED.
- green: suite 716 green; analyze 5 pre-existing, unchanged.
- commit: `627d7c2` (characterization pin)

## Notes and deviations

- Suite arithmetic: 709 (baseline) + 4 + 2 + 1 = 716.
- U6/U7/U8 credit the 13 pre-existing provider-suite tests, untouched and green
  throughout (verified `git diff 57412fe -- test/data/providers/pass_at_k/`
  empty).
- Dart-language reds: two of three cycles opened at compile level (member
  missing) — valid per playbook when the language requires the symbol to
  exist; the stub-driven UnimplementedError reds were recorded before any
  implementation existed.
