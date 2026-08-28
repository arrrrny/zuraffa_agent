// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See specs/068-engine-event-log (gap analysis 2026-08-28: the sealed
// EngineEvent union had no storage/observability layer — nothing in lib/
// emitted, stored, or queried events; the repo gap analysis row 12 records
// "limited observability"). This is the recording primitive beneath the
// future event bus (spec 013 Draft) and the eval harness (epic #7).
//
// Pattern: plain-Dart read projection like UsageLedger
// (lib/src/usage_ledger.dart) — no @Zorphy, no dart:io, no new deps
// (constitution Principles VII/IX).

import 'engine_event.dart';

/// Append-only, in-memory log of [EngineEvent]s with typed and temporal
/// projections.
///
/// Events are stored in insertion order and exposed as unmodifiable
/// snapshots: `events` builds a fresh `List.unmodifiable` copy per read,
/// so callers can never mutate the log through a returned list. The
/// projections (`byType`, `firstOfType`, `lastOfType`, `since`, `before`)
/// are synchronous and preserve insertion order.
///
/// This is deliberately NOT the event bus (spec 013): no subscription,
/// no streaming, no request/response — just record and query. Persistence
/// is owned by the session-recording specs.
class EngineEventLog {
  final List<EngineEvent> _events = [];

  /// Appends [event] to the log.
  void add(EngineEvent event) {
    _events.add(event);
  }

  /// Appends every event of [events] in iteration order.
  void addAll(Iterable<EngineEvent> events) {
    _events.addAll(events);
  }

  /// All recorded events in insertion order, as an unmodifiable snapshot.
  ///
  /// Mutating the returned list throws and never affects the log.
  List<EngineEvent> get events => List.unmodifiable(_events);

  /// Number of events recorded so far.
  int get length => _events.length;

  /// Whether no event has been recorded.
  bool get isEmpty => _events.isEmpty;

  /// Whether at least one event has been recorded.
  bool get isNotEmpty => _events.isNotEmpty;

  /// Events of type [T] or a subtype of [T], in insertion order.
  List<T> byType<T extends EngineEvent>() =>
      List.unmodifiable(_events.whereType<T>());

  /// The first event of type [T] or a subtype of [T], or `null` when none exists.
  T? firstOfType<T extends EngineEvent>() {
    for (final event in _events) {
      if (event is T) return event;
    }
    return null;
  }

  /// The last event of type [T] or a subtype of [T], or `null` when none exists.
  T? lastOfType<T extends EngineEvent>() {
    for (var i = _events.length - 1; i >= 0; i--) {
      final event = _events[i];
      if (event is T) return event;
    }
    return null;
  }

  /// Events emitted at or after [cutoff], in insertion order.
  ///
  /// With [inclusive] (the default) an event emitted exactly at [cutoff]
  /// is included; with `inclusive: false` only strictly later events count.
  List<EngineEvent> since(DateTime cutoff, {bool inclusive = true}) =>
      List.unmodifiable(
        _events.where(
          (e) => inclusive
              ? e.emittedAt.isAfter(cutoff) ||
                    e.emittedAt.isAtSameMomentAs(cutoff)
              : e.emittedAt.isAfter(cutoff),
        ),
      );

  /// Events emitted before [cutoff], in insertion order.
  ///
  /// By default (exclusive) an event emitted exactly at [cutoff] is NOT
  /// included; with `inclusive: true` it is.
  List<EngineEvent> before(DateTime cutoff, {bool inclusive = false}) =>
      List.unmodifiable(
        _events.where(
          (e) => inclusive
              ? e.emittedAt.isBefore(cutoff) ||
                    e.emittedAt.isAtSameMomentAs(cutoff)
              : e.emittedAt.isBefore(cutoff),
        ),
      );
}
