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
//
// Refined under specs/033-steering-queue (TDD): the enqueue/dispatch
// semantics the task names — enqueue (FIFO append + lastInjectedAt stamp)
// and pop (head out as a ({message, queue}) record, processedCount + 1,
// StateError on empty) as pure snapshot transitions, the defensive copy
// that makes the "immutable snapshot" doc claim load-bearing
// (List.unmodifiable — the scaffold stored the caller's reference), and
// the persistence contract (toJson/fromJson round-tripping the whole
// queue incl. FIFO order). The scaffold described the snapshot mutation
// model in doc comments but shipped no transition API.

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

  const SteeringQueue._({
    required this.id,
    required this.pending,
    required this.processedCount,
    this.lastInjectedAt,
  });

  /// Constructs an immutable snapshot. The [pending] list is defensively
  /// copied into an unmodifiable view: later mutations of the caller's
  /// list do not affect the queue, and direct writes to [SteeringQueue.pending]
  /// throw.
  SteeringQueue({
    required this.id,
    required List<SteeringMessage> pending,
    required this.processedCount,
    this.lastInjectedAt,
  }) : pending = List.unmodifiable(pending);

  /// True when there are no pending messages to drain.
  bool get isEmpty => pending.isEmpty;

  /// Number of pending messages waiting to be drained.
  int get pendingCount => pending.length;

  /// The next message the engine will inject, or null when the queue
  /// is empty.
  SteeringMessage? get head => pending.isEmpty ? null : pending.first;

  /// Enqueues [message]: returns a NEW snapshot with the message
  /// appended to the pending list (FIFO — it becomes the new tail) and
  /// [lastInjectedAt] stamped with the message's own [SteeringMessage.injectedAt]
  /// (the queue records when the newest message was injected).
  /// `id` and `processedCount` are unchanged; `this` is never mutated.
  SteeringQueue enqueue(SteeringMessage message) => SteeringQueue._(
        id: id,
        pending: List.unmodifiable([...pending, message]),
        processedCount: processedCount,
        lastInjectedAt: message.injectedAt,
      );

  /// Pops the head message (dispatch): returns a record carrying the
  /// popped [message] (the one the engine's `SteeringInjected` event will
  /// consume) and the drained [queue] — a NEW snapshot with the head
  /// removed, `processedCount + 1`, and `lastInjectedAt` preserved.
  /// `this` is never mutated.
  ///
  /// Throws [StateError] when the queue is empty — the engine consults
  /// [isEmpty] first; a silent null would fabricate a steering injection.
  ({SteeringMessage message, SteeringQueue queue}) pop() {
    if (pending.isEmpty) {
      throw StateError('SteeringQueue.pop() on empty queue $id');
    }
    final message = pending.first;
    return (
      message: message,
      queue: SteeringQueue._(
        id: id,
        pending: List.unmodifiable(pending.skip(1)),
        processedCount: processedCount + 1,
        lastInjectedAt: lastInjectedAt,
      ),
    );
  }

  /// Serializes the queue to a JSON map (persistence contract):
  /// `{id, pending: [{id, content, injectedAt}...], processedCount,
  /// lastInjectedAt?}` — `lastInjectedAt` only when present
  /// (absent-never-fabricated); pending preserves FIFO order.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'pending': [for (final m in pending) m.toJson()],
      'processedCount': processedCount,
    };
    if (lastInjectedAt != null) json['lastInjectedAt'] = lastInjectedAt!.toIso8601String();
    return json;
  }

  /// Parses a [SteeringQueue] from its JSON shape (see [toJson]).
  /// Round-trips id, pending (FIFO order), processedCount, and
  /// lastInjectedAt-when-present. Throws [ArgumentError] naming the
  /// offending key when a required field is missing or ill-typed (a
  /// non-list `pending` or a non-map entry included) — never fabricates
  /// a default.
  factory SteeringQueue.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String) {
      throw ArgumentError.value(idRaw, 'id', 'SteeringQueue.id must be a non-null string');
    }
    final processedRaw = json['processedCount'];
    if (processedRaw is! int || processedRaw < 0) {
      throw ArgumentError.value(processedRaw, 'processedCount', 'SteeringQueue.processedCount must be a non-negative int');
    }
    final pendingRaw = json['pending'];
    if (pendingRaw is! List) {
      throw ArgumentError.value(pendingRaw, 'pending', 'SteeringQueue.pending must be a list of message objects');
    }
    final messages = <SteeringMessage>[
      for (final entry in pendingRaw)
        if (entry is Map)
          SteeringMessage.fromJson(Map<String, dynamic>.from(entry))
        else
          throw ArgumentError.value(entry, 'pending', 'SteeringQueue.pending entries must be message objects'),
    ];
    DateTime? lastInjectedAt;
    final lastRaw = json['lastInjectedAt'];
    if (lastRaw != null) {
      if (lastRaw is! String) {
        throw ArgumentError.value(lastRaw, 'lastInjectedAt', 'SteeringQueue.lastInjectedAt must be an ISO-8601 string when present');
      }
      lastInjectedAt = DateTime.tryParse(lastRaw);
      if (lastInjectedAt == null) {
        throw ArgumentError.value(lastRaw, 'lastInjectedAt', 'SteeringQueue.lastInjectedAt is not a parseable ISO-8601 timestamp');
      }
    }
    return SteeringQueue._(
      id: idRaw,
      pending: List.unmodifiable(messages),
      processedCount: processedRaw,
      lastInjectedAt: lastInjectedAt,
    );
  }

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
