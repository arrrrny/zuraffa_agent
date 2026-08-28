// Spec 076 — agent memory persistence: 010-style file-backed stores.
//
// RED phase: written BEFORE the implementation exists. The library
// lib/src/engine/persistent_agent_memory.dart does not exist yet — this run
// must fail (missing library), proving test-first order.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/engine/agent_memory.dart';
import 'package:zuraffa_agent/src/engine/persistent_agent_memory.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('zuraffa_mem_076_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  MemoryRecord rec(
    String id,
    String content, {
    Set<String> tags = const {},
    double salience = 0.5,
    MemorySource? source,
    DateTime? createdAt,
  }) =>
      MemoryRecord(
        id: id,
        content: content,
        tags: tags,
        source: source ?? MemorySource(agentName: 'test-agent'),
        salience: salience,
        createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
      );

  group('spec 076 — persistence', () {
    test('MemoryJsonCodec round-trips records and links', () {
      final record = rec(
        'r-1',
        'The user prefers concise answers',
        tags: {'preference', 'style'},
        salience: 0.9,
        source: MemorySource(sessionId: 's-9', missionId: 'm-1'),
        createdAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
      );
      // jsonEncode → jsonDecode proves the WIRE format round-trips too.
      final decoded = MemoryJsonCodec.recordFromJson(
          jsonDecode(jsonEncode(MemoryJsonCodec.recordToJson(record)))
              as Map<String, dynamic>);
      expect(decoded, equals(record));

      final link = MemoryLink(
        fromRecordId: 'r-1',
        toRecordId: 'r-2',
        type: MemoryLinkType.supports,
        createdAt: DateTime.utc(2026, 3, 5),
        note: 'observed twice',
      );
      final decodedLink = MemoryJsonCodec.linkFromJson(
          jsonDecode(jsonEncode(MemoryJsonCodec.linkToJson(link)))
              as Map<String, dynamic>);
      expect(decodedLink, equals(link));
    });

    test('PersistentLongTermMemoryStore write-through persists to disk',
        () {
      final file = File('${tmp.path}/long_term.json');
      final store = PersistentLongTermMemoryStore(file: file);
      store.remember(rec('lt-1', 'Dart SDK is 3.11'));
      store.remember(rec('lt-2', 'Zuraffa runs pure Dart'));

      expect(file.existsSync(), isTrue,
          reason: 'write-through must create the file');
      final doc =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(doc['version'], equals(1));
      final records = (doc['records'] as List).cast<Map<String, dynamic>>();
      expect(records, hasLength(2));
      expect(
          MemoryJsonCodec.recordFromJson(records.first).id, equals('lt-1'));
    });

    test('restore round-trips records and links with full fidelity', () {
      final ltFile = File('${tmp.path}/long_term.json');
      final graphFile = File('${tmp.path}/graph.json');
      final original = PersistentLongTermMemoryStore(file: ltFile);
      original.remember(rec(
        'lt-1',
        'The user prefers concise answers',
        tags: {'preference'},
        salience: 0.9,
      ));
      final originalGraph = PersistentMemoryGraph(file: graphFile);
      originalGraph.link('lt-1', 'lt-2', MemoryLinkType.supports,
          note: 'repeated observation');

      // "Restart": fresh instances over the same files.
      final restored = PersistentLongTermMemoryStore(file: ltFile);
      restored.restore();
      final restoredGraph = PersistentMemoryGraph(file: graphFile);
      restoredGraph.restore();

      expect(restored.all, hasLength(1));
      expect(restored.byId('lt-1'),
          equals(original.byId('lt-1'))); // full value equality
      expect(restoredGraph.links, hasLength(1));
      expect(restoredGraph.links.first.type, equals(MemoryLinkType.supports));
      expect(restoredGraph.links.first.note, equals('repeated observation'));
      expect(restoredGraph.links.first.fromRecordId, equals('lt-1'));
    });

    test('same-id replace writes through without duplication', () {
      final file = File('${tmp.path}/long_term.json');
      final store = PersistentLongTermMemoryStore(file: file);
      store.remember(rec('lt-1', 'first version'));
      store.remember(rec('lt-1', 'second version'));

      final doc =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final records = (doc['records'] as List).cast<Map<String, dynamic>>();
      expect(records, hasLength(1), reason: 'replace must not duplicate');
      expect(MemoryJsonCodec.recordFromJson(records.first).content,
          equals('second version'));

      final restored = PersistentLongTermMemoryStore(file: file);
      restored.restore();
      expect(restored.all, hasLength(1));
      expect(restored.byId('lt-1')!.content, equals('second version'));
    });

    test('restore skips malformed entries and fails loud on a corrupt file',
        () {
      final good =
          MemoryJsonCodec.recordFromJson(MemoryJsonCodec.recordToJson(
              rec('g-1', 'good record')));

      // File with two good records and one corrupt entry between them.
      final mixed = <dynamic>[
        MemoryJsonCodec.recordToJson(rec('g-0', 'first good')),
        {'id': 'broken', 'content': 42}, // content must be a String
        MemoryJsonCodec.recordToJson(good),
      ];
      final mixedFile = File('${tmp.path}/mixed.json');
      mixedFile
          .writeAsStringSync(jsonEncode({'version': 1, 'records': mixed}));

      final store = PersistentLongTermMemoryStore(file: mixedFile);
      store.restore();
      expect(store.all, hasLength(2), reason: 'corrupt entry skipped');
      expect(store.byId('g-0'), isNotNull);
      expect(store.byId('g-1'), isNotNull);

      // Wholly unparseable file → loud StateError.
      final corrupt = File('${tmp.path}/corrupt.json');
      corrupt.writeAsStringSync('{this is not json');
      expect(() => PersistentLongTermMemoryStore(file: corrupt).restore(),
          throwsA(isA<StateError>()));
    });

    test('restore on a missing file starts empty', () {
      final store =
          PersistentLongTermMemoryStore(file: File('${tmp.path}/absent.json'));
      store.restore(); // must not throw
      expect(store.all, isEmpty);
    });

    test('PersistentMemoryGraph round-trips links and replaces idempotently',
        () {
      final file = File('${tmp.path}/graph.json');
      final graph = PersistentMemoryGraph(file: file);
      graph.link('a', 'b', MemoryLinkType.supports, note: 'first');
      graph.link('a', 'b', MemoryLinkType.supports, note: 'second');

      final doc =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final links = (doc['links'] as List).cast<Map<String, dynamic>>();
      expect(links, hasLength(1), reason: 'idempotent re-link replaces');
      expect(MemoryJsonCodec.linkFromJson(links.first).note,
          equals('second'));

      final restored = PersistentMemoryGraph(file: file);
      restored.restore();
      expect(restored.links, hasLength(1));
      expect(restored.links.first.note, equals('second'));
      expect(restored.neighborsOf('b'), hasLength(1)); // incoming visible
    });

    test('atomic writes leave no temp files and always-valid JSON', () {
      final file = File('${tmp.path}/long_term.json');
      final store = PersistentLongTermMemoryStore(file: file);
      for (var i = 0; i < 5; i++) {
        store.remember(rec('lt-$i', 'record number $i'));
        // After EVERY mutation: no tmp sibling, file parses.
        expect(File('${file.path}.tmp').existsSync(), isFalse,
            reason: 'tmp must be renamed away immediately (step $i)');
        expect(() => jsonDecode(file.readAsStringSync()), returnsNormally,
            reason: 'snapshot valid after every write (step $i)');
      }
      final tmpSiblings =
          tmp.listSync().where((e) => e.path.endsWith('.tmp')).toList();
      expect(tmpSiblings, isEmpty);
    });

    test('full system persistence — promote survives a restart', () {
      final ltFile = File('${tmp.path}/long_term.json');
      final graphFile = File('${tmp.path}/graph.json');

      // System #1: facade over persistent stores.
      final system = AgentMemorySystem(
        longTerm: PersistentLongTermMemoryStore(file: ltFile),
        graph: PersistentMemoryGraph(file: graphFile),
      );
      system.remember(
          rec('fact-1', 'Zuraffa speaks Dart', salience: 0.8),
          sessionId: null); // long-term
      system.remember(
          rec('note-1', 'Dart SDK 3.11 installed', salience: 0.7),
          sessionId: 'session-1');
      system.link('fact-1', 'note-1', MemoryLinkType.supports);
      system.promote('note-1'); // must persist through the LT store override

      // System #2: rebuilt from the same files — "the restart".
      final restoredSystem = AgentMemorySystem(
        longTerm: PersistentLongTermMemoryStore(file: ltFile)
          ..restore(),
        graph: PersistentMemoryGraph(file: graphFile)..restore(),
      );

      final hits = restoredSystem.recall('Dart');
      expect(hits, hasLength(2), reason: 'both records durable after restart');
      expect(hits.every((h) => h.layer == MemoryLayer.longTerm), isTrue,
          reason: 'the promoted note must have landed in long-term');
      final neighbors = restoredSystem.linked('fact-1');
      expect(neighbors, hasLength(1));
      expect(neighbors.first.$1.type, equals(MemoryLinkType.supports));
      expect(neighbors.first.$2?.id, equals('note-1'));
    });

    test('write-through works for records created with default salience', () {
      final file = File('${tmp.path}/long_term.json');
      final store = PersistentLongTermMemoryStore(file: file);
      store.remember(rec('d-1', 'default salience record'));

      final restored = PersistentLongTermMemoryStore(file: file);
      restored.restore();
      expect(restored.byId('d-1')!.salience, equals(0.5));
      expect(restored.byId('d-1'), equals(store.byId('d-1')));
    });
  });
}
