// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (R2 — state & sessions).
//
// The AgentSession root entity — spec-exact from epic #1 §R2.1:
//   "AgentSession (tree-of-entries, branching — port pi_agent's session
//    tree)"
//
// The repo already ships all the leaf entry types (TurnRecord,
// ToolInvocation, UsageLedger, ModelChangeEntry, BranchSummaryEntry,
// CompactionEntry, LabelEntry, CustomEntry, ThinkingLevelChangeEntry,
// ToolCallSignature). This file is the **root** of that tree: it owns the
// `rootEntryId` (immutable, points at the first entry), the
// `currentEntryId` cursor (mutable, points at the head the engine is
// appending to), and the optional `parentSessionId` (non-null when this
// session is a fork/branch of another, per R2.1 "branching" + R2.2
// "branch/fork/resume first-class").
//
// Declared as a plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner. When zfa ships a session-aware
// generator, this file may be regenerated with @Zorphy; until then it is
// the canonical source for the AgentSession surface.
//
// Refined under specs/032-agent-session-root (TDD): the aggregate
// transitions the task names — appendEntry (cursor advance + updatedAt
// stamp) and fork (branch linked via parentSessionId at the current head,
// root-anchor fallback for fresh sessions) — plus the persistence
// contract (toJson/fromJson round-tripping all seven fields with
// absent-never-fabricated optionals and typed ArgumentErrors). The
// scaffold described the cursor advance and the branch link in doc
// comments but shipped no transition API; the refinement closes that gap
// with pure snapshot transitions mirroring CircuitBreaker's style.

/// AgentSession root entity.
///
/// Owns the entry-tree of a single agent run: the immutable `rootEntryId`
/// anchor, the mutable `currentEntryId` cursor that the engine advances as
/// it appends turns, and the optional `parentSessionId` that links this
/// session to its fork parent when it is a branch (R2.2 "branch/fork/resume
/// first-class").
///
/// The leaf entry types themselves (TurnRecord, ToolInvocation, etc.) live
/// in their own entity files; AgentSession only stores their string ids.
/// This keeps the root serialisable without forcing eager loads of the
/// entire tree, and matches pi_agent's session-tree model where the tree
/// is reconstructed on demand by walking entry ids.
class AgentSession {
  /// Unique session id (UUID or equivalent). Required — this is an entity,
  /// not a value object, so identity is mandatory.
  final String id;

  /// Optional parent mission id. Null when this session is the primary run
  /// (no enclosing mission). Non-null when the session is a sub-run inside
  /// a larger mission (e.g. an explore sub-agent dispatched by a parent).
  final String? missionId;

  /// Immutable id of the root entry of the entry tree. Required — every
  /// session has at least a root anchor; the engine appends entries as
  /// children of `currentEntryId` and advances the cursor.
  final String rootEntryId;

  /// Mutable cursor: id of the entry the engine is currently appending
  /// to. Null only when the session has been created but no entries have
  /// been written yet (the engine initialises it to `rootEntryId` on the
  /// first append).
  final String? currentEntryId;

  /// Optional parent session id. Non-null when this session is a fork or
  /// branch of another session (R2.1 "branching" + R2.2
  /// "branch/fork/resume first-class"). Null for the primary session.
  final String? parentSessionId;

  /// When this session was created. Required.
  final DateTime createdAt;

  /// When this session was last updated (cursor advanced, entry appended,
  /// etc.). Initially equal to [createdAt].
  final DateTime updatedAt;

  const AgentSession({
    required this.id,
    required this.rootEntryId,
    required this.createdAt,
    required this.updatedAt,
    this.missionId,
    this.currentEntryId,
    this.parentSessionId,
  });

  /// True when this session is a branch/fork of another session
  /// ([parentSessionId] is non-null).
  bool get isBranch => parentSessionId != null;

  /// True when the session has at least one entry written
  /// ([currentEntryId] is non-null, i.e. the cursor has moved off the
  /// initial null state).
  bool get isHead => currentEntryId != null;

  /// Appends an entry to the session tree: returns a NEW snapshot whose
  /// cursor ([currentEntryId]) points at [entryId] and whose [updatedAt]
  /// is stamped [at] (default: now). The first append moves the cursor
  /// off its initial null state (see [isHead]).
  ///
  /// Pure transition — `this` is never mutated (the aggregate is an
  /// immutable snapshot; the engine owns tree validity and entry
  /// ordering, the root only tracks the cursor). Throws [ArgumentError]
  /// when [entryId] is empty.
  AgentSession appendEntry(String entryId, {DateTime? at}) {
    if (entryId.isEmpty) {
      throw ArgumentError.value(entryId, 'entryId', 'entry id must not be empty');
    }
    final ts = at ?? DateTime.now();
    return AgentSession(
      id: id,
      missionId: missionId,
      rootEntryId: rootEntryId,
      currentEntryId: entryId,
      parentSessionId: parentSessionId,
      createdAt: createdAt,
      updatedAt: ts,
    );
  }

  /// Forks this session at its current head: returns a NEW child session
  /// linked to this one via [AgentSession.parentSessionId] (R2.1
  /// "branching" + R2.2 "branch/fork/resume first-class").
  ///
  /// The child keeps the same entry tree ([rootEntryId] preserved — the
  /// branch grows inside the parent's tree, it does not copy it), starts
  /// its cursor at the fork point (`currentEntryId ?? rootEntryId` — a
  /// fresh session forks at its root anchor), inherits [missionId], and
  /// is stamped [at] (default: now) for both [createdAt] and [updatedAt].
  ///
  /// Pure transition — `this` is never mutated.
  AgentSession fork({required String sessionId, DateTime? at}) {
    final ts = at ?? DateTime.now();
    return AgentSession(
      id: sessionId,
      missionId: missionId,
      rootEntryId: rootEntryId,
      currentEntryId: currentEntryId ?? rootEntryId,
      parentSessionId: id,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  /// Serializes the session root to a JSON map (persistence contract):
  /// `id`, `rootEntryId`, `createdAt`, `updatedAt` always;
  /// `missionId`, `currentEntryId`, `parentSessionId` only when present
  /// (absent-never-fabricated). Timestamps are ISO-8601 strings; a
  /// non-UTC [DateTime] serializes as its UTC instant (the stores keep
  /// instants, not zones).
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'rootEntryId': rootEntryId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (missionId != null) json['missionId'] = missionId;
    if (currentEntryId != null) json['currentEntryId'] = currentEntryId;
    if (parentSessionId != null) json['parentSessionId'] = parentSessionId;
    return json;
  }

  /// Parses an [AgentSession] from its JSON shape (see [toJson]).
  /// Round-trips all seven fields exactly: absent optionals stay null,
  /// timestamps restore as UTC instants. Throws [ArgumentError] naming
  /// the offending key when a required field is missing or ill-typed —
  /// never fabricates a default.
  factory AgentSession.fromJson(Map<String, dynamic> json) {
    String requireString(String key) {
      final value = json[key];
      if (value is! String) {
        throw ArgumentError.value(value, key, 'AgentSession.$key must be a non-null string');
      }
      return value;
    }

    DateTime requireTimestamp(String key) {
      final value = json[key];
      if (value is! String) {
        throw ArgumentError.value(value, key, 'AgentSession.$key must be an ISO-8601 string');
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw ArgumentError.value(value, key, 'AgentSession.$key is not a parseable ISO-8601 timestamp');
      }
      return parsed;
    }

    String? optionalString(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) {
        throw ArgumentError.value(value, key, 'AgentSession.$key must be a string when present');
      }
      return value;
    }

    return AgentSession(
      id: requireString('id'),
      rootEntryId: requireString('rootEntryId'),
      createdAt: requireTimestamp('createdAt'),
      updatedAt: requireTimestamp('updatedAt'),
      missionId: optionalString('missionId'),
      currentEntryId: optionalString('currentEntryId'),
      parentSessionId: optionalString('parentSessionId'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          missionId == other.missionId &&
          rootEntryId == other.rootEntryId &&
          currentEntryId == other.currentEntryId &&
          parentSessionId == other.parentSessionId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        missionId,
        rootEntryId,
        currentEntryId,
        parentSessionId,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'AgentSession(id: $id, missionId: $missionId, rootEntryId: $rootEntryId, '
      'currentEntryId: $currentEntryId, parentSessionId: $parentSessionId, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';
}
