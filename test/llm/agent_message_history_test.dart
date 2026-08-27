import 'package:test/test.dart';
import 'package:zuraffa_agent/src/types.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/agent_message_history.dart';

void main() {
  group('AgentMessageHistory (U1)', () {
    test('U1: carries messages + episodicMemories and exposes memorySummaries in insertion order', () {
      final memories = [
        EpisodicMemory(
          id: 'snap-1',
          summary: '<state_snapshot><overall_goal>first</overall_goal></state_snapshot>',
          messages: [UserMessage.text('older')],
        ),
        EpisodicMemory(
          id: 'snap-2',
          summary: '<state_snapshot><overall_goal>second</overall_goal></state_snapshot>',
          messages: [UserMessage.text('middle')],
        ),
      ];
      final history = AgentMessageHistory(
        messages: [UserMessage.text('recent')],
        episodicMemories: memories,
      );

      expect(history.messages, hasLength(1));
      expect(
        ((history.messages.first as UserMessage).content.first as TextBlock)
            .text,
        'recent',
      );
      expect(history.episodicMemories, hasLength(2));
      expect(history.episodicMemories.first.id, 'snap-1');

      // Summaries are exposed for context building, oldest first, summary-only.
      expect(history.memorySummaries, [
        '<state_snapshot><overall_goal>first</overall_goal></state_snapshot>',
        '<state_snapshot><overall_goal>second</overall_goal></state_snapshot>',
      ]);
    });
  });
}
