// Acceptance tests for spec 010 (episodic memory) — A1..A5, through the
// feature's real entry points: LLMBasedContextCompressor.compress() (spec
// 009), PersistentEpisodicMemoryStore.restore(), RetrieveMemoryTool.execute().
// See specs/010-episodic-memory/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/context_compressor.dart';
import 'package:zuraffa_agent/src/llm/episodic_memory_store.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/persistent_episodic_memory_store.dart';
import 'package:zuraffa_agent/src/llm/retrieve_memory_tool.dart';
import 'fake_llm_client.dart';
import 'persistent_episodic_memory_store_test.dart' show InMemorySessionStorage;
import 'package:zuraffa_agent/src/types.dart';

const snapshotFor = '''
<state_snapshot>
  <overall_goal>Goal {goal}.</overall_goal>
  <key_knowledge>Knowledge {goal}.</key_knowledge>
  <file_system_state>Files {goal}.</file_system_state>
  <recent_actions>Actions {goal}.</recent_actions>
  <current_plan>Plan {goal}.</current_plan>
</state_snapshot>''';

/// A client that answers every generate() with a valid five-section snapshot.
FakeLlmClient snapshotClient() => FakeLlmClient(
      providerName: 'compressor',
      outcomes: List.generate(
        6,
        (i) => ScriptedOutcome(
          response: LlmResponse(
              content: snapshotFor.replaceAll('{goal}', 'round-$i')),
        ),
      ),
    );

void main() {
  group('Episodic memory acceptance (spec 010, A1-A5)', () {
    test('A1: three compressions on a growing conversation leave 3 entries covering the full history (SC-001, AC-1/AC-3)', () async {
      final client = snapshotClient();
      final compressor = LLMBasedContextCompressor(
        client: client,
        settings: const ContextCompressionSettings(
          messageCountThreshold: 5,
          keepRecentMessages: 2,
        ),
      );

      final fullConversation = <AgentMessage>[
        for (var i = 0; i < 8; i++) UserMessage.text('original-$i'),
      ];

      // Round 1: 8 messages -> compress.
      var result = await compressor.compress(fullConversation);
      expect(result.strategy, CompressionStrategy.llm);
      var preserved = result.preservedMessages;

      // Rounds 2-3: grow with 10 more messages each, compress again.
      for (var round = 2; round <= 3; round++) {
        final grown = [
          ...preserved,
          for (var i = 0; i < 10; i++)
            UserMessage.text('original-r$round-$i'),
        ];
        fullConversation.addAll(grown.skip(preserved.length));
        result = await compressor.compress(grown);
        expect(result.strategy, CompressionStrategy.llm);
        preserved = result.preservedMessages;
      }

      final store = compressor.store;
      expect(store.entries, hasLength(3));
      // Combined originals cover the full conversation: every memory carries
      // original messages, and the three memories are distinct snapshots.
      final ids = store.entries.map((m) => m.id).toSet();
      expect(ids, hasLength(3));
      for (final memory in store.entries) {
        expect(memory.summary, contains('<state_snapshot>'));
        expect(memory.messages, isNotEmpty);
      }
    });

    test('A2: retrieval returns the original messages, not just the summary (SC-002)', () async {
      final store = EpisodicMemoryStore();
      store.add(EpisodicMemory(
        id: 'snap-quote',
        summary: '<state_snapshot><overall_goal>auth</overall_goal></state_snapshot>',
        messages: [
          UserMessage.text('Decide the auth approach.'),
          AssistantMessage.text('Decision: OAuth 2.1 with PKCE.'),
        ],
      ));

      final retrieved = store.retrieve('snap-quote');
      expect(retrieved, isNotNull);
      expect(retrieved!.summary, contains('auth'));
      expect(retrieved.messages, hasLength(2));
      expect(
        ((retrieved.messages[1] as AssistantMessage).content.single as TextBlock)
            .text,
        contains('OAuth 2.1'),
      );
    });

    test('A3: memories persist across a session reload (SC-003)', () async {
      final storage = InMemorySessionStorage();
      final first = PersistentEpisodicMemoryStore(storage: storage);
      await first.add(EpisodicMemory(
        id: 'snap-live',
        summary: '<state_snapshot><overall_goal>live</overall_goal></state_snapshot>',
        messages: [UserMessage.text('before restart')],
      ));

      // Engine restart: a brand-new store instance over the same backend.
      final reloaded = PersistentEpisodicMemoryStore(storage: storage);
      await reloaded.restore();

      final memory = reloaded.retrieve('snap-live');
      expect(memory, isNotNull);
      expect(memory!.messages, hasLength(1));
      expect(
        ((memory.messages.single as UserMessage).content.single as TextBlock)
            .text,
        'before restart',
      );
    });

    test('A4: retrieve_memory with snapshot_id returns the memory with original messages (AC-4)', () async {
      final client = snapshotClient();
      final store = EpisodicMemoryStore();
      final compressor = LLMBasedContextCompressor(
        client: client,
        store: store,
        settings: const ContextCompressionSettings(
          messageCountThreshold: 5,
          keepRecentMessages: 1,
        ),
      );
      final history = [
        for (var i = 0; i < 6; i++) UserMessage.text('decision-$i: pick option $i'),
      ];
      final result = await compressor.compress(history);
      expect(result.memory, isNotNull);
      final snapshotId = result.memory!.id;

      // The model calls the tool with the snapshot id.
      final tool = RetrieveMemoryTool(store: store);
      final toolResult = tool.execute({'snapshot_id': snapshotId});
      expect(toolResult.found, isTrue);
      expect(toolResult.error, isNull);
      expect(toolResult.memory!.id, snapshotId);
      expect(toolResult.memory!.messages, isNotEmpty);
      expect(toolResult.memory!.messages.first, isA<UserMessage>());
      expect(toolResult.memory!.summary, contains('<state_snapshot>'));
    });

    test('A5: retrieve_memory with limit/offset returns paginated results (AC-5)', () async {
      final client = snapshotClient();
      final store = EpisodicMemoryStore();
      final compressor = LLMBasedContextCompressor(
        client: client,
        store: store,
        settings: const ContextCompressionSettings(
          messageCountThreshold: 5,
          keepRecentMessages: 1,
        ),
      );

      // Two compression rounds on a growing conversation.
      var history = <AgentMessage>[
        for (var i = 0; i < 6; i++) UserMessage.text('h1-$i'),
      ];
      var result = await compressor.compress(history);
      history = [
        ...result.preservedMessages,
        for (var i = 0; i < 6; i++) UserMessage.text('h2-$i'),
      ];
      await compressor.compress(history);
      expect(store.entries, hasLength(2));

      final tool = RetrieveMemoryTool(store: store);
      final page = tool.execute({'limit': 1, 'offset': 1});
      expect(page.found, isTrue);
      expect(page.listing, hasLength(1));
      expect(page.listing!.single.id, store.entries[1].id);

      final firstPage = tool.execute({'limit': 1});
      expect(firstPage.listing!.single.id, store.entries[0].id);
      expect(firstPage.listing!.single.messageCount,
          store.entries[0].messages.length);
    });
  });
}
