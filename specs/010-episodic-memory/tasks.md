# Tasks: Episodic Memory

**Branch**: `010-episodic-memory` | **Date**: 2026-08-27 | **Plan**: [plan.md](./plan.md)

## T1 — Spec-kit artifacts

- [x] T1.1 Refine spec.md (AC-1..AC-5 ids, pagination/persistence contracts, assumptions).
- [x] T1.2 plan.md (this file) + tasks.md.
- [x] T1.3 tdd/test-list.md (16 behaviors: U1-U11, A1-A5).

## T2 — AgentMessageHistory value object (U1)

- [x] T2.1 Red: test `agent_message_history_test.dart::U1` (loading red — file missing).
- [x] T2.2 Green: `lib/src/llm/agent_message_history.dart` — messages + episodicMemories + memorySummaries.
- [x] T2.3 Commit.

## T3 — Store pagination (U2-U4)

- [x] T3.1 Red: `list()` returns all entries in insertion order (U2).
- [x] T3.2 Green: implement `list` on EpisodicMemoryStore.
- [x] T3.3 Red: `list(limit: n)` / `list(offset: k)` slice correctly (U3).
- [x] T3.4 Green: slicing logic.
- [x] T3.5 Red+Green: edge cases — offset beyond end → empty, limit<=0 → empty (U4).
- [x] T3.6 Mutation check: off-by-one on the slice window (killed).
- [x] T3.7 Commit(s).

## T4 — RetrieveMemoryTool (U5-U8)

- [x] T4.1 Red: tool advertises LlmToolSpec name `retrieve_memory` with snapshot_id/limit/offset schema (U5).
- [x] T4.2 Green: `lib/src/llm/retrieve_memory_tool.dart` spec surface.
- [x] T4.3 Red: execute(snapshot_id) returns that memory with original messages (U6).
- [x] T4.4 Green: snapshot lookup branch.
- [x] T4.5 Red: execute(limit/offset) returns paginated summaries (U7).
- [x] T4.6 Green: pagination branch (delegates to store.list).
- [x] T4.7 Red+Green: unknown snapshot_id → typed not-found error result (U8).
- [x] T4.8 Mutation check: snapshot_id branch dropped (killed).
- [x] T4.9 Commit(s).

## T5 — PersistentEpisodicMemoryStore (U9-U11)

- [x] T5.1 Red: add() mirrors a CustomEntry (customType 'episodic_memory') into SessionStorage (U9).
- [x] T5.2 Green: `lib/src/llm/persistent_episodic_memory_store.dart` extends EpisodicMemoryStore.
- [x] T5.3 Red: restore() rebuilds entries from storage (U10).
- [x] T5.4 Green: restore filter + decode.
- [x] T5.5 Red: retrieve-by-id works on a restored store (U11).
- [x] T5.6 Mutation check: restore filter inverted (killed).
- [x] T5.7 Commit(s).

## T6 — Acceptance behaviors (A1-A5)

- [x] T6.1 A1: 3 compressions on a growing conversation → 3 entries covering full history (SC-001, AC-1/AC-3-first-half).
- [x] T6.2 A2: retrieval returns original messages, not just summaries (SC-002, AC-4/AC-1).
- [x] T6.3 A3: persistence round-trip — add, new store on same storage, restore, retrieve (SC-003, AC-3-persistence-half).
- [x] T6.4 A4: retrieve_memory tool by snapshot_id end-to-end (AC-4).
- [x] T6.5 A5: retrieve_memory tool pagination end-to-end (AC-5).
- [x] T6.6 Commits.

## T7 — Gates + verification

- [x] T7.1 `dart analyze` — 0 issues in new files; no new issues overall.
- [x] T7.2 `dart test` — no new failures vs. baseline (+453/-6); all feature tests green.
- [x] T7.3 tdd/cycle-log.md complete with red evidence per cycle.
- [x] T7.4 tdd/verification.md audit vs. rubric.
- [x] T7.5 Commit spec-kit artifacts.

## T8 — Delivery

- [x] T8.1 Push branch `010-episodic-memory`.
- [x] T8.2 Open PR → master (stacked above #61; body documents merge order).
