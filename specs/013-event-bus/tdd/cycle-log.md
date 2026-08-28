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

## Cycle 2: A2 multiple subscribers receive an event, in registration order

- test: `test/events/event_bus_test.dart::A2: multiple subscribers each receive an event, in registration order` (new)
- red (deliberate-mutant): the test passed on first run because A1's `emit<T>` already
  loops every subscriber. Mutant — `emit` delivers only to `subs.first` — produced
  `Expected: ['s1:x', 's2:x', 's3:x']` (only `['s1:x']`); restoring the full loop
  returned it to green. This confirms the test actually guards multi-subscriber delivery.
- green: no implementation change required; A2 is satisfied by the A1 `emit<T>` loop
  over a copied subscriber list. Suite `dart test` -> 916 passed, 2 skipped.
- refactor: none needed.
- commit: `7155247`

## Cycle 3: A3 BeforeToolCallRequest handler response is used

- test: `test/events/event_bus_test.dart::A3: a registered BeforeToolCallRequest handler response is used` (new)
- red: `dart test test/events/event_bus_test.dart -n "A3"`
  -> `Bad state: request/response not yet implemented` (stub `request` threw)
- green: `lib/src/events/event_bus.dart` added `_handlers` map, `registerHandler<T,R>`
  (stores an async closure returning `Object`) and `request<R>` (dispatches to the
  most-recently-registered handler, casts its response to `R`, throws `StateError`
  when none registered). Suite `dart test` -> 918 passed, 2 skipped.
- refactor: none needed (handler closure casts `R` to `Object` at the boundary).
- commit: `bbac0ce`

## Cycle 4: A4 AgentController.publish delivers to all listeners

- test: `test/events/event_bus_test.dart::A4: AgentController.publish delivers to all listeners like EventBus` (new)
- red: `dart test test/events/event_bus_test.dart -n "A4"`
  -> `Expected: ['hi']  Actual: []` (stub `AgentController.publish`/`listen` were no-ops)
- green: `lib/src/events/event_bus.dart` `AgentController.publish<T>` delegates to
  `_bus.emit<T>` and `listen<T>` to `_bus.on<T>`, so delivery is identical to the
  bare bus. Suite `dart test` -> 919 passed, 2 skipped.
- refactor: none needed.
- commit: `3dd8459`

## Summary

All four acceptance behaviors (A1 pub/sub delivery, A2 multi-subscriber in-order,
A3 request/response, A4 controller wrapper) are DONE and green. FR-005 (engine emits
lifecycle events through the bus) is deferred — it depends on spec 002 landing its
event stream, and is recorded as out of scope for this feature.
