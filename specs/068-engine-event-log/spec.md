# Feature Specification: EngineEventLog

**Branch**: `feat/spec-068-engine-event-log` | **Date**: 2026-08-28

## Summary

Add `EngineEventLog` — an append-only, in-memory recording of
`EngineEvent`s with typed and temporal projections — giving the sealed
event union (issues #16–#24, spec 067) its first storage/observability
layer.

Today nothing in `lib/` emits, stores, or queries `EngineEvent`s: the
union is an orphaned type system (verified by gap analysis — the only
references outside its own library are comments). The repo's own gap
analysis (row 12) records the consequence: *"Event Bus … zuraffa_agent:
EngineEvent sealed hierarchy only … Impact: Limited observability."* The
general pub/sub bus remains spec 013 (Draft); what is missing beneath it
is the humble recording primitive every consumer needs: append events,
read them back in order, filter by type, filter by emission time, expose
an unmodifiable snapshot. That is what the eval harness (epic #7, golden
missions asserting emitted event sequences), session recording, and
future bus subscribers all build on. `UsageLedger`
(`lib/src/usage_ledger.dart`) sets the house precedent: a plain-Dart read
projection over records, no `@Zorphy`, no `dart:io`.

## Files

- `lib/src/engine/events/engine_event_log.dart` — new standalone library importing `engine_event.dart`: `EngineEventLog` (mutable append-only accumulator + synchronous projections).
- `lib/zuraffa_agent.dart` — export the new library (non-behavioral wiring).
- `test/engine/events/engine_event_log_test.dart` — new test file (append order, unmodifiable exposure, typed filters, temporal filters with inclusive/exclusive boundaries, emptiness).
- `specs/068-engine-event-log/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

## FRs

- **FR-001**: `void add(EngineEvent event)` appends one event; `void addAll(Iterable<EngineEvent> events)` appends in iteration order. Order of insertion is preserved exactly on read-back.
- **FR-002**: `List<EngineEvent> get events` returns an **unmodifiable** copy — mutating the returned list (add/remove/clear/element assignment) throws; mutations never propagate into the log. `int get length`, `bool get isEmpty`, `bool get isNotEmpty` reflect the append count.
- **FR-003**: `List<T> byType<T extends EngineEvent>()` returns the sub-list of events of exactly type `T`, in insertion order. `T? firstOfType<T extends EngineEvent>()` / `T? lastOfType<T extends EngineEvent>()` return the first/last such event or `null`.
- **FR-004**: `List<EngineEvent> since(DateTime cutoff, {bool inclusive = true})` returns events with `emittedAt >= cutoff` (or `>` when `inclusive: false`), preserving order; `List<EngineEvent> before(DateTime cutoff, {bool inclusive = false})` mirrors it for `emittedAt <=`/`<` cutoff. Implementation note (design discovery during the red phase): the sealed base `EngineEvent` gains an abstract `DateTime get emittedAt;` — every subtype already carries the field, so all 9 conform without modification, and the temporal projections filter the whole union uniformly.
- **FR-005**: `dart analyze --fatal-infos` clean; `dart test` green (baseline 911/2 at `30b4b94` + new tests). Engine purity preserved: pure Dart, no `dart:io`, no new dependencies.

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- The pub/sub bus and request/response patterns (spec 013 Draft — the log is the recording primitive beneath it, not the bus).
- Streaming/async subscription (`Stream<EngineEvent>`) — deferred to the bus spec.
- Persistence of the log (session recording specs own storage).
- A 10th union member `PlanChanged` (spec 067, PR #78) — this spec branches off master and tests against the 9 master events; the log is agnostic to union size.
