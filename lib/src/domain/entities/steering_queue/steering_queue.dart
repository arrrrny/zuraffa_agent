// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R1 — engine core: steering & follow-up
// queues).
//
// The SteeringQueue value object — spec-exact from epic #1 §R1.3
// (issue #2 body: "Steering & follow-up queues (pi-mono pattern):
// mid-mission user input injected between turns without losing state").
//
// Modeled as an immutable snapshot of the queue state at a point in
// time: the pending messages (FIFO order, head at index 0), the count
// of messages already drained, and the timestamp of the most recent
// injection. The engine mutates the queue by appending a message and
// returning a new snapshot (the snapshot itself is never mutated in
// place); the provider is responsible for persisting the latest
// snapshot. This matches pi-mono's agent-loop design where the queue
// is a value the loop consults between turns, not a shared mutable
// object.
//
// Pattern: plain Dart value object (no @Zorphy annotation), same as
// SteeringMessage, AgentSession, ToolResult, StopPolicy.

import '../steering_message/steering_message.dart';

/// SteeringQueue value object (immutable snapshot).
///
/// Holds the pending [SteeringMessage]s the engine will drain between
/// turns, plus a [processedCount] of all messages ever popped and the
/// [lastInjectedAt] timestamp. The pending list is in FIFO order —
/// [head] is the next message the loop will inject.
class SteeringQueue {
  /// Unique queue id (UUID or equivalent). Scoped per mission: each
  /// running mission has exactly one steering queue.
  final String id;

  /// Pending messages in FIFO order (head at index 0). May be empty —
  /// [isEmpty] is true. The engine pops from index 0 and appends to the
  /// end when a new steering input arrives.
  final List<SteeringMessage> pending;

  /// Total messages ever drained from this queue (monotonically
  /// non-decreasing across snapshots). Starts at 0 for a fresh queue
  /// and increments per pop.
  final int processedCount;

  /// When the most recent message was injected into the queue. Null
  /// when the queue has never been injected (fresh queue). Useful for
  /// ordering against other mission events.
  final DateTime? lastInjectedAt;

  const SteeringQueue({
    required this.id,
    required this.pending,
    required this.processedCount,
    this.lastInjectedAt,
  });

  /// True when there are no pending messages to drain.
  bool get isEmpty => pending.isEmpty;

  /// Number of pending messages waiting to be drained.
  int get pendingCount => pending.length;

  /// The next message the engine will inject, or null when the queue
  /// is empty.
  SteeringMessage? get head => pending.isEmpty ? null : pending.first;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SteeringQueue &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _listEq(pending, other.pending) &&
          processedCount == other.processedCount &&
          lastInjectedAt == other.lastInjectedAt);

  static bool _listEq(List<SteeringMessage> a, List<SteeringMessage> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(pending), processedCount, lastInjectedAt);

  @override
  String toString() =>
      'SteeringQueue(id: $id, pending: ${pending.length}, processedCount: $processedCount, lastInjectedAt: $lastInjectedAt)';
}
