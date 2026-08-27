# Cycle Log: StopPolicy datasource + mock pair

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 544 passed, 0 failed (post spec-25)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged)
- commit: `58c9062`
- recorded: cycle 0, before any spec-27 change
