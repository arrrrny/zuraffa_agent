# TDD Cycle Log: Episodic Memory

---
feature: 010-episodic-memory
profile: .specify/memory/tdd-profile.md
started_at: 26b289c (branch point on 009-context-compression-llm)
---

Red-green discipline: one behavior per red (remediation T046 from spec 007
applies). A red is genuine only when the failure is the behavior under test
(missing API / wrong semantics), not a test-fixture bug.

## Cycle 1 — U1 AgentMessageHistory

- **Red**: loading failure — `agent_message_history.dart` does not exist
  (`dart test test/llm/agent_message_history_test.dart` → compile error
  `AgentMessageHistory isn't a type`). First red iteration used a
  non-existent `UserMessage(content: String)` / `contentText` API —
  fixture bug, repaired to `UserMessage.text(...)` + `UserMessage.content`
  casts before green work started; red re-confirmed against the correct API.
- **Green**: `lib/src/llm/agent_message_history.dart` (messages +
  episodicMemories + memorySummaries, appendMessages/addMemory helpers).
- **Commits**: 63afeeb (feat U1), f23a80d (test cast fix).

## Cycles 2-4 — U2-U4 store pagination

- **Red**: compile error `The method 'list' isn't defined for the type
  'EpisodicMemoryStore'` (U2, U3, U4 all red in one run — they probe the
  same new API; implemented together but asserted per-behavior).
- **Green**: `EpisodicMemoryStore.list({int? limit, int offset = 0})` —
  insertion order, limit<=0 → empty, offset beyond end → empty, negative
  offset clamped, unmodifiable page.
- **Mutation**: `skip(offset)` → `skip(offset + 1)` (off-by-one window):
  +2 -2 (U2, U3 fail) — killed. Restored, re-verified green.
- **Commit**: 4cd1bb9.

## Cycles 5-8 — U5-U8 RetrieveMemoryTool

- **Red**: loading failure — `retrieve_memory_tool.dart` does not exist
  (`RetrieveMemoryTool isn't a type`). All four behaviors red together
  (single new API surface).
- **Green**: `lib/src/llm/retrieve_memory_tool.dart` — LlmToolSpec surface
  (name/description/schema), execute(snapshot_id) full-memory lookup,
  execute(limit/offset) listing (summaries + counts, no originals),
  typed not-found / invalid-parameters errors. One intermediate fixture
  fix: test asserted an intentionally-omitted `listing.messages` field —
  replaced with `messageCount` assertions matching the designed surface.
- **Mutation**: drop snapshot_id branch (`if (snapshotId != null)` →
  `if (false)`, always listing): +2 -2 (U6, U8 fail) — killed. Restored.
- **Commit**: 01c5177.

## Cycles 9-11 — U9-U11 PersistentEpisodicMemoryStore

- **Red**: loading failure — `persistent_episodic_memory_store.dart` does
  not exist. (Fixture fix pre-green: `firstOrNull` is not in dart:core —
  replaced with an explicit loop in the test's storage fake.)
- **Green**: `PersistentEpisodicMemoryStore extends EpisodicMemoryStore` —
  add() mirrors a CustomEntry (customType 'episodic_memory', payload =
  memory JSON) into SessionStorage; restore() rebuilds in insertion order,
  skips foreign/malformed entries.
- **Mutation**: invert restore filter (`!=` → `==`, restore nothing):
  +1 -2 (U10, U11 fail) — killed. Restored.
- **Commit**: 06695c5.

## Cycles 12-16 — A1-A5 acceptance

- **Red (partial, honest)**: A1 first run failed `CompressionStrategy.none`
  vs `llm` — test-arithmetic bug (8 messages vs messageCountThreshold 10);
  repaired threshold to 5. A5 first run failed `hasLength(2)` vs 1 entry —
  same class of fixture bug (round-2 history too short to re-trigger);
  repaired to add 6 messages. A2-A4 first-ran green: they exercise the
  U1-U11 implementations through public entry points.
- **Green**: all five acceptance behaviors pass through
  LLMBasedContextCompressor.compress(), PersistentEpisodicMemoryStore, and
  RetrieveMemoryTool.
- **Commit**: (acceptance commit), then d5e5d20 style fixes (unnecessary
  imports + prefer_final_locals) restoring analyze to the 111 baseline.

## Final gates

- `dart analyze`: 111 issues — exactly the pre-existing baseline (162 on
  master before specs 007-009; the stack has been driving it down); zero
  issues in any spec-010 file.
- `dart test`: +469 passed / 6 failed — the 6 are the pre-existing
  baseline loading failures (unrelated specs); +16 new passing tests vs.
  the spec-009 baseline (+453), zero new failures.
- Purity: no `dart:io` in any spec-010 file (constitution VII) — verified
  by grep before commit.
