# Cycle Log: Event Bus (spec 013)

Append only. Newest last. This file currently holds only the Baseline entry; no
cycles have been driven yet because `plan.md` is absent and the outer-only TDD
plan is being recorded before any change.

## Baseline

- suite: `dart test` -> 909 passed, 2 skipped (0 failed)
- commit: `fce207d`
- recorded: cycle 0, before any change

## Cycle 1: A1 subscriber to LLMChunkEvent receives each chunk event

- test: `test/events/event_bus_test.dart::A1: a subscriber to LLMChunkEvent receives each chunk event` (new)
- red: `dart test test/events/event_bus_test.dart -n "A1"`
  -> `Expected: ['hello', 'world']  Actual: []` (1 failed) — stub `EventBus.on`/`emit` were no-ops
- green: `lib/src/events/event_bus.dart` implemented `on<T>` (registers listener) and `emit<T>` (delivers synchronously to every subscriber of type `T` in registration order, over a copied list so a handler may (un)subscribe during dispatch). Suite `dart test` -> 916 passed, 2 skipped
- refactor: none needed (first cycle; implementation is the minimal pub/sub surface)
- commit: `1a737f1`
