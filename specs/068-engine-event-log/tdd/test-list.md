# Test List: EngineEventLog

---
feature: 068-engine-event-log
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 5 # FR-001..FR-005 in spec.md
planned_at: 30b4b94 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 911 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at 30b4b94
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `add` / `addAll` append events; read-back preserves insertion order exactly | FR-001 | example | DONE | `test/engine/events/engine_event_log_test.dart::EngineEventLog::add/addAll preserve insertion order` |
| A2  | `events` is an unmodifiable copy: mutation throws and never propagates; `length`/`isEmpty`/`isNotEmpty` track appends | FR-002 | example | DONE | `…::events is an unmodifiable snapshot` + `…::length and emptiness track appends` |
| A3  | `byType<T>` / `firstOfType<T>` / `lastOfType<T>` return exactly-type-T events in insertion order (or null) | FR-003 | example | DONE | `…::byType filters by exact type, insertion order` + `…::firstOfType and lastOfType` |
| A4  | `since(cutoff, {inclusive})` / `before(cutoff, {inclusive})` filter on `emittedAt` with correct inclusive/exclusive boundaries, order preserved | FR-004 | example | DONE | `…::since filters by emission time with inclusive/exclusive boundary` + `…::before filters by emission time with inclusive/exclusive boundary` |
| A5  | `dart analyze --fatal-infos` exits 0 and `dart test` passes baseline + new | FR-005 | gate | DONE | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/events/engine_event_log.dart` (new library)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `EngineEventLog` is constructible empty; `isEmpty` true; all projections return empty/null | FR-001, FR-003 | example | DONE | `…::empty log behaves as empty` |
| U2  | `_events` is never aliased: `events` builds a fresh unmodifiable list per call; two consecutive `events` reads are equal snapshots but not the same mutable object | FR-002 | example | DONE | `…::events is an unmodifiable snapshot` (mutating returned list throws both times) |
| U3  | `byType<T>` uses exact type matching (`whereType` semantics) — a `MissionStarted` is not returned by `byType<MissionCompleted>()` | FR-003 | example | DONE | A3 (distinct payload types in fixture) + mutant M2 |
| U4  | `since`/`before` boundary: an event emitted exactly AT the cutoff is included iff `inclusive: true` (default for `since`, opt-in for `before`) | FR-004 | example | DONE | A4 boundary fixtures + mutant M3 |

### Barrel export

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U5  | `lib/zuraffa_agent.dart` exports `engine_event_log.dart` — the log is reachable from the package root | FR-005 | gate | DONE | analyzer gate (test imports the library path directly; export is non-behavioral wiring) |

## Invariants and edge cases

- Same-instance round-trip: events read back are the exact instances appended (`same(...)`) — keeps this spec independent of spec 066's `==` (any merge order).
- Cutoff with no matching events: `since`/`before` return empty lists, never throw.
- `firstOfType`/`lastOfType` on an empty log or type-absent log: `null`, never throw.
- `addAll` with an empty iterable: no-op.
- Fixtures use the 9 master events with distinct payloads; the log is union-size agnostic (spec 067's `PlanChanged` not required).

## Out of scope

- Pub/sub bus + request/response (spec 013 Draft).
- `Stream<EngineEvent>` subscription (deferred to the bus).
- Persistence (session recording specs own storage).
- Event equality (spec 066 / PR #77).

## Verification commands

- Single feature: `dart test test/engine/events/engine_event_log_test.dart --reporter expanded`
- Full suite: `dart test`
- Analyze gate: `dart analyze --fatal-infos`
- Mutation: deliberate mutants, one at a time, `cp`-restored (see `verification.md`)
