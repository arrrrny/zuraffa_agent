// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R1 — engine core: steering & follow-up
// queues).
//
// The SteeringMessage value object — spec-exact from epic #1 §R1.3
// (issue #2 body: "Steering & follow-up queues (pi-mono pattern):
// mid-mission user input injected between turns without losing state").
//
// The repo already ships the SteeringInjected lifecycle event
// (lib/src/engine/events/steering_injected.dart, PR #19) that fires when a
// steering message is pulled off the queue and injected into the running
// turn. This file is the atomic unit of mid-mission user input — the
// message that sits in the queue waiting to be drained.
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner, same as AgentSession (PR #50),
// ToolResult (PR #49), and StopPolicy (PR #47).
//
// Refined under specs/033-steering-queue (TDD): the persistence contract —
// toJson/fromJson round-tripping id, content, and injectedAt exactly
// (ISO-8601 timestamp, typed ArgumentError on malformed input) so a
// steering message survives the store boundary between turns.

/// SteeringMessage value object.
///
/// A single piece of mid-mission user input that sits in the
/// [SteeringQueue] waiting to be drained by the engine between turns.
/// The engine pops messages FIFO and emits a `SteeringInjected` event
/// per pop; the message content is appended to the running turn's
/// context as a follow-up user message.
class SteeringMessage {
  /// Unique message id (UUID or equivalent). Required for queue dedup
  /// and for tracing the message through the session tree.
  final String id;

  /// The textual content of the steering input. The engine appends this
  /// as a user-role message to the running turn's context. (Multimodal
  /// parts are a later R2 concern; for now steering is text-only.)
  final String content;

  /// When this message was injected into the queue. Required — used by
  /// the loop to enforce ordering and by the session tree to reconstruct
  /// the steering timeline.
  final DateTime injectedAt;

  const SteeringMessage({
    required this.id,
    required this.content,
    required this.injectedAt,
  });

  /// Serializes to a JSON map: `{id, content, injectedAt}` — all three
  /// fields are required, so none is ever omitted. The timestamp is an
  /// ISO-8601 string (UTC instants round-trip exactly).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'content': content,
        'injectedAt': injectedAt.toIso8601String(),
      };

  /// Parses a [SteeringMessage] from its JSON shape (see [toJson]).
  /// Throws [ArgumentError] naming the offending key when a required
  /// field is missing, ill-typed, or the timestamp is unparseable —
  /// never fabricates a default.
  factory SteeringMessage.fromJson(Map<String, dynamic> json) {
    String requireString(String key) {
      final value = json[key];
      if (value is! String) {
        throw ArgumentError.value(value, key, 'SteeringMessage.$key must be a non-null string');
      }
      return value;
    }

    final injectedRaw = json['injectedAt'];
    if (injectedRaw is! String) {
      throw ArgumentError.value(injectedRaw, 'injectedAt', 'SteeringMessage.injectedAt must be an ISO-8601 string');
    }
    final injectedAt = DateTime.tryParse(injectedRaw);
    if (injectedAt == null) {
      throw ArgumentError.value(injectedRaw, 'injectedAt', 'SteeringMessage.injectedAt is not a parseable ISO-8601 timestamp');
    }

    return SteeringMessage(
      id: requireString('id'),
      content: requireString('content'),
      injectedAt: injectedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SteeringMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          injectedAt == other.injectedAt);

  @override
  int get hashCode => Object.hash(id, content, injectedAt);

  @override
  String toString() =>
      'SteeringMessage(id: $id, content: ${content.length > 40 ? "${content.substring(0, 40)}…" : content}, injectedAt: $injectedAt)';
}
