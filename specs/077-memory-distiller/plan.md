# Implementation Plan: Memory distiller (spec 077)

## Approach

A pure policy engine over `AgentMemorySystem`'s public surface. No new
plumbing in the memory module — the distiller is a consumer, not a
modification. One new file, one new test file.

## Components

### 1. Value objects

- `DistillationPolicy({double salienceThreshold = 0.7, int? maxPerSession})`
  — validates threshold in 0.0..1.0 and cap >= 1 when set; `==` /
  `hashCode` / `toString`.
- `SkipReason` enum — `belowThreshold` / `duplicateOfLongTerm` /
  `capReached`.
- `SkippedRecord({id, reason})` — house value semantics.
- `DistillationReport({promoted, skipped, sessionRemaining})` — house
  value semantics; `promoted` is ordered (promotion order = ranking order).

### 2. `MemoryDistiller`

```dart
MemoryDistiller({required AgentMemorySystem system, DistillationPolicy policy = const DistillationPolicy()})
```

`distill(String sessionId)`:

1. Snapshot: `system.sessionMemory.forSession(sessionId)` (insertion order).
2. Gate: partition into candidates (`salience >= threshold`) and
   below-threshold (skipped, stay in session).
3. Rank candidates: salience desc, createdAt asc (older first among
   equals — FIFO stability).
4. Walk ranked candidates in order, maintaining a promotion budget
   (`maxPerSession` remaining, null = ∞) and a live duplicate check:
   - normalized content (trim + toLowerCase) already in long-term
     (`system.longTermMemory`) → skip `duplicateOfLongTerm` (stays in
     session); the live check catches same-content session siblings too,
     because each promotion lands in long-term immediately.
   - budget exhausted → skip `capReached`.
   - else → `system.promote(id)` (facade semantics: identity preserved,
     removed from session), record id in `promoted`.
5. Return `DistillationReport(promoted, skipped, sessionRemaining:
   system.sessionMemory.forSession(sessionId).length)`.

Promotion failures cannot occur mid-walk (ids come from the live snapshot;
`promote` throws only on unknown/already-LT ids) — no defensive catching.

### 3. Tests (`test/engine/memory_distiller_test.dart`, ~11)

Gate + boundary, identity preservation, duplicate guard (incl. same-run
sibling dedup), cap + ranking stability, idempotency, unknown session,
report accounting/value semantics, default policy 0.7 boundary, and the
076 persistence integration (distill → rebuild stores → durable).

## Sequencing

1. RED — tests against missing `memory_distiller.dart`.
2. GREEN — implementation.
3. Mutations M1–M5 (one at a time, cp-restored).
4. Gates + verification.md + commit + PR (base
   `feat/spec-076-memory-persistence`).

## Risks / decisions

- **Explicit `distill()` call, not a hook**: no async/event infra in the
  memory module; an explicit seam is honest and trivially wireable later.
- **Duplicate check against the LIVE long-term store**: makes same-run
  sibling dedup fall out for free — no separate seen-set.
- **Report is exhaustive**: every snapshot record ends up in `promoted`
  or `skipped` — full accounting beats silent filtering.
