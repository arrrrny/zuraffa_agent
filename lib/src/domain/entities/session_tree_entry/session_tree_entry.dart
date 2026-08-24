// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// SessionTreeEntry sealed hierarchy value object - spec-exact from epic #1 §R1 (issue #3).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// SessionTreeEntry sealed hierarchy value object.
///
/// Sealed SessionTreeEntry unifying the existing entry types (message / thinking-level-change / model-change / compaction / label / custom). Dispatch by type gives the engine one entry-list walk per turn (epic #1 §R2.1).
class SessionTreeEntry {
  final String id;
  final String sessionId;
  final String? parentEntryId;
  final int createdAt;

  const SessionTreeEntry({
    required this.id,
    required this.sessionId,
    this.parentEntryId,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionTreeEntry &&
          runtimeType == other.runtimeType && id == other.id && sessionId == other.sessionId && parentEntryId == other.parentEntryId && createdAt == other.createdAt);

  @override
  int get hashCode => Object.hash(id, sessionId, parentEntryId, createdAt);

  @override
  String toString() =>
      'SessionTreeEntry(id: $id, sessionId: $sessionId, parentEntryId: $parentEntryId)';
}
