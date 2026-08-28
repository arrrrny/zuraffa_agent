# Feature Specification: Memory distiller — auto-promotion session → long-term

**Branch**: `feat/spec-077-memory-distiller` (off `feat/spec-076-memory-persistence` `fdc9f89`) | **Date**: 2026-08-29

## Summary

Spec 073 gave the agent a manual `promote()` — a human (or the agent itself,
deliberately) decides which session memories earn durability. Spec 076 made
the durable layers file-backed. What is still missing is the **automatic**
bridge: most sessions end, their working memory evaporates, and the good
parts — the high-salience learnings — are lost because nobody called
promote.

The **memory distiller** closes that gap. It scans a session's memory,
decides which records are worth keeping, promotes them into long-term
memory, and reports exactly what it did and why:

- **Salience gate** — a record must reach the policy's `salienceThreshold`
  (default `0.7`). The threshold is the promotion price.
- **Duplicate guard** — a record whose normalized content (trimmed,
  case-folded) already exists in long-term memory is NOT promoted again;
  knowledge must not duplicate. The check runs against the live long-term
  store, so two same-content records in one session also dedupe against
  each other mid-run.
- **Cap** — `maxPerSession` bounds promotions per distillation (highest
  salience first; ties broken by age — older records win, FIFO stability).
  A runaway session cannot flood long-term memory.
- **Full accounting** — `DistillationReport` lists every promoted id and
  every skipped record with a typed reason (`belowThreshold`,
  `duplicateOfLongTerm`, `capReached`) plus what remained in session.
  Nothing silently disappears.

`distill(sessionId)` is an explicit call (session end, a checkpoint, a
cron) — the honest seam for a synchronous engine. It is idempotent:
re-distilling a session promotes nothing new and duplicates nothing.

Composability is the payoff: the distiller only touches
`AgentMemorySystem`'s public surface (`sessionMemory`, `promote`,
`longTermMemory`). Over the 076 persistent stores, distilled knowledge is
immediately durable — distilled at session end, still there after a
restart.

## Files

- `lib/src/engine/memory_distiller.dart` — NEW: `DistillationPolicy`,
  `SkipReason`, `SkippedRecord`, `DistillationReport`, `MemoryDistiller`.
- `test/engine/memory_distiller_test.dart` — NEW: policy gate, dedup, cap,
  ranking, idempotency, report accounting, persistence integration.

## User scenarios

### US1 — Session ends, knowledge stays (P1)

As an agent operator, a session ends and its high-salience learnings are
automatically in long-term memory — nobody had to call promote by hand.

**Independent test**: session with mixed salience → `distill` → the
high-salience records are in long-term (identity preserved), the rest
stayed in session memory.

### US2 — No duplicates, no floods (P1)

As an agent operator, distilling never duplicates existing knowledge and
never promotes more than the cap per session.

**Independent test**: duplicate content skipped with reason; three
candidates with cap 2 → exactly two promoted, third skipped `capReached`.

### US3 — Full accounting (P2)

As an agent operator, I can see exactly what the distiller did — promoted,
skipped (with reason), and what remains in the session.

**Independent test**: report fields fully populated for a mixed session.

## Requirements

### Functional requirements

- **FR-001**: `DistillationPolicy` MUST expose `salienceThreshold`
  (default `0.7`) and `maxPerSession` (`int?`, default null = uncapped),
  with house value semantics.
- **FR-002**: `distill(sessionId)` MUST promote exactly the session
  records with `salience >= threshold`, via the facade's `promote()`
  (identity-preserving: id, content, createdAt, salience unchanged).
- **FR-003**: Boundary: `salience == threshold` promotes.
- **FR-004**: A record whose normalized content (trim + case-fold) already
  exists in long-term memory MUST be skipped with
  `duplicateOfLongTerm` and MUST remain in session memory.
- **FR-005**: With `maxPerSession` set, promotions MUST be capped to the
  top-N candidates (salience desc, then createdAt asc — older first among
  equals); overflow skipped with `capReached`.
- **FR-006**: Below-threshold records MUST be skipped with
  `belowThreshold` and remain in session memory.
- **FR-007**: `distill` MUST be idempotent — a second run on the same
  session promotes nothing new and adds no long-term duplicates.
- **FR-008**: Unknown / empty session → empty report, no throw.
- **FR-009**: `DistillationReport` MUST carry `promoted` (ids, promotion
  order), `skipped` (`SkippedRecord`: id + reason), and `sessionRemaining`
  (records still in session after the run), with house value semantics.
- **FR-010**: Composed with the 076 persistent stores, distilled records
  MUST be durable (present after store rebuild).
- **FR-011**: Gates — `dart analyze --fatal-infos` exit 0; full `dart
  test` green.

### Key entities

- `DistillationPolicy` — threshold + cap value object.
- `SkipReason` — `belowThreshold` / `duplicateOfLongTerm` / `capReached`.
- `DistillationReport` — promoted / skipped / sessionRemaining accounting.
- `MemoryDistiller` — `distill(String sessionId)` over
  `AgentMemorySystem`.

## Success criteria

- **SC-001**: Mixed-salience session distilled correctly (gate + identity).
- **SC-002**: Duplicate guard and cap enforce their invariants.
- **SC-003**: Distillation over persistent stores survives a restart.

## Dependencies

- Builds on: spec 073 (`AgentMemorySystem`) — hard prerequisite.
- Builds on: spec 076 (persistent stores) for FR-010 — this branch stacks
  on 076.
- Feeds: session-end hooks (future), the agent's own memory hygiene.
