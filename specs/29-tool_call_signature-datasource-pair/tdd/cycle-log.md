# Cycle Log: ToolCallSignature datasource + mock pair

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 562 passed... recorded pre-change: 551 passed, 0 failed (post spec-27)
- analyze: `dart analyze` -> 5 issues (all pre-existing, unchanged)
- commit: `adbb8bb`
- recorded: cycle 0, before any spec-29 change

## Cycle 1: A3, A4, U1..U6 content-addressable entity

- test: `test/domain/entities/tool_call_signature/tool_call_signature_test.dart` (new, 6 tests)
- red: `dart test test/domain/entities/tool_call_signature/`
  -> compile error: `No named parameter with the name 'toolName'` (6 tests failed to load)
- green: entity enriched — `toolName`/`argumentHash`/`version` content triple with const-derived key `'toolName@version:argumentHash'` (id defaults to key; legacy explicit ids preserved but excluded from equality); `==`/`hashCode` on the content triple. Suite -> 557 passed (entity +6, one legacy stub test file still counted... arithmetic below)
- refactor: none — const constructor, derived getter
- commit: entity test (red), `7a6a9bd` (green)

## Cycle 2: A1, A2, U8, U9 capture/lookup interface + mock

- test: `test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart` (rewritten: 3 pre-refinement `UnimplementedError` stub assertions superseded — compile-parity `isA` check kept; 4 behavior tests for this cycle + 3 for cycle 3 written test-first in the same file)
- red: compile errors — `The method 'capture' isn't defined`, `The method 'lookup' isn't defined`
- green (partial by design): interface replaced with the capture/lookup/count/reset contract (scaffolded `current()` dropped — documented in spec.md Assumptions); mock implemented as a key-addressed `Map<String, ToolCallSignature>` with idempotent `capture` and null-on-miss `lookup`; `count`/`reset` intentionally left throwing `UnimplementedError` to preserve cycle 3's red. Run: A1/A2/U8/U9 +5 green, A5..A7 -3 red (`UnimplementedError: Implement ToolCallSignatureMockDatasource.count`) — one run proving both the cycle-2 green and the cycle-3 red
- refactor: none
- commit: datasource test (red), cycle-2 implementation commit

## Cycle 3: A5..A7 idempotency + bounded store

- test: same file, `A5..A7 idempotency + bounded store (cycle 3)` group (3 tests, written in cycle 2's test-first commit)
- red: preserved from cycle 2's run — `UnimplementedError: Implement ToolCallSignatureMockDatasource.count` (3 failures)
- green: `count() => _store.length`; `reset() { _store.clear(); }`. Suite -> 562 passed, 0 failed
- refactor: none — one-liners over the map
- commit: cycle-3 implementation commit `4547b6a`

## Notes and deviations

- Suite arithmetic: 551 (post-27) + 6 (entity) + 8-3 (datasource: 8 behavior tests replace 3 stub tests) = 562.
- Cycle 2 and cycle 3's tests were committed together (one test-first commit) but implemented in two staged green commits, preserving a genuine red for each: compile errors for cycle 2, `UnimplementedError` for cycle 3. The staging is visible in the intermediate run recorded above.
- `dart analyze` held at the 5 pre-existing issues throughout.
- One tooling slip: the cycle-3 implementation command initially mis-quoted a PATH export and timed out without running tests; the file edit had already applied, and the test run was re-executed cleanly afterwards (no silent state).
