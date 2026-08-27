# Cycle Log: RepetitionTracker datasource + mock pair

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 529 passed, 0 failed
- analyze: `dart analyze` -> 5 issues (all pre-existing: 4 `unnecessary_non_null_assertion` in `test/domain/entities/golden_mission_test.dart`, 1 `depend_on_referenced_packages` in `lib/src/artifact/in_memory_artifact_store.dart`)
- commit: `ccca224`
- recorded: cycle 0, before any change

## Cycle 1: U1..U6 entity parity

- test: `test/domain/entities/repetition_tracker/repetition_tracker_test.dart` (new, 6 tests)
- red: `dart test test/domain/entities/repetition_tracker/repetition_tracker_test.dart`
  -> compile error: `Error: No named parameter with the name 'maxCalls'` (6 tests failed to load — the enriched surface does not exist)
- green: `lib/src/domain/entities/repetition_tracker/repetition_tracker.dart` gained `maxCalls`/`window` fields (defaults 5 / 60s), `isRepetition` predicate, `assert(maxCalls >= 1)`, full equality/hashCode/toString. Suite `dart test` -> 535 passed, 0 failed
- refactor: none needed — const constructor, pure predicate, no dead code
- commit: `bbb06fe` (test, red), `76feab6` (implementation, green)

## Cycle 2: A1..A3 + U8 + U9 loop detection (MVP)

- test: `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` (rewritten: kept U7 compile-parity check, replaced the pre-refinement `UnimplementedError` stub assertions, added 5 behavior tests)
- red: `dart test test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`
  -> compile error: `Error: No named parameter with the name 'config'` (config/clock constructor params, record/count/isLooping methods absent)
- green: interface `repetition_tracker_datasource.dart` extended with `record`/`count`/`isLooping` (+ injectable `at`/`now`); mock implemented with `Map<String, List<DateTime>>` per-signature timestamps + injectable clock. Window pruning deliberately NOT implemented yet (driven by cycle 3). Suite -> 538 passed, 0 failed
- deviation recorded: one `prefer_final_locals` lint appeared in the new test (analyze 5 -> 6); fixed to `final` during green, restoring the 5-issue baseline. Suite re-run green
- refactor: none — methods already minimal
- commit: `c75a3f5` (test, red), `0279256` (implementation, green)

## Cycle 3: A4, A5, U10, U11 window expiry

- test: same file, new group `A4..A5 + U10..U11 window expiry (cycle 3)` (4 tests)
- red: `dart test test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`
  -> 4 assertion failures: `Expected: <0> Actual: <2>` (A4), `Expected: <0> Actual: <1>` (A5), `Expected: <1> Actual: <2>` (U10), `Expected: <0> Actual: <1>` (U11) — the mock counted every record regardless of age
- green: `_prune(occurrences, at:)` added and applied on both write (record) and read (count) paths; an occurrence is expired when its age >= window. Suite -> 542 passed, 0 failed
- fixture corrections during green (implementation was correct, tests carried wrong assumptions): cycle-2 tests now evaluate with explicit in-window `now:` (they had relied on the absence of pruning against the real wall clock); A4 records both occurrences at T0 per AC US2-1 wording; U10 records at 61s-ago so the window has actually passed. Re-run: file +10 green, suite 542 green
- refactor: pruning extracted into the single `_prune` helper used by both paths — no further refactor needed
- commit: `f9cc640` (test, red), `30ae986` (implementation + fixture corrections, green)

## Cycle 4: A6, A7 persistence contract + reset

- test: same file, new group `A6..A7 persistence contract + reset (cycle 4)` (2 tests)
- red: `dart test test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart`
  -> A6 failed: `reset()` still threw `UnimplementedError` (left from the stub). A7 green-on-arrival — its read-after-write semantics were already driven red in cycle 3 (U10/U11), so A7 acts as the acceptance-level confirmation
- green: `reset()` implemented as `_events.clear()` — history cleared, `_config` untouched. Suite -> 544 passed, 0 failed
- refactor: none — one-line implementation
- commit: `47c45a8` (test, red), `25c0285` (implementation, green)

## Notes and deviations

- The original 3 stub-assertion tests (`current`/`reset` throw `UnimplementedError`) were superseded by the refined spec (spec.md Assumptions documents this drift remediation); U7 (compile parity) was kept.
- `dart analyze` held at the 5 pre-existing issues across all cycles except one transient `prefer_final_locals` in cycle 2, fixed within the same green step (see cycle 2 deviation).
- Final state: 6 entity tests + 12 datasource tests = 18 spec-25 tests; suite 544 passed (baseline 529 + 15 net new — 3 superseded stub tests replaced).
