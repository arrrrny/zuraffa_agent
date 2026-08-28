// Tests for the three-layer agent memory (spec 073): long-term store,
// session store, cross-reference graph, and the AgentMemorySystem facade.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/engine/agent_memory.dart';

MemorySource src({String? sessionId, String? missionId, String? agentName}) =>
    MemorySource(sessionId: sessionId, missionId: missionId, agentName: agentName);

MemoryRecord rec(
  String id,
  String content, {
  Set<String> tags = const {},
  MemorySource? source,
  DateTime? createdAt,
  double salience = 0.5,
}) =>
    MemoryRecord(
      id: id,
      content: content,
      tags: tags,
      source: source ?? src(agentName: 'test'),
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
      salience: salience,
    );

void main() {
  group('spec 073 — AgentMemorySystem', () {
    test('value objects carry house semantics and validation', () {
      // MemorySource: at least one field must be set.
      expect(() => MemorySource(), throwsArgumentError);
      final s1 = src(sessionId: 's1', agentName: 'a');
      final s2 = src(sessionId: 's1', agentName: 'a');
      expect(s1 == s2, isTrue);
      expect(s1.hashCode, s2.hashCode);
      expect(s1.toString(), contains('s1'));

      // MemoryRecord equality across all fields; salience bounds; empty
      // content rejected.
      final r1 = rec('m1', 'the user prefers concise answers',
          tags: {'preference'}, salience: 0.9);
      final r2 = rec('m1', 'the user prefers concise answers',
          tags: {'preference'}, salience: 0.9);
      expect(r1 == r2, isTrue);
      expect(r1.hashCode, r2.hashCode);
      expect(r1.toString(), contains('m1'));
      expect(rec('m', 'x') == rec('m', 'y'), isFalse);
      expect(() => rec('m', ''), throwsArgumentError);
      expect(() => rec('m', '   \t '), throwsArgumentError);
      expect(() => rec('m', 'x', salience: 1.5), throwsArgumentError);
      expect(() => rec('m', 'x', salience: -0.1), throwsArgumentError);

      // MemoryLink: direction is meaningful, value semantics hold.
      final l1 = MemoryLink(
        fromRecordId: 'a',
        toRecordId: 'b',
        type: MemoryLinkType.supports,
        createdAt: DateTime.utc(2026, 1, 2),
      );
      final l2 = MemoryLink(
        fromRecordId: 'a',
        toRecordId: 'b',
        type: MemoryLinkType.supports,
        createdAt: DateTime.utc(2026, 1, 2),
      );
      final l3 = MemoryLink(
        fromRecordId: 'b',
        toRecordId: 'a',
        type: MemoryLinkType.supports,
        createdAt: DateTime.utc(2026, 1, 2),
      );
      expect(l1 == l2, isTrue);
      expect(l1.hashCode, l2.hashCode);
      expect(l1 == l3, isFalse, reason: 'a supports b is NOT b supports a');
      expect(l1.toString(), contains('supports'));

      // RecallHit: equality over record + layer.
      final h1 = RecallHit(record: r1, layer: MemoryLayer.longTerm);
      final h2 = RecallHit(record: r2, layer: MemoryLayer.longTerm);
      final h3 = RecallHit(record: r2, layer: MemoryLayer.session);
      expect(h1 == h2, isTrue);
      expect(h1.hashCode, h2.hashCode);
      expect(h1 == h3, isFalse);
      expect(h1.toString(), contains('longTerm'));
    });

    test('LongTermMemoryStore replaces, ranks, and filters', () {
      final store = LongTermMemoryStore();
      final low = rec('lt1', 'kilo serves the openai-compatible api',
          createdAt: DateTime.utc(2026, 1, 1), salience: 0.2);
      final high = rec('lt2', 'KILO is the default provider',
          createdAt: DateTime.utc(2026, 1, 2), salience: 0.9);
      final tagged = rec('lt3', 'provider fallback order documented',
          tags: {'infra', 'providers'},
          createdAt: DateTime.utc(2026, 1, 3),
          salience: 0.5);

      store.remember(low);
      store.remember(high);
      store.remember(tagged);
      expect(store.all, hasLength(3));

      // Same-id replace keeps position.
      store.remember(rec('lt2', 'KILO is the default provider (updated)',
          createdAt: DateTime.utc(2026, 1, 2), salience: 0.9));
      expect(store.all, hasLength(3));
      expect(store.byId('lt2')!.content, contains('updated'));
      expect(store.all[1].id, 'lt2', reason: 'replace keeps position');

      // Search: case-insensitive substring, salience desc, createdAt desc.
      final hits = store.search('kilo');
      expect(hits.map((m) => m.id), ['lt2', 'lt1'],
          reason: 'salience 0.9 before 0.2');
      expect(store.search('KILO'), hasLength(2), reason: 'case-insensitive');
      expect(store.search('missing'), isEmpty);
      expect(store.search(''), isEmpty);

      // Tie on salience → createdAt desc decides.
      final tie = LongTermMemoryStore();
      tie.remember(rec('t1', 'alpha note', createdAt: DateTime.utc(2026, 1, 1)));
      tie.remember(rec('t2', 'note alpha', createdAt: DateTime.utc(2026, 1, 5)));
      expect(tie.search('alpha').map((m) => m.id), ['t2', 't1']);

      // byTag exact match (case preserved); latest(n) by createdAt desc.
      expect(store.byTag('providers').map((m) => m.id), ['lt3']);
      expect(store.byTag('Providers'), isEmpty, reason: 'exact match');
      expect(store.latest(2).map((m) => m.id), ['lt3', 'lt2']);
      expect(store.contains('lt1'), isTrue);
      expect(store.contains('nope'), isFalse);

      // Unmodifiable view.
      expect(() => store.all.add(rec('x', 'x')), throwsUnsupportedError);
    });

    test('SessionMemoryStore scopes by session with global id uniqueness',
        () {
      final store = SessionMemoryStore();
      final s1note = rec('n1', 'user asked about provider budgets',
          source: src(sessionId: 's1'));
      final s2note = rec('n2', 'the mission failed on timeout',
          source: src(sessionId: 's2'));

      store.remember('s1', s1note);
      store.remember('s2', s2note);
      expect(store.forSession('s1').map((m) => m.id), ['n1']);
      expect(store.forSession('s2').map((m) => m.id), ['n2']);
      expect(store.byId('n2')!.content, contains('timeout'));
      expect(store.contains('n1'), isTrue);

      // Insertion order within a session.
      store.remember('s1', rec('n0', 'first note of s1',
          source: src(sessionId: 's1'), createdAt: DateTime.utc(2025, 12, 31)));
      expect(store.forSession('s1').map((m) => m.id), ['n1', 'n0'],
          reason: 'insertion order, not createdAt order');

      // Global id uniqueness: remembering an existing id under a different
      // session RELOCATES the record.
      store.remember('s2', rec('n1', 'relocated note',
          source: src(sessionId: 's2')));
      expect(store.forSession('s1').map((m) => m.id), ['n0'],
          reason: 'n1 left s1');
      expect(store.forSession('s2').map((m) => m.id), ['n2', 'n1']);
      expect(store.byId('n1')!.content, 'relocated note');

      // Evaporate path.
      store.forgetSession('s1');
      expect(store.forSession('s1'), isEmpty);
      expect(store.contains('n0'), isFalse);

      // remove() used by promote.
      expect(store.remove('n2'), isTrue);
      expect(store.remove('n2'), isFalse, reason: 'already gone');
    });

    test('MemoryGraph traverses both directions and filters by type', () {
      final graph = MemoryGraph();
      graph.link('a', 'b', MemoryLinkType.supports);
      graph.link('c', 'a', MemoryLinkType.contradicts,
          note: 'c refutes a');
      graph.link('a', 'd', MemoryLinkType.derivedFrom);

      // neighborsOf: EITHER endpoint, outgoing flag correct.
      final around = graph.neighborsOf('a');
      expect(around, hasLength(3));
      final outgoing =
          around.where((l) => l.fromRecordId == 'a').toList();
      final incoming =
          around.where((l) => l.fromRecordId != 'a').toList();
      expect(outgoing, hasLength(2));
      expect(incoming, hasLength(1));
      expect(incoming.single.type, MemoryLinkType.contradicts);

      // Standalone graph rejects self-links (unknown ids are the facade's
      // job — see A4).
      expect(() => graph.link('x', 'x', MemoryLinkType.relatesTo),
          throwsArgumentError);

      // Duplicate (from,to,type) replaces — different note, same count.
      graph.link('a', 'b', MemoryLinkType.supports, note: 'replaced');
      expect(graph.links, hasLength(3));
      expect(
        graph.links
            .firstWhere((l) =>
                l.fromRecordId == 'a' && l.toRecordId == 'b')
            .note,
        'replaced',
      );

      // Same pair, DIFFERENT type is a second, legitimate link.
      graph.link('b', 'a', MemoryLinkType.supports);
      expect(graph.links, hasLength(4));

      // Typed filters.
      expect(graph.contradictions(), hasLength(1));
      expect(graph.linksOf(MemoryLinkType.supports), hasLength(2));
      expect(graph.linksOf(MemoryLinkType.supersedes), isEmpty);

      // Unmodifiable view.
      expect(() => graph.links.add(
            MemoryLink(fromRecordId: 'p', toRecordId: 'q',
                type: MemoryLinkType.relatesTo,
                createdAt: DateTime.utc(2026)),
          ), throwsUnsupportedError);
    });

    test('three-layer story: remember, link, recall, promote', () {
      final system = AgentMemorySystem();

      final fact = system.remember(rec('fact-1', 'the user prefers dart',
          tags: {'preference'}, salience: 0.6));
      expect(fact.id, 'fact-1');
      expect(system.longTermMemory.contains('fact-1'), isTrue);

      system.remember(
          rec('note-1', 'user said the dart preference again today',
              source: src(sessionId: 'sess-7'), salience: 0.8),
          sessionId: 'sess-7');
      expect(system.sessionMemory.forSession('sess-7'), hasLength(1));

      // Cross-reference across layers.
      system.link('note-1', 'fact-1', MemoryLinkType.supports,
          note: 'today reinforced the preference');

      // Recall finds BOTH with correct layer attribution.
      final hits = system.recall('dart');
      expect(hits, hasLength(2));
      expect(hits.map((h) => h.layer).toSet(),
          {MemoryLayer.session, MemoryLayer.longTerm});
      expect(
          hits.first.record.id, 'note-1', reason: 'salience 0.8 > 0.6');

      // Promote the session note; the link survives; recall still finds
      // it, now long-term.
      final promoted = system.promote('note-1');
      expect(promoted.id, 'note-1');
      expect(promoted.content, contains('preference again'));
      expect(system.sessionMemory.forSession('sess-7'), isEmpty);
      expect(system.longTermMemory.contains('note-1'), isTrue);

      final after = system.recall('dart');
      expect(after, hasLength(2));
      expect(after.map((h) => h.layer), everyElement(MemoryLayer.longTerm),
          reason: 'promoted note is now long-term');

      final linked = system.linked('note-1');
      expect(linked, hasLength(1));
      final (link, record, layer) = linked.single;
      expect(link.type, MemoryLinkType.supports);
      expect(record!.id, 'fact-1');
      expect(layer, MemoryLayer.longTerm);
    });

    test('recall ranks by salience then recency across both layers', () {
      final system = AgentMemorySystem();
      // Long-term, LOW salience, older.
      system.remember(rec('lt-low', 'rust memory safety matters',
          createdAt: DateTime.utc(2026, 1, 1), salience: 0.2));
      // Session, HIGH salience, newer — must rank FIRST.
      system.remember(
          rec('s-high', 'rust async runtime pitfalls noted',
              source: src(sessionId: 's'),
              createdAt: DateTime.utc(2026, 1, 2),
              salience: 0.9),
          sessionId: 's');
      // Long-term, HIGH salience, newer still — ties broken by createdAt.
      system.remember(rec('lt-high', 'rust borrow checker rules',
          createdAt: DateTime.utc(2026, 1, 3), salience: 0.9));

      final hits = system.recall('rust');
      expect(hits.map((h) => h.record.id), ['lt-high', 's-high', 'lt-low']);
      expect(hits[1].layer, MemoryLayer.session);
      expect(hits[0].layer, MemoryLayer.longTerm);
    });

    test('recall honors the limit and rejects empty queries', () {
      final system = AgentMemorySystem();
      for (var i = 0; i < 5; i++) {
        system.remember(rec('lt-$i', 'memory topic number $i'));
      }
      expect(system.recall('memory', limit: 3), hasLength(3));
      expect(system.recall('memory'), hasLength(5));
      expect(system.recall(''), isEmpty);
      expect(system.recall('   '), isEmpty);
    });

    test('link validates endpoints and stays idempotent', () {
      final system = AgentMemorySystem();
      system.remember(rec('real', 'a real memory'));
      system.remember(rec('note', 'a session note',
          source: src(sessionId: 's')), sessionId: 's');

      expect(() => system.link('real', 'ghost', MemoryLinkType.supports),
          throwsArgumentError);
      expect(() => system.link('ghost', 'real', MemoryLinkType.supports),
          throwsArgumentError);
      expect(() => system.link('real', 'real', MemoryLinkType.relatesTo),
          throwsArgumentError);

      // Re-linking the same (from, to, type) replaces — no throw.
      system.link('real', 'note', MemoryLinkType.supports);
      system.link('real', 'note', MemoryLinkType.supports, note: 'again');
      expect(system.graph.links, hasLength(1));
      expect(system.graph.links.single.note, 'again');
    });

    test('promote moves a session memory into long-term', () {
      final system = AgentMemorySystem();
      final created = DateTime.utc(2025, 6, 15);
      system.remember(
          rec('keep', 'promote me: the deploy script lives in /bin',
              source: src(sessionId: 's9'), createdAt: created, salience: 0.7),
          sessionId: 's9');
      system.remember(rec('stay', 'long-term already',
          createdAt: created, salience: 0.7));

      expect(() => system.promote('ghost'), throwsArgumentError);
      expect(() => system.promote('stay'),
          throwsArgumentError, reason: 'already long-term');

      final promoted = system.promote('keep');
      expect(promoted.createdAt, created, reason: 'createdAt preserved');
      expect(promoted.salience, 0.7);
      expect(system.sessionMemory.forSession('s9'), isEmpty);
      expect(system.longTermMemory.byId('keep')!.content, contains('/bin'));
    });

    test('forgetSession evaporates session memory and leaves honest dangling links',
        () {
      final system = AgentMemorySystem();
      system.remember(rec('fact', 'a durable fact'));
      system.remember(rec('evap', 'a session note that will evaporate',
          source: src(sessionId: 's1')), sessionId: 's1');
      system.link('evap', 'fact', MemoryLinkType.supports);

      system.sessionMemory.forgetSession('s1');

      // The link is still in the graph — the record it points at is gone.
      final linked = system.linked('fact');
      expect(linked, hasLength(1));
      final (link, record, layer) = linked.single;
      expect(link.fromRecordId, 'evap');
      expect(record, isNull, reason: 'dangling link resolves to null');
      expect(layer, isNull);
    });
  });
}
