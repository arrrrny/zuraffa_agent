// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 075 — engine event bus: typed synchronous pub/sub over the sealed
// EngineEvent union.
//
// Implements the INTENT of the drafted spec 013-event-bus (pub/sub
// observability) with the house's real event model. The draft's
// request/response pattern and AgentController are deferred — the request
// event types it referenced (BeforeToolCallRequest & co.) do not exist in
// this repo and the sealed union grows only from its own spec; see
// specs/075-engine-event-bus/spec.md for the honest deviation notes.
//
// The bridge to the engine runtimes is one line at the call site:
//
//     MissionRunner(..., onEvent: bus.publish)
//
// — any onEvent-shaped emitter becomes a multi-subscriber source, which a
// bare callback cannot be (GAP-ANALYSIS row 12: "limited observability").
//
// Delivery contract: synchronous, registration order, error-isolated. A
// throwing subscriber never breaks its siblings and never propagates to
// the publisher — broken observers must not break the engine. Errors go
// to the optional onSubscriberError hook; without one they are swallowed
// (the bus is infrastructure; spec 064's dart:io-free discipline rules
// out stderr logging as a default).

import 'events/engine_event.dart';

/// Handle for one bus subscription — cancel to stop delivery.
class EngineEventSubscription {
  EngineEventSubscription._(this._onCancel);

  final void Function() _onCancel;
  bool _active = true;

  /// Whether this subscription still receives events.
  bool get isActive => _active;

  /// Stops delivery. Idempotent — cancelling twice is safe and the slot
  /// is freed on the first call.
  void cancel() {
    if (!_active) return;
    _active = false;
    _onCancel();
  }
}

class _SubscriberEntry {
  _SubscriberEntry({required this.type, required this.invoke});

  /// The exact `T` the caller subscribed with — either a concrete final
  /// subtype of EngineEvent or EngineEvent itself (the wildcard).
  final Type type;

  /// Type-erasing invoker built at subscribe time as `(e) => handler(e
  /// as T)` — the cast is sound because publish only invokes when
  /// `type` matches the event's runtime type. No dynamic dispatch.
  final void Function(EngineEvent) invoke;

  bool active = true;
}

/// A synchronous typed publish/subscribe bus over [EngineEvent]s.
///
/// ```dart
/// final bus = EngineEventBus();
/// bus.subscribe<TurnStarted>((e) => print('turn ${e.turnId}'));
/// bus.subscribe<EngineEvent>(logger);        // everything
/// emitter.onEvent = bus.publish;             // the bridge
/// ```
class EngineEventBus {
  EngineEventBus({void Function(Object error, EngineEvent event)?
      onSubscriberError})
      : _onSubscriberError = onSubscriberError;

  final void Function(Object error, EngineEvent event)? _onSubscriberError;
  final List<_SubscriberEntry> _entries = [];

  /// Number of live subscriptions.
  int get subscriberCount =>
      _entries.where((e) => e.active).length;

  /// Subscribes [handler] to events of exactly type [T]. Subscribe with
  /// `EngineEvent` itself to receive every event (the wildcard). All
  /// union members are final classes, so exact-type matching is
  /// unambiguous.
  EngineEventSubscription subscribe<T extends EngineEvent>(
      void Function(T) handler) {
    final entry = _SubscriberEntry(
      type: T,
      invoke: (EngineEvent event) => handler(event as T),
    );
    _entries.add(entry);
    return EngineEventSubscription._(() => entry.active = false);
  }

  /// Publishes [event] synchronously to every matching subscriber, in
  /// registration order. Subscriber errors are isolated: they never
  /// break delivery to later subscribers and never propagate here.
  void publish(EngineEvent event) {
    final eventType = event.runtimeType;
    for (final entry in _entries) {
      if (!entry.active) continue;
      if (entry.type != EngineEvent && entry.type != eventType) continue;
      try {
        entry.invoke(event);
      } catch (error) {
        _onSubscriberError?.call(error, event);
        // Swallowed on purpose — see the library doc comment.
      }
    }
  }

  /// Re-publishes [events] through the bus, in order, to every CURRENT
  /// subscriber. This is a broadcast, not per-subscriber catch-up: a
  /// late subscriber that wants history subscribes first, then the
  /// caller replays — the natural composition with EngineEventLog
  /// (spec 068): `bus.replay(log.events)`.
  void replay(Iterable<EngineEvent> events) {
    for (final event in events) {
      publish(event);
    }
  }
}
