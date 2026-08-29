// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 076 — agent memory persistence: 010-style file-backed stores.
//
// Follows the spec 010 PersistentEpisodicMemoryStore precedent: a store
// SUBCLASS mirrors every mutation into a backing store and rebuilds via an
// explicit restore(). The backing store here is a JSON file on local disk,
// written atomically (write *.tmp, then rename over the target) so a crash
// mid-write can never tear the snapshot (FR-007).
//
// Restore semantics (FR-004, 010 precedent): a malformed INDIVIDUAL entry
// is skipped — one corrupt record must not lose the remaining memories.
// A wholly unparseable file fails loud with StateError: external damage is
// not silently swallowed.
//
// Deliberately NOT persisted: SessionMemoryStore — the evaporating layer
// (spec 073 contract, FR-009). Durability is earned by promotion; the
// facade's promote() routes through LongTermMemoryStore.remember, so the
// override below fires and promotions persist for free (FR-008).
//
// Design note (shadowing in PersistentMemoryGraph): the base
// MemoryGraph.link() stamps createdAt with DateTime.now() internally, so
// replaying restored links through super.link() would lose the persisted
// timestamps. The subclass therefore owns its link list and shadows the
// read paths (links / neighborsOf / linksOf) to preserve full fidelity;
// base semantics are replicated exactly in the override. The long-term
// store needs no shadowing — remember() is its only mutation, so
// super-delegation round-trips cleanly.

import 'dart:convert';
import 'dart:io';

import 'agent_memory.dart';

/// JSON codec for the memory value objects (FR-001).
///
/// Stateless and static: the domain objects in agent_memory.dart stay pure
/// (no toJson/fromJson on them) — serialization is a persistence concern
/// and lives here, beside its only consumer.
class MemoryJsonCodec {
  static Map<String, dynamic> recordToJson(MemoryRecord record) => {
        'id': record.id,
        'content': record.content,
        'tags': record.tags.toList()..sort(),
        'source': {
          if (record.source.sessionId != null)
            'sessionId': record.source.sessionId,
          if (record.source.missionId != null)
            'missionId': record.source.missionId,
          if (record.source.agentName != null)
            'agentName': record.source.agentName,
        },
        'createdAt': record.createdAt.toIso8601String(),
        'salience': record.salience,
      };

  /// Decodes one record. Throws [FormatException] / [TypeError] /
  /// [ArgumentError] on malformed input — callers (restore) treat those as
  /// skip-this-entry signals (FR-004).
  static MemoryRecord recordFromJson(Map<String, dynamic> json) {
    final sourceJson = json['source'];
    if (sourceJson is! Map) {
      throw const FormatException('record source must be a map');
    }
    final tagsJson = json['tags'];
    if (tagsJson != null && tagsJson is! List) {
      // Skip the entry rather than silently loading it with its tags lost —
      // a write-through would then make that loss permanent on disk.
      throw const FormatException('record tags must be a list');
    }
    return MemoryRecord(
      id: json['id'] as String,
      content: json['content'] as String,
      tags: {
        if (tagsJson is List)
          for (final tag in tagsJson) tag as String,
      },
      source: MemorySource(
        sessionId: sourceJson['sessionId'] as String?,
        missionId: sourceJson['missionId'] as String?,
        agentName: sourceJson['agentName'] as String?,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      salience: (json['salience'] as num).toDouble(),
    );
  }

  static Map<String, dynamic> linkToJson(MemoryLink link) => {
        'fromRecordId': link.fromRecordId,
        'toRecordId': link.toRecordId,
        'type': link.type.name,
        'createdAt': link.createdAt.toIso8601String(),
        if (link.note != null) 'note': link.note,
      };

  static MemoryLink linkFromJson(Map<String, dynamic> json) => MemoryLink(
        fromRecordId: json['fromRecordId'] as String,
        toRecordId: json['toRecordId'] as String,
        type: MemoryLinkType.values.byName(json['type'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        note: json['note'] as String?,
      );
}

/// Writes [contents] to [file] atomically: land in a `*.tmp` sibling first,
/// then rename over the target (FR-007). Rename-replace is atomic on POSIX
/// and NTFS, so a reader (or a crash) never observes a partial snapshot.
/// The only snapshot format this library reads and writes.
const int _snapshotVersion = 1;

/// Rejects a snapshot written by a different format version. Without this, a
/// future v2 file would load as a silently truncated v1 store — the per-entry
/// skips swallow every unrecognised shape — which is exactly what the loud
/// [StateError] policy exists to prevent.
void _checkVersion(Map<String, dynamic> doc, File file) {
  final version = doc['version'];
  if (version != _snapshotVersion) {
    throw StateError('unsupported memory file version $version '
        '(expected $_snapshotVersion): ${file.path}');
  }
}

void _atomicWrite(File file, String contents) {
  file.parent.createSync(recursive: true);
  final tmp = File('${file.path}.tmp');
  tmp.writeAsStringSync(contents, flush: true);
  tmp.renameSync(file.path);
}

/// A [LongTermMemoryStore] that mirrors every [remember] into a JSON file
/// (write-through, full snapshot) and can rebuild itself via [restore]
/// (FR-002 / FR-003).
///
/// Snapshot format: `{"version":1,"records":[...]}` in insertion order.
/// Same-id replaces land as replacements — a full-snapshot rewrite cannot
/// duplicate (FR-005).
class PersistentLongTermMemoryStore extends LongTermMemoryStore {
  PersistentLongTermMemoryStore({required this.file});

  /// The backing JSON file. Its directory is created on first write.
  final File file;

  @override
  void remember(MemoryRecord record) {
    // In-memory semantics first (super: same-id replace in place).
    super.remember(record);
    _writeThrough();
  }

  void _writeThrough() {
    _atomicWrite(
      file,
      jsonEncode({
        'version': _snapshotVersion,
        'records': [for (final r in all) MemoryJsonCodec.recordToJson(r)],
      }),
    );
  }

  /// Loads the file into the store — the "engine restart" path
  /// (FR-003 / FR-004).
  ///
  /// - Missing file → no-op, no throw (first boot).
  /// - Malformed individual entries → skipped, the rest still load.
  /// - Unparseable whole file, or an unsupported `version` → [StateError]
  ///   (external damage is loud).
  ///
  /// Records are merged into the current in-memory state rather than
  /// replacing it: same-id records are replaced (so repeated calls are
  /// idempotent), but records held in memory and absent from the file
  /// survive. The restart path starts from an empty store, where merge and
  /// rebuild coincide.
  void restore() {
    if (!file.existsSync()) return;
    final Map<String, dynamic> doc;
    try {
      doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException {
      throw StateError('memory file is corrupt (not JSON): ${file.path}');
    } on TypeError {
      throw StateError('memory file is corrupt (not an object): ${file.path}');
    }
    _checkVersion(doc, file);
    final entries = doc['records'];
    if (entries is! List) {
      throw StateError(
          'memory file is corrupt (records is not a list): ${file.path}');
    }
    for (final entry in entries) {
      if (entry is! Map) continue;
      try {
        super.remember(MemoryJsonCodec
            .recordFromJson(Map<String, dynamic>.from(entry)));
      } on FormatException {
        continue; // 010 precedent: one bad entry must not lose the rest.
      } on TypeError {
        continue;
      } on ArgumentError {
        continue;
      }
    }
  }
}

/// A [MemoryGraph] that mirrors every [link] into a JSON file and can
/// rebuild itself via [restore] (FR-006).
///
/// Snapshot format: `{"version":1,"links":[...]}` in insertion order;
/// idempotent re-links land as replacements.
///
/// This subclass SHADOWS the link list (see the file header): the base
/// link() stamps createdAt itself, so replaying restored links through it
/// would lose the persisted timestamps. All read paths are overridden to
/// serve the shadow list; base semantics are replicated exactly.
class PersistentMemoryGraph extends MemoryGraph {
  PersistentMemoryGraph({required this.file});

  /// The backing JSON file. Its directory is created on first write.
  final File file;

  final List<MemoryLink> _links = [];

  @override
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
    _writeThrough();
  }

  void _writeThrough() {
    _atomicWrite(
      file,
      jsonEncode({
        'version': _snapshotVersion,
        'links': [for (final l in _links) MemoryJsonCodec.linkToJson(l)],
      }),
    );
  }

  @override
  List<MemoryLink> get links => List.unmodifiable(_links);

  @override
  List<MemoryLink> neighborsOf(String recordId) => List.unmodifiable([
        for (final l in _links)
          if (l.fromRecordId == recordId || l.toRecordId == recordId) l,
      ]);

  @override
  List<MemoryLink> linksOf(MemoryLinkType type) => List.unmodifiable([
        for (final l in _links)
          if (l.type == type) l,
      ]);

  /// Loads the file into the graph — same semantics as
  /// [PersistentLongTermMemoryStore.restore] (missing file → no-op;
  /// malformed entry → skipped; corrupt file or unsupported `version` →
  /// [StateError]; links merged into current state, re-links replaced).
  void restore() {
    if (!file.existsSync()) return;
    final Map<String, dynamic> doc;
    try {
      doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } on FormatException {
      throw StateError('memory file is corrupt (not JSON): ${file.path}');
    } on TypeError {
      throw StateError('memory file is corrupt (not an object): ${file.path}');
    }
    _checkVersion(doc, file);
    final entries = doc['links'];
    if (entries is! List) {
      throw StateError(
          'memory file is corrupt (links is not a list): ${file.path}');
    }
    for (final entry in entries) {
      if (entry is! Map) continue;
      try {
        final link =
            MemoryJsonCodec.linkFromJson(Map<String, dynamic>.from(entry));
        if (link.fromRecordId == link.toRecordId) continue;
        _links.removeWhere((l) =>
            l.fromRecordId == link.fromRecordId &&
            l.toRecordId == link.toRecordId &&
            l.type == link.type);
        _links.add(link);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      } on ArgumentError {
        continue; // includes unknown link-type names
      }
    }
  }
}
