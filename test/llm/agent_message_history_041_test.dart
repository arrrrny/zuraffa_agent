// Spec 041 (issue arrrrny/zuraffa_agent#3) — AgentMessageHistory
// append/truncate semantics, test-first via /speckit.tdd.run.
//
// Behaviors (specs/041-agent_message/tdd/test-list.md):
// - U4/U5/U6 (FR-004): truncate — last-N retention, memories untouched,
//   error + boundary shapes, immutability.
// - U7/U8 (FR-003/005): appendMessages/addMemory shipped-semantics pins.
//
// Lives in its own file so spec-010's agent_message_history_test.dart stays
// byte-identical (its group covers U1 of that spec).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/types.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/agent_message_history.dart';

EpisodicMemory _memory(String id, String goal) => EpisodicMemory(
      id: id,
      summary: '<state_snapshot><overall_goal>$goal</overall_goal></state_snapshot>',
      messages: [UserMessage.text('older-$goal')],
    );

AgentMessageHistory _threeMessages() => AgentMessageHistory(
      messages: [
        UserMessage.text('first'),
        UserMessage.text('second'),
        UserMessage.text('third'),
      ],
      episodicMemories: [_memory('snap-1', 'goal-1')],
    );

void main() {
  group('spec 041 — AgentMessageHistory.truncate (FR-004)', () {
    test('U4: truncate(2) keeps the LAST two messages; memories survive', () {
      final history = _threeMessages();
      final truncated = history.truncate(2);
      expect(truncated.messages, hasLength(2));
      expect(
        (truncated.messages.first as UserMessage)
            .content
            .first is TextBlock,
        isTrue,
      );
      expect(
        ((truncated.messages.first as UserMessage).content.first as TextBlock)
            .text,
        'second', // oldest ('first') evicted
      );
      expect(
        ((truncated.messages.last as UserMessage).content.first as TextBlock)
            .text,
        'third',
      );
      expect(truncated.episodicMemories, hasLength(1));
      expect(truncated.episodicMemories.first.id, 'snap-1');
      expect(truncated.memorySummaries,
          ['<state_snapshot><overall_goal>goal-1</overall_goal></state_snapshot>']);
    });

    test('U5: truncate(0) empties messages, memories survive', () {
      final truncated = _threeMessages().truncate(0);
      expect(truncated.messages, isEmpty);
      expect(truncated.episodicMemories, hasLength(1));
    });

    test('U5: truncate(-1) throws ArgumentError', () {
      expect(
        () => _threeMessages().truncate(-1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('U5: truncate(n >= length) returns a content-equal history', () {
      final history = _threeMessages();
      final kept = history.truncate(99);
      expect(kept.messages, hasLength(3));
      expect(kept.memorySummaries, history.memorySummaries);
      expect(
        ((kept.messages.first as UserMessage).content.first as TextBlock).text,
        'first',
      );
    });

    test('U6: truncate does not mutate the receiver', () {
      final history = _threeMessages();
      history.truncate(1);
      expect(history.messages, hasLength(3)); // receiver unchanged
      expect(history.episodicMemories, hasLength(1));
    });
  });

  group('spec 041 — AgentMessageHistory shipped-semantics pins', () {
    test('U7 pin: appendMessages appends at the end, memories untouched', () {
      final history = _threeMessages();
      final grown = history.appendMessages([UserMessage.text('fourth')]);
      expect(grown.messages, hasLength(4));
      expect(
        ((grown.messages.last as UserMessage).content.first as TextBlock).text,
        'fourth',
      );
      expect(grown.episodicMemories, same(history.episodicMemories));
      expect(history.messages, hasLength(3)); // immutable
    });

    test('U8 pin: addMemory appends in insertion order', () {
      final history = AgentMessageHistory(
        messages: [UserMessage.text('recent')],
        episodicMemories: [_memory('snap-1', 'first')],
      );
      final grown = history.addMemory(_memory('snap-2', 'second'));
      expect(grown.episodicMemories, hasLength(2));
      expect(grown.episodicMemories.last.id, 'snap-2');
      expect(grown.memorySummaries.last,
          contains('<overall_goal>second</overall_goal>'));
      expect(history.episodicMemories, hasLength(1)); // immutable
    });
  });
}
