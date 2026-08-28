# Implementation Plan: Engine event bus

**Branch**: `feat/spec-075-engine-event-bus` | **Date**: 2026-08-29

## Summary

One new library: a synchronous typed pub/sub bus over the sealed
EngineEvent union, plus its subscription handle. No existing files
change.

## Phase 1 — Design

### `lib/src/engine/engine_event_bus.dart` (new)

```dart
class EngineEventSubscription {
  bool get isActive;
  void cancel(); // idempotent; frees the slot
}

class EngineEventBus {
  EngineEventBus({void Function(Object error, EngineEvent event)?
                    onSubscriberError});

  EngineEventSubscription subscribe<T extends EngineEvent>(
      void Function(T) handler);

  void publish(EngineEvent event);   // sync, registration order, isolated
  void replay(Iterable<EngineEvent> events); // broadcast each, in order
  int get subscriberCount;
}
```

Key decisions:

- **Type-safe bridging**: each subscription stores `Type type` plus an
  erasing invoker `void Function(EngineEvent)` built as `(e) =>
  handler(e as T)` — the cast is sound because delivery only invokes
  when `type == e.runtimeType` (or `type == EngineEvent`); no dynamic
  calls anywhere.
- **Matching**: exact runtime-type equality against the subscribed `T`;
  `subscribe<EngineEvent>` matches everything. The union's subtypes are
  all `final`, so no deeper hierarchy exists to worry about.
- **Isolation**: each delivery wrapped in try/catch; on error, the
  `onSubscriberError` hook (if any) receives the error and the event;
  the loop continues to later subscribers; nothing rethrows.
- **Order**: single `List<_Entry>` in registration order; publish walks
  it. Cancellation marks the entry inactive (lazy removal keeps indices
  stable mid-walk; count reflects live entries).

### Test file `test/engine/engine_event_bus_test.dart` (new)

Uses REAL union members (TurnStarted / TurnCompleted / ToolCallStarted /
ToolCallCompleted) as the draft's SC-001 intends — no fake event types.
Groups: typed delivery / order / fan-out / isolation / cancel / replay /
count / bridge pattern.

## Phase 2 — TDD

1. RED: test file first — missing-library compile failure.
2. GREEN: implement until green.
3. Deliberate mutants (cp-restored): M1 publish delivers to the FIRST
   matching subscriber only — killed by fan-out test; M2 type filter
   dropped (all subscribers get all events) — killed by typed-delivery
   test; M3 replay iterates reversed — killed by replay order test;
   M4 isolation removed (subscriber exception propagates) — killed by
   isolation test; M5 cancel is a no-op — killed by cancel test.
4. Gates + `tdd/verification.md`; commit; push; PR (base master).
