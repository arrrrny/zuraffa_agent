# Cycle Log: ToolCallSignature datasource + mock pair

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 551 passed, 0 failed (post spec-27)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged)
- commit: `95f59a9`
- recorded: cycle 0, before any spec-29 change
