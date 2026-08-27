# Cycle Log: Context Compression (LLM-based)

Append only. Newest last. Every entry's `red` block is the evidence that the test
existed and failed before the implementation.

## Baseline

- suite: `dart test` -> 442 passed, 6 failed (all loading failures of unrelated
  unimplemented features, pre-dating this branch).
- commit: `878fe98` (spec 008 head)
- recorded: cycle 0, before any 009 change.
- green criterion per cycle: the cycle's test passes AND the full-suite failure
  delta vs this baseline is zero new.

## Cycle 1: U1 EpisodicMemory value object

- test: `test/domain/entities/episodic_memory_test.dart::U1` (new)
- red: -> `Failed to load ... episodic_memory.dart` (entity missing), then one
  test-side cast fix (AgentMessage base has no `content` getter)
- green: hand-curated value object (agent_message.dart precedent documented in
  the header; JSON round-trip via AgentMessage.toJson/fromJson). Plan amended:
  Zorphy wrapper rejected because the embedded conversational model is
  hand-curated (custom converters would be needed). Suite -> 443 passed, 6 failed
- commits: `e815925`, `6106c53`

## Cycle 2: U2 EpisodicMemoryStore

- test: `test/llm/episodic_memory_store_test.dart::U2` (new)
- red: -> loading failure (store missing)
- green: add/retrieve-by-id/search (case-insensitive summary substring),
  insertion order, id-replace semantics. Suite -> 444 passed, 6 failed
- commit: `896d691`

## Cycle 3: U3 identity below threshold

- test: `test/llm/context_compressor_test.dart::U3` (new)
- red: -> `UnimplementedError`
- green: threshold gate (tokens via estimateContextTokens, optional
  messageCountThreshold, keepRecentMessages floor) returning the identity
  result. Suite -> 445 passed, 6 failed
- commit: `1732e87`

## Cycle 4: U4 LLM compression path

- test: `test/llm/context_compressor_test.dart::U4` (new)
- red: -> `UnimplementedError`
- green: split into compressed/preserved, one generate() call with the
  five-section system prompt, snapshot validation, memory storage, result
  assembly (heuristic fallback still stubbed). Suite -> 446 passed, 6 failed
- commit: `248c439`

## Cycle 5: U5 prompt contract — passed first run, mutant-verified

- test: `test/llm/context_compressor_test.dart::U5` (new; FakeLlmClient gained
  request recording)
- red: none — passed on first run (prompt landed with U4's green)
- deliberate-mutant check: '<current_plan>' mutated to '<plan>' in the prompt
  -> U5 failed; restored; green
- commit: `5a3eaa7`

## Cycle 6: U6 invalid-snapshot fallback

- test: `test/llm/context_compressor_test.dart::U6` (new)
- red: -> `UnimplementedError` (fallback stub)
- green: HeuristicSummarizer wrapped — compressed messages adapted to
  MessageEntry inputs, CompactionSummary rendered into the same five-section
  XML shape. One await lint fixed before green. Suite -> 448 passed, 6 failed
- commit: `4815867`

## Cycle 7: U7 LLM-error fallback (SC-003)

- test: `test/llm/context_compressor_test.dart::U7` (new)
- red: -> `Expected: contains 'use approach' Actual: '<state_snapshot>...'
  (empty key knowledge)` — a TEST fixture bug (Decision lines did not start
  their lines, so the line-based heuristic found none); fixture repaired with
  newline-separated Decision lines, then green
- commit: `52e742f`

## Cycle 8: U8 memory entry stored and retrievable — first run, mutant-verified

- test: `test/llm/context_compressor_test.dart::U8` (new)
- red: none — passed on first run (storage landed with U4)
- deliberate-mutant check: first attempt did NOT apply (replace silently
  missed); redone with an application assertion — memory created but not
  stored -> U8 failed; restored; green. Lesson recorded: always assert the
  mutant applied.
- commit: `4c358a5`

## Cycle 9: U9 100-message compression under 3000 tokens (SC-001) — first run, mutant-verified

- test: `test/llm/context_compressor_test.dart::U9` (new)
- red: none — passed on first run
- deliberate-mutant check: keepRecentMessages tripled (preserved slice
  inflated) -> budget exceeded -> U9 failed; restored; green
- commit: `ff633c7`

## Cycle 10: U10 configurable thresholds (AC-5)

- test: `test/llm/context_compressor_test.dart::U10` (new)
- red: -> `Expected: llm Actual: none` — a TEST arithmetic bug (300 chars is
  ~75 tokens, not 300); fixture corrected to 1600-char messages (~40k tokens),
  then green. The threshold/message-count logic itself landed with U3.
- deliberate-mutant check: messageCountThreshold branch removed -> U10 failed;
  restored; green
- commits: `b3a7bde`

## Cycle 11: U11 heuristic fallback parity — first run, mutant-verified

- test: `test/llm/context_compressor_test.dart::U11` (new)
- red: none — passed on first run (parity landed with U6)
- deliberate-mutant check: fallback memory not stored -> U11 failed; restored;
  green
- commit: `5add3fa`

## Audit-phase closing

- analyze: pristine for all feature files (one unused test variable removed,
  `d660dca`); full-repo issues 112 — all pre-existing baseline (was 162 at
  master).
- suite: 453 passed, 6 failed — the 6 failures pre-date the branch (unrelated
  loading failures); zero new failures vs the spec-008 baseline.
