# Cycle Log: UiTreePayload value object (serialization + diffing slice)

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 716 passed, 0 failed (2026-08-27, post-spec-037)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged list)
- commit: `43dffd7`
- recorded: cycle 0, before any spec-038 change

## Cycle 1 — U1/U2/U6 serialization (FR-001/002)

- test: `test/domain/entities/ui_tree_payload/ui_tree_payload_test.dart`
  (group `spec 038 — UiTreePayload serialization`, 5 tests)
- red: compile errors, verbatim —
  `Error: Member not found: 'UiTreePayload.fromJson'.` and
  `Error: The method 'toJson' isn't defined for the type 'UiTreePayload'.`
- DEVIATION (caught before any run): the first implementation edit also
  included `diff` + helpers — cycle-2 scope — violating one-cycle scope.
  Reverted in-editor before the first test run; diff was re-implemented in
  cycle 2 strictly after its own red. Recorded here per Hard Rule 2 honesty.
- green: `toJson` (exact four keys) + `fromJson` (mimeType type+value
  checked, pinning fields, tree shape; constructs via the standard
  constructor). Suite -> 721 green (`All tests passed!`).
- refactor: none.
- commit: `fda576f`

## Cycle 2 — U3/U4/U5/U9/U10 diff (FR-003/004)

- test: same file, group `spec 038 — UiTreePayload.diff` (6 tests)
- red: compile error —
  `Error: The method 'diff' isn't defined for the type 'UiTreePayload'.`
  (also `UiTreeDiff` unresolved, same cause)
- green, two design corrections driven by the failing tests:
  1. U4 red (`Expected: ['root/1'] / Actual: ['root', 'root/1']`) fixed the
     CONTRACT, not the test: minimal-anchor semantics — a node is 'changed'
     only when its own payload (node minus `children`) differs; descendant
     changes never bubble to ancestors. Implemented via `_ownPayloadEq`.
  2. U3 red exposed a direction swap in MY symmetry expectations
     (`reverse.removedPaths` vs `addedPaths`); fixture fixed, code unchanged.
  Two collection-literal inference warnings in the new fixtures were fixed
  BEFORE commit — analyze held at the 5-issue baseline (constitution X).
  Suite -> 727 green.
- refactor: none beyond the corrections above.
- commit: `7e69612`

## Verification experiments (verify-phase mutants, before verification.md)

All applied alone, run, restored exactly (`git diff --stat lib/` = 0), file
re-run green after each.

- M1 `parsedMime != mimeType` arm disabled -> run against
  "U2: missing mimeType" it PASSED (survivor — the `is! String` guard covers
  the missing case); re-aimed at "U2: wrong mimeType" ->
  `Expected: throws ... contains 'mimeType' / Actual: <Closure: () => UiTreePayload>`
  -> KILLED. Lesson recorded: each mutant must target the test that owns the
  mutated arm.
- M1b whole mimeType check removed (`if (false)`) -> missing-mimeType test
  fails the same way -> KILLED (both arms are load-bearing).
- M2 changed-detection disabled (`if (false)`) -> U4:
  `Expected: ['root/1'] / Actual: []` -> KILLED.
- M3 toJson key renamed to `mimeTypeX` -> U1:
  `Expected: Set:['mimeType', ...] / Actual: Set:['mimeTypeX', ...]` ->
  KILLED (also breaks U6 round-trip).

## Notes and deviations

- Suite arithmetic: 716 (baseline) + 5 + 6 = 727.
- U7/U8 + clean-arch rows credit the 11 pre-existing provider-suite tests,
  untouched and green throughout (`git diff 43dffd7 -- test/data/providers/ui_tree_payload/`
  empty).
- The over-implementation slip in cycle 1 never reached a commit or a run;
  disclosed as a process note, zero artifact impact.
