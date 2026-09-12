**Template Version**: `zuraffa-1.0`

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
  traces: MemoryDistille.fr1
- **FR-002**: `distill(sessionId)` MUST promote exactly the session
  records with `salience >= threshold`, via the facade's `promote()`
  (identity-preserving: id, content, createdAt, salience unchanged).
  traces: MemoryDistille.fr2
- **FR-003**: The system MUST satisfy this requirement: Boundary: `salience == threshold` promotes.
  traces: MemoryDistille.fr3
- **FR-004**: The system MUST satisfy this requirement: A record whose normalized content (trim + case-fold) already
  exists in long-term memory MUST be skipped with
  `duplicateOfLongTerm` and MUST remain in session memory.
  traces: MemoryDistille.fr4
- **FR-005**: With `maxPerSession` set, promotions MUST be capped to the
  top-N candidates (salience desc, then createdAt asc — older first among
  equals); overflow skipped with `capReached`.
  traces: MemoryDistille.fr5
- **FR-006**: Below-threshold records MUST be skipped with
  `belowThreshold` and remain in session memory.
  traces: MemoryDistille.fr6
- **FR-007**: `distill` MUST be idempotent — a second run on the same
  session promotes nothing new and adds no long-term duplicates.
  traces: MemoryDistille.fr7
- **FR-008**: The system MUST satisfy this requirement: Unknown / empty session → empty report, no throw.
  traces: MemoryDistille.fr8
- **FR-009**: `DistillationReport` MUST carry `promoted` (ids, promotion
  order), `skipped` (`SkippedRecord`: id + reason), and `sessionRemaining`
  (records still in session after the run), with house value semantics.
  traces: MemoryDistille.fr9
- **FR-010**: The system MUST satisfy this requirement: Composed with the 076 persistent stores, distilled records
  MUST be durable (present after store rebuild).
  traces: MemoryDistille.fr10
- **FR-011**: The system MUST satisfy this requirement: Gates — `dart analyze --fatal-infos` exit 0; full `dart
  test` green.
  traces: MemoryDistille.fr11

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

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** DistillationPolicy defaults and validation **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** distills a mixed-salience session — gate, identity, residue **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** boundary salience equal to threshold promotes; default is 0.7 **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** duplicate guard skips content already known to long-term **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** same-content session siblings dedupe within one run **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** cap promotes the best N — salience desc, older first among equals **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** distill is idempotent — no double promotion, no duplicates **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** unknown session distills to an empty report **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
9. **Given** the feature implementation under its clean-architecture seams **When** DistillationReport accounts for every record **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** distilled knowledge is durable across a store rebuild **Then** the pinned regression test passes (`test/engine/memory_distiller_test.dart`).
   **Type**: acceptance

## Layer Contracts

**Domain**:

- `MemoryDistille`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`, `fr7(...) -> Result`, `fr8(...) -> Result`, `fr9(...) -> Result`, `fr10(...) -> Result`, `fr11(...) -> Result`

