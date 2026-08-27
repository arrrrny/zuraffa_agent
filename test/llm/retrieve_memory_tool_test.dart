// Tests for lib/src/llm/retrieve_memory_tool.dart — Spec 010 US2 (FR-002, FR-004).
// Behaviors U5-U8 — see specs/010-episodic-memory/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/episodic_memory_store.dart';
import 'package:zuraffa_agent/src/llm/retrieve_memory_tool.dart';
import 'package:zuraffa_agent/src/types.dart';

void main() {
  late EpisodicMemoryStore store;
  late RetrieveMemoryTool tool;

  setUp(() {
    store = EpisodicMemoryStore();
    store.add(EpisodicMemory(
      id: 'snap-001',
      summary: '<state_snapshot><overall_goal>auth</overall_goal></state_snapshot>',
      messages: [
        UserMessage.text('Decide auth.'),
        AssistantMessage.text('Decision: OAuth 2.1.'),
      ],
    ));
    store.add(EpisodicMemory(
      id: 'snap-002',
      summary: '<state_snapshot><overall_goal>storage</overall_goal></state_snapshot>',
      messages: [UserMessage.text('Decide storage.')],
    ));
    store.add(EpisodicMemory(
      id: 'snap-003',
      summary: '<state_snapshot><overall_goal>ui</overall_goal></state_snapshot>',
      messages: [UserMessage.text('Decide UI.')],
    ));
    tool = RetrieveMemoryTool(store: store);
  });

  group('RetrieveMemoryTool (spec 010, U5-U8)', () {
    test('U5: advertises an LlmToolSpec named retrieve_memory with snapshot_id/limit/offset schema', () {
      final spec = tool.spec;
      expect(spec.name, 'retrieve_memory');
      expect(spec.description, isNotEmpty);
      expect(spec.parameters['type'], 'object');
      final props = spec.parameters['properties'] as Map<String, dynamic>;
      expect(props.keys, containsAll(['snapshot_id', 'limit', 'offset']));
      expect((spec.parameters['required'] as List?) ?? const [], isEmpty);
    });

    test('U6: execute with snapshot_id returns that memory with its original messages', () {
      final result = tool.execute({'snapshot_id': 'snap-001'});
      expect(result.found, isTrue);
      expect(result.memory, isNotNull);
      expect(result.memory!.id, 'snap-001');
      expect(result.memory!.summary, contains('auth'));
      expect(result.memory!.messages, hasLength(2));
      expect(result.memory!.messages.first, isA<UserMessage>());
      expect(result.error, isNull);
    });

    test('U7: execute with limit/offset returns a paginated summary listing (no full originals)', () {
      final page1 = tool.execute({'limit': 2});
      expect(page1.found, isTrue);
      expect(page1.listing, isNotNull);
      expect(page1.listing!.map((m) => m.id).toList(), ['snap-001', 'snap-002']);
      // The listing carries summaries + counts, not the full original messages.
      final counts = page1.listing!.map((m) => m.messageCount).toList();
      expect(counts, [2, 1]);
      expect(page1.memory, isNull);

      final page2 = tool.execute({'limit': 2, 'offset': 2});
      expect(page2.listing!.map((m) => m.id).toList(), ['snap-003']);

      final beyond = tool.execute({'limit': 2, 'offset': 99});
      expect(beyond.found, isTrue);
      expect(beyond.listing, isEmpty);
    });

    test('U8: execute with an unknown snapshot_id returns a typed not-found error result', () {
      final result = tool.execute({'snapshot_id': 'missing-snap'});
      expect(result.found, isFalse);
      expect(result.memory, isNull);
      expect(result.listing, isNull);
      expect(result.error, isNotNull);
      expect(result.error!.code, RetrieveMemoryErrorCode.notFound);
      expect(result.error!.message, contains('missing-snap'));
    });
  });
}
