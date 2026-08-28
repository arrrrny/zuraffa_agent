// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 073 — agent memory: three layers.
//
// Layer 1 — LongTermMemoryStore: durable, cross-session facts.
// Layer 2 — SessionMemoryStore: session-scoped working memory,
//           evaporating with the session unless promoted.
// Layer 3 — MemoryGraph: typed cross-reference links between records in
//           either layer (supports / contradicts / supersedes /
//           derivedFrom / relatesTo).
//
// AgentMemorySystem composes the three: remember routes by scope, recall
// searches both layers with layer-attributed hits, link/linked manage the
// graph, promote bridges session → long-term.
//
// Relationship to the episodic-memory subsystem (specs 009/010):
// COMPOSES, never replaces. EpisodicMemory is the compression mechanism
// (slices of one conversation restored by retrieve_memory); these layers
// are the curated memory the agent reads and writes deliberately. All
// state is in-memory here — persistence follows the 010
// PersistentEpisodicMemoryStore precedent in a later spec.
//
// Value objects follow the house pattern (plain Dart, ==, hashCode,
// toString — no codegen), consistent with AgentTool / SteeringQueue /
// EngineEvent siblings.

// Value objects -------------------------------------------------------------

/// Where a memory came from — at least one field must be set.
class MemorySource {
  final String? sessionId;
  final String? missionId;
  final String? agentName;

  MemorySource({this.sessionId, this.missionId, this.agentName}) {
    if (sessionId == null && missionId == null && agentName == null) {
      throw ArgumentError.value(
          this, 'source', 'a memory source needs a session, mission, or agent');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorySource &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          missionId == other.missionId &&
          agentName == other.agentName);

  @override
  int get hashCode => Object.hash(sessionId, missionId, agentName);

  @override
  String toString() =>
      'MemorySource(sessionId: $sessionId, missionId: $missionId, '
      'agentName: $agentName)';
}

/// One atomic memory — a fact, a note, a learning. Belongs to exactly one
/// layer at a time (long-term or a session), decided by which store holds
/// it, not by a field on the record.
class MemoryRecord {
  final String id;
  final String content;
  final Set<String> tags;
  final MemorySource source;
  final DateTime createdAt;
  final double salience;

  MemoryRecord({
    required this.id,
    required String content,
    Set<String> tags = const {},
    required this.source,
    DateTime? createdAt,
    double salience = 0.5,
  })  : content = _validatedContent(content),
        tags = Set.unmodifiable(tags),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        salience = _validatedSalience(salience);

  static String _validatedContent(String content) {
    if (content.trim().isEmpty) {
      throw ArgumentError.value(content, 'content', 'must not be empty');
    }
    return content;
  }

  static double _validatedSalience(double salience) {
    if (salience < 0.0 || salience > 1.0) {
      throw ArgumentError.value(salience, 'salience', 'must be within 0.0..1.0');
    }
    return salience;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          _setEq(tags, other.tags) &&
          source == other.source &&
          createdAt == other.createdAt &&
          salience == other.salience);

  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  int get hashCode =>
      Object.hash(id, content, Object.hashAllUnordered(tags), source,
          createdAt, salience);

  @override
  String toString() =>
      'MemoryRecord(id: $id, salience: $salience, tags: ${tags.toList()..sort()}, '
      'content: ${content.length} chars)';
}

/// Typed, directed cross-reference between two memory records.
enum MemoryLinkType {
  /// The from-record adds evidence for the to-record.
  supports,

  /// The from-record refutes the to-record.
  contradicts,

  /// The from-record replaces the (now outdated) to-record.
  supersedes,

  /// The from-record was derived from the to-record.
  derivedFrom,

  /// Loose association — no stronger claim.
  relatesTo,
}

/// One directed edge in the cross-reference graph. Direction is
/// meaningful: `a supports b` is a different link than `b supports a`.
class MemoryLink {
  final String fromRecordId;
  final String toRecordId;
  final MemoryLinkType type;
  final DateTime createdAt;
  final String? note;

  const MemoryLink({
    required this.fromRecordId,
    required this.toRecordId,
    required this.type,
    required this.createdAt,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryLink &&
          runtimeType == other.runtimeType &&
          fromRecordId == other.fromRecordId &&
          toRecordId == other.toRecordId &&
          type == other.type &&
          createdAt == other.createdAt &&
          note == other.note);

  @override
  int get hashCode =>
      Object.hash(fromRecordId, toRecordId, type, createdAt, note);

  @override
  String toString() =>
      'MemoryLink($fromRecordId ${type.name} $toRecordId'
      '${note != null ? ', note: $note' : ''})';
}

/// Which layer a recalled record was found in — attribution, not
/// partition: recall interleaves both layers in one ranking.
enum MemoryLayer { longTerm, session }

/// One search result: the record plus the layer it came from.
class RecallHit {
  final MemoryRecord record;
  final MemoryLayer layer;

  const RecallHit({required this.record, required this.layer});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecallHit &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          layer == other.layer);

  @override
  int get hashCode => Object.hash(record, layer);

  @override
  String toString() =>
      'RecallHit(layer: ${layer.name}, record: ${record.id})';
}

// Layer 1 — long-term store --------------------------------------------------

/// Durable, cross-session memory: facts, knowledge, preferences. Same-id
/// inserts replace in place (insertion order kept).
class LongTermMemoryStore {
  final List<MemoryRecord> _records = [];

  /// Stores a record; a later record with the same id replaces the earlier
  /// one in place.
  void remember(MemoryRecord record) {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _records[index] = record;
    } else {
      _records.add(record);
    }
  }

  /// All records in insertion order.
  List<MemoryRecord> get all => List.unmodifiable(_records);

  MemoryRecord? byId(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool contains(String id) => byId(id) != null;

  /// Case-insensitive substring search over content, ranked by salience
  /// (desc), then createdAt (desc).
  List<MemoryRecord> search(String query) {
    final needle = query.toLowerCase();
    if (needle.trim().isEmpty) return const [];
    return _ranked([
      for (final r in _records)
        if (r.content.toLowerCase().contains(needle)) r,
    ]);
  }

  /// Exact-match tag filter, ranked like [search].
  List<MemoryRecord> byTag(String tag) =>
      _ranked([for (final r in _records) if (r.tags.contains(tag)) r]);

  /// The [n] most recently created records (createdAt desc).
  List<MemoryRecord> latest(int n) {
    final sorted = [..._records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted.take(n));
  }

  static List<MemoryRecord> _ranked(List<MemoryRecord> records) {
    final sorted = [...records]
      ..sort((a, b) {
        final bySalience = b.salience.compareTo(a.salience);
        if (bySalience != 0) return bySalience;
        return b.createdAt.compareTo(a.createdAt);
      });
    return List.unmodifiable(sorted);
  }
}

// Layer 2 — session store ----------------------------------------------------

/// Session-scoped working memory. Records belong to exactly one session;
/// remembering an existing id under a different session RELOCATES the
/// record (record ids are globally unique across this store).
/// `forgetSession` is the evaporate path.
class SessionMemoryStore {
  final Map<String, List<MemoryRecord>> _bySession = {};

  /// Stores [record] under [sessionId]. A record id is globally unique
  /// here: re-remembering an existing id under a different session moves
  /// it there.
  void remember(String sessionId, MemoryRecord record) {
    // Relocate: remove the id from any other session first.
    for (final session in _bySession.keys) {
      _bySession[session]!.removeWhere((r) => r.id == record.id);
    }
    final session = _bySession.putIfAbsent(sessionId, () => []);
    final index = session.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      session[index] = record;
    } else {
      session.add(record);
    }
  }

  /// The session's records in insertion order.
  List<MemoryRecord> forSession(String sessionId) =>
      List.unmodifiable(_bySession[sessionId] ?? const []);

  /// Drops every record of the session — the evaporate path.
  void forgetSession(String sessionId) => _bySession.remove(sessionId);

  /// Finds a record by id across all sessions.
  MemoryRecord? byId(String id) {
    for (final session in _bySession.values) {
      for (final r in session) {
        if (r.id == id) return r;
      }
    }
    return null;
  }

  /// Every record across every session, in session-then-insertion order —
  /// the search surface the facade's recall uses.
  List<MemoryRecord> get all => List.unmodifiable([
        for (final session in _bySession.values) ...session,
      ]);

  bool contains(String id) => byId(id) != null;

  /// Removes a record by id wherever it lives; returns whether anything
  /// was removed (the promote path uses this).
  bool remove(String id) {
    for (final session in _bySession.values) {
      final before = session.length;
      session.removeWhere((r) => r.id == id);
      if (session.length != before) return true;
    }
    return false;
  }
}

// Layer 3 — cross-reference graph ---------------------------------------------

/// The cross-reference graph: typed, directed links between memory record
/// ids. The graph itself only rejects self-links and treats a repeated
/// (from, to, type) as an idempotent replace — endpoint EXISTENCE is the
/// facade's job (it can see both stores; a standalone graph legitimately
/// holds ids it cannot verify).
class MemoryGraph {
  final List<MemoryLink> _links = [];

  /// Adds a directed link. Self-links throw [ArgumentError]; a repeated
  /// (from, to, type) replaces the earlier link (new note/createdAt)
  /// instead of duplicating.
  void link(String fromRecordId, String toRecordId, MemoryLinkType type,
      {String? note}) {
    if (fromRecordId == toRecordId) {
      throw ArgumentError.value(
          fromRecordId, 'fromRecordId', 'a memory cannot link to itself');
    }
    _links.removeWhere((l) =>
        l.fromRecordId == fromRecordId &&
        l.toRecordId == toRecordId &&
        l.type == type);
    _links.add(MemoryLink(
      fromRecordId: fromRecordId,
      toRecordId: toRecordId,
      type: type,
      createdAt: DateTime.now().toUtc(),
      note: note,
    ));
  }

  /// All links, insertion order.
  List<MemoryLink> get links => List.unmodifiable(_links);

  /// Links where [recordId] is EITHER endpoint, in insertion order.
  List<MemoryLink> neighborsOf(String recordId) => List.unmodifiable([
        for (final l in _links)
          if (l.fromRecordId == recordId || l.toRecordId == recordId) l,
      ]);

  /// All links of [type].
  List<MemoryLink> linksOf(MemoryLinkType type) => List.unmodifiable([
        for (final l in _links)
          if (l.type == type) l,
      ]);

  /// All `contradicts` links — the contradiction surface.
  List<MemoryLink> contradictions() => linksOf(MemoryLinkType.contradicts);
}

// Facade ----------------------------------------------------------------------

/// Composes the three memory layers into one system.
///
/// - [remember] with `sessionId: null` writes long-term; with a session id
///   writes session memory.
/// - [recall] searches BOTH stores and returns layer-attributed hits in
///   one ranking (salience desc, createdAt desc).
/// - [link] / [linked] manage the cross-reference graph (the facade
///   validates endpoint existence first — graph integrity).
/// - [promote] moves a session memory into long-term (identity preserved).
class AgentMemorySystem {
  AgentMemorySystem({
    LongTermMemoryStore? longTerm,
    SessionMemoryStore? sessions,
    MemoryGraph? graph,
  })  : longTermMemory = longTerm ?? LongTermMemoryStore(),
        sessionMemory = sessions ?? SessionMemoryStore(),
        graph = graph ?? MemoryGraph();

  final LongTermMemoryStore longTermMemory;
  final SessionMemoryStore sessionMemory;
  final MemoryGraph graph;

  /// Stores [record]: long-term when [sessionId] is null, session memory
  /// otherwise. Returns the stored record.
  ///
  /// Throws [ArgumentError] if [record.id] already exists in the opposite
  /// layer — ids are globally unique across the system so [recall] never
  /// double-counts a record and [promote] never silently overwrites.
  MemoryRecord remember(MemoryRecord record, {String? sessionId}) {
    if (sessionId == null) {
      if (sessionMemory.contains(record.id)) {
        throw ArgumentError.value(record.id, 'record.id',
            'memory id already used in session memory');
      }
      longTermMemory.remember(record);
    } else {
      if (longTermMemory.contains(record.id)) {
        throw ArgumentError.value(record.id, 'record.id',
            'memory id already used in long-term memory');
      }
      sessionMemory.remember(sessionId, record);
    }
    return record;
  }

  /// Searches both layers (case-insensitive substring over content),
  /// ranked by salience desc then createdAt desc, capped by [limit].
  /// The layer is attribution on each hit — both layers interleave in one
  /// ranking.
  List<RecallHit> recall(String query, {int? limit}) {
    final hits = <RecallHit>[
      for (final r in longTermMemory.search(query))
        RecallHit(record: r, layer: MemoryLayer.longTerm),
      for (final r in _searchSession(query))
        RecallHit(record: r, layer: MemoryLayer.session),
    ];
    hits.sort((a, b) {
      final bySalience =
          b.record.salience.compareTo(a.record.salience);
      if (bySalience != 0) return bySalience;
      return b.record.createdAt.compareTo(a.record.createdAt);
    });
    if (limit != null && hits.length > limit) {
      return List.unmodifiable(hits.sublist(0, limit));
    }
    return List.unmodifiable(hits);
  }

  List<MemoryRecord> _searchSession(String query) {
    final needle = query.toLowerCase();
    if (needle.trim().isEmpty) return const [];
    return [
      for (final r in sessionMemory.all)
        if (r.content.toLowerCase().contains(needle)) r,
    ];
  }

  /// Adds a cross-reference link after validating BOTH endpoints exist in
  /// either layer (graph integrity — the graph never dangles from here).
  void link(String fromRecordId, String toRecordId, MemoryLinkType type,
      {String? note}) {
    if (fromRecordId == toRecordId) {
      throw ArgumentError.value(
          fromRecordId, 'fromRecordId', 'a memory cannot link to itself');
    }
    _requireKnown(fromRecordId, 'fromRecordId');
    _requireKnown(toRecordId, 'toRecordId');
    graph.link(fromRecordId, toRecordId, type, note: note);
  }

  void _requireKnown(String id, String paramName) {
    if (!longTermMemory.contains(id) && !sessionMemory.contains(id)) {
      throw ArgumentError.value(
          id, paramName, 'cannot link an unknown memory record');
    }
  }

  /// Neighbors of [recordId] with resolved records: each entry is the
  /// link, the neighbor's record if still alive (null after the record's
  /// session evaporated or it was otherwise removed), and its layer.
  List<(MemoryLink, MemoryRecord?, MemoryLayer?)> linked(String recordId) {
    final results = <(MemoryLink, MemoryRecord?, MemoryLayer?)>[];
    for (final link in graph.neighborsOf(recordId)) {
      final neighborId =
          link.fromRecordId == recordId ? link.toRecordId : link.fromRecordId;
      final record = longTermMemory.byId(neighborId);
      MemoryLayer? layer;
      if (record != null) {
        layer = MemoryLayer.longTerm;
      } else {
        final sessionRecord = sessionMemory.byId(neighborId);
        if (sessionRecord != null) {
          results.add((link, sessionRecord, MemoryLayer.session));
          continue;
        }
      }
      results.add((link, record, layer));
    }
    return List.unmodifiable(results);
  }

  /// Moves a session memory into long-term memory. Identity is preserved
  /// (id, content, createdAt, salience); links survive untouched (the
  /// graph references ids, not stores). Unknown ids and already-long-term
  /// records throw [ArgumentError].
  MemoryRecord promote(String recordId) {
    final sessionRecord = sessionMemory.byId(recordId);
    if (sessionRecord == null) {
      if (longTermMemory.contains(recordId)) {
        throw ArgumentError.value(
            recordId, 'recordId', 'already a long-term memory');
      }
      throw ArgumentError.value(recordId, 'recordId', 'unknown memory record');
    }
    sessionMemory.remove(recordId);
    longTermMemory.remember(sessionRecord);
    return sessionRecord;
  }
}
