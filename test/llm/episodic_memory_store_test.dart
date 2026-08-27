// Tests for lib/src/llm/episodic_memory_store.dart — Spec 009 US2.
// Behavior U2 — see specs/009-context-compression-llm/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/episodic_memory_store.dart';
import 'package:zuraffa_agent/src/types.dart';

void main() {
  group('EpisodicMemoryStore (U2)', () {
    test('adds, retrieves by id, and searches entries — returning the snapshot with its original messages', () {
      final store = EpisodicMemoryStore();
      expect(store.entries, isEmpty);

      final first = EpisodicMemory(
        id: 'mem_1',
        summary: '<state_snapshot><overall_goal>auth work</overall_goal>'
            '<key_knowledge>OAuth 2.1 chosen</key_knowledge>'
            '<file_system_state>lib/auth.dart</file_system_state>'
            '<recent_actions>spike</recent_actions>'
            '<current_plan>integrate</current_plan></state_snapshot>',
        messages: [
          UserMessage.text('Decide auth.'),
          AssistantMessage.text('Decision: OAuth 2.1.'),
        ],
      );
      final second = EpisodicMemory(
        id: 'mem_2',
        summary: '<state_snapshot><overall_goal>storage work</overall_goal>'
            '<key_knowledge>sqlite chosen</key_knowledge>'
            '<file_system_state>lib/store.dart</file_system_state>'
            '<recent_actions>migrations</recent_actions>'
            '<current_plan>seed</current_plan></state_snapshot>',
        messages: [UserMessage.text('Decide storage.')],
      );

      store.add(first);
      store.add(second);

      // Insertion order preserved.
      expect(store.entries.map((m) => m.id).toList(), ['mem_1', 'mem_2']);

      // Retrieval by id returns the snapshot WITH its original messages.
      final retrieved = store.retrieve('mem_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.summary, contains('OAuth 2.1'));
      expect(retrieved.messages, hasLength(2));
      expect(retrieved.messages.first, isA<UserMessage>());

      // Search matches summaries and returns whole entries.
      final hits = store.search('sqlite');
      expect(hits, hasLength(1));
      expect(hits.single.id, 'mem_2');
      expect(store.search('nomatch'), isEmpty);

      // Unknown id retrieves nothing.
      expect(store.retrieve('missing'), isNull);
    });
  });

  group('EpisodicMemoryStore pagination (spec 010, U2-U4)', () {
    EpisodicMemoryStore seededStore() {
      final store = EpisodicMemoryStore();
      store.add(EpisodicMemory(id: 'mem_1', summary: 's1', messages: const []));
      store.add(EpisodicMemory(id: 'mem_2', summary: 's2', messages: const []));
      store.add(EpisodicMemory(id: 'mem_3', summary: 's3', messages: const []));
      store.add(EpisodicMemory(id: 'mem_4', summary: 's4', messages: const []));
      return store;
    }

    test('U2: list() with no arguments returns all entries in insertion order (oldest first)', () {
      final store = seededStore();
      final all = store.list();
      expect(all.map((m) => m.id).toList(), ['mem_1', 'mem_2', 'mem_3', 'mem_4']);
      // Same contract as entries: unmodifiable view.
      expect(() => all.add(EpisodicMemory(id: 'x', summary: '', messages: const [])),
          throwsUnsupportedError);
    });

    test('U3: limit caps the page; offset skips; limit+offset slices the window', () {
      final store = seededStore();

      expect(store.list(limit: 2).map((m) => m.id).toList(), ['mem_1', 'mem_2']);
      expect(store.list(offset: 2).map((m) => m.id).toList(), ['mem_3', 'mem_4']);
      expect(
        store.list(limit: 2, offset: 1).map((m) => m.id).toList(),
        ['mem_2', 'mem_3'],
      );
      // limit larger than remaining → everything from offset on.
      expect(store.list(limit: 10, offset: 1).map((m) => m.id).toList(),
          ['mem_2', 'mem_3', 'mem_4']);
    });

    test('U4: edge cases — offset beyond end, limit<=0, empty store', () {
      final store = seededStore();
      expect(store.list(offset: 4), isEmpty);
      expect(store.list(offset: 99), isEmpty);
      expect(store.list(limit: 0), isEmpty);
      expect(store.list(limit: -3), isEmpty);
      expect(store.list(limit: 0, offset: 99), isEmpty);

      final empty = EpisodicMemoryStore();
      expect(empty.list(), isEmpty);
      expect(empty.list(limit: 5, offset: 2), isEmpty);
    });
  });
}
