// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// SessionBranch (fork/switch/resume) value object - spec-exact from epic #1 §R1 (issue #3).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// SessionBranch (fork/switch/resume) value object.
///
/// Branching primitive — fork a session at entry N, switch between branches, resume either. Shares ancestry 1..N with the original (epic #1 §R2.2, issue #3 AC1+2).
class SessionBranch {
  final String id;
  final String sessionId;
  final String forkedFromEntryId;
  final int forkedAt;
  final bool isActive;

  const SessionBranch({
    required this.id,
    required this.sessionId,
    required this.forkedFromEntryId,
    required this.forkedAt,
    required this.isActive,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionBranch &&
          runtimeType == other.runtimeType && id == other.id && sessionId == other.sessionId && forkedFromEntryId == other.forkedFromEntryId && forkedAt == other.forkedAt && isActive == other.isActive);

  @override
  int get hashCode => Object.hash(id, sessionId, forkedFromEntryId, forkedAt, isActive);

  @override
  String toString() =>
      'SessionBranch(id: $id, sessionId: $sessionId, forkedFromEntryId: $forkedFromEntryId)';
}
