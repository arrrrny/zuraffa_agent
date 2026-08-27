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
}
