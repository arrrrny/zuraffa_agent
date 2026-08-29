// Spec 080 (issue arrrrny/zuraffa_agent#91) — R1 Agent Message History:
// context assembly & pure transforms. TDD cycle: RED → GREEN →
// MUTATIONS → GATES → verification.md.
//
// Coverage (specs/080-agent-message-history/tdd/test-list.md):
// - Group A (U1–U4):  equality — `==` and `hashCode` over messages +
//   episodicMemories.
// - Group B (U5–U7):  JSON round-trip — `toJson` → `fromJson`
//   produces an equal history.
// - Group C (U8–U9):  truncate preserves memories — pinned by equality,
//   not just list length.
// - Group D (U10–U14): fromJson error paths — every malformed input
//   throws a typed ArgumentError naming the offending key.
// - Group E (U15–U17): purity pin — appendMessages / addMemory /
//   truncate return new values; the receiver is unchanged.
//
// Lives in its own file so spec-010's `agent_message_history_test.dart`
// (U1 of that spec) and spec-041's `agent_message_history_041_test.dart`
// (U4–U8 of that spec) stay byte-identical — their cycle records depend
// on it.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/types.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/llm/agent_message_history.dart';

EpisodicMemory _memory(String id, String goal) => EpisodicMemory(
      id: id,
      summary:
          '<state_snapshot><overall_goal>$goal</overall_goal></state_snapshot>',
      messages: [UserMessage.text('older-$goal')],
    );

void main() {
  const groupName = 'spec 080 — AgentMessageHistory';

  group(groupName, () {
    // ----------------------------------------------------------------
    // Group A — equality (FR-001 / FR-002)
    // ----------------------------------------------------------------
    group('equality', () {
      test('U1: equal histories (same message instances + same memory instances) are ==', () {
        final msg1 = UserMessage.text('hello');
        final msg2 = AssistantMessage.text('hi');
        final mem1 = _memory('snap-1', 'g1');
        final a = AgentMessageHistory(
          messages: [msg1, msg2],
          episodicMemories: [mem1],
        );
        // Same instances in a separate history wrapper.
        final b = AgentMessageHistory(
          messages: [msg1, msg2],
          episodicMemories: [mem1],
        );

        expect(a == b, isTrue);
        expect(b == a, isTrue);
      });

      test('U2: appending a message breaks ==', () {
        final a = AgentMessageHistory(
          messages: [UserMessage.text('hello')],
          episodicMemories: const [],
        );
        final b = AgentMessageHistory(
          messages: [UserMessage.text('hello'), AssistantMessage.text('hi')],
          episodicMemories: const [],
        );

        expect(a == b, isFalse);
        expect(b == a, isFalse);
      });

      test('U3: appending a memory breaks ==', () {
        final a = AgentMessageHistory(
          messages: [UserMessage.text('hello')],
          episodicMemories: const [],
        );
        final b = AgentMessageHistory(
          messages: [UserMessage.text('hello')],
          episodicMemories: [_memory('snap-1', 'g1')],
        );

        expect(a == b, isFalse);
        expect(b == a, isFalse);
      });

      test('U4: hashCode agrees with ==', () {
        final msg = UserMessage.text('x');
        final mem = _memory('s', 'g');
        final a = AgentMessageHistory(
          messages: [msg],
          episodicMemories: [mem],
        );
        final b = AgentMessageHistory(
          messages: [msg],
          episodicMemories: [mem],
        );
        final c = AgentMessageHistory(
          messages: [UserMessage.text('different')],
          episodicMemories: [mem],
        );

        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
        expect(a == c, isFalse);
        // unequal → hashCode MAY collide but the test asserts
        // equality agreement (the only property that must hold).
      });
    });

    // ----------------------------------------------------------------
    // Group B — JSON round-trip (FR-003 / FR-004)
    // ----------------------------------------------------------------
    group('JSON round-trip', () {
      test('U5: toJson → fromJson preserves structural shape (lossless round-trip)', () {
        // Note: AgentMessage subclasses inherit Object identity equality
        // (no == override in scope for this spec), so the round-trip is
        // asserted structurally (counts, roles, content text, memory id)
        // rather than via ==.
        final original = AgentMessageHistory(
          messages: [UserMessage.text('hello'), AssistantMessage.text('hi')],
          episodicMemories: [_memory('snap-1', 'g1')],
        );

        final json = original.toJson();
        final rebuilt = AgentMessageHistory.fromJson(json);

        expect(rebuilt.messages, hasLength(2));
        expect(rebuilt.episodicMemories, hasLength(1));
        // First message is a UserMessage with TextBlock 'hello'.
        final firstMsg = rebuilt.messages[0] as UserMessage;
        expect((firstMsg.content.first as TextBlock).text, 'hello');
        // Second message is an AssistantMessage with TextBlock 'hi'.
        final secondMsg = rebuilt.messages[1] as AssistantMessage;
        expect((secondMsg.content.first as TextBlock).text, 'hi');
        // Memory preserved.
        expect(rebuilt.episodicMemories.first.id, 'snap-1');
        // Summaries still derivable.
        expect(rebuilt.memorySummaries, original.memorySummaries);
      });

      test('U6: empty history round-trips', () {
        const original = AgentMessageHistory();
        final json = original.toJson();
        final rebuilt = AgentMessageHistory.fromJson(json);

        // Both lists empty.
        expect(rebuilt.messages, isEmpty);
        expect(rebuilt.episodicMemories, isEmpty);
        // JSON shape: both keys present, both lists empty.
        expect(json['messages'] as List, isEmpty);
        expect(json['episodicMemories'] as List, isEmpty);
      });

      test('U7: toJson shape has exactly two keys', () {
        const original = AgentMessageHistory();
        final json = original.toJson();

        expect(json.keys.toSet(), {'messages', 'episodicMemories'});
      });
    });

    // ----------------------------------------------------------------
    // Group C — truncate preserves memories — pinned by equality (FR-006)
    // ----------------------------------------------------------------
    group('truncate preserves memories', () {
      test('U8: truncate(N).episodicMemories == receiver.episodicMemories', () {
        final original = AgentMessageHistory(
          messages: [
            UserMessage.text('first'),
            UserMessage.text('second'),
            UserMessage.text('third'),
          ],
          episodicMemories: [_memory('snap-1', 'g1'), _memory('snap-2', 'g2')],
        );

        final truncated = original.truncate(2);

        // Memories survive — pinned by equality, not just length.
        expect(truncated.episodicMemories == original.episodicMemories, isTrue);
        // Active window is truncated.
        expect(truncated.messages, hasLength(2));
      });

      test(
        'U9: truncate(0).episodicMemories == receiver.episodicMemories',
        () {
          final original = AgentMessageHistory(
            messages: [UserMessage.text('first'), UserMessage.text('second')],
            episodicMemories: [_memory('snap-1', 'g1')],
          );

          final truncated = original.truncate(0);

          // Memories survive even when active window is fully evicted.
          expect(truncated.episodicMemories == original.episodicMemories, isTrue);
          expect(truncated.messages, isEmpty);
        },
      );
    });

    // ----------------------------------------------------------------
    // Group D — fromJson error paths (FR-005)
    // ----------------------------------------------------------------
    group('fromJson error paths', () {
      test('U10: missing messages throws ArgumentError naming messages', () {
        const json = <String, dynamic>{
          'episodicMemories': <dynamic>[],
        };

        expect(
          () => AgentMessageHistory.fromJson(json),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.name,
              'name',
              'messages',
            ),
          ),
        );
      });

      test('U11: messages not a list throws ArgumentError naming messages', () {
        const json = <String, dynamic>{
          'messages': 'not a list',
          'episodicMemories': <dynamic>[],
        };

        expect(
          () => AgentMessageHistory.fromJson(json),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.name,
              'name',
              'messages',
            ),
          ),
        );
      });

      test('U12: missing episodicMemories throws ArgumentError naming episodicMemories', () {
        const json = <String, dynamic>{
          'messages': <dynamic>[],
        };

        expect(
          () => AgentMessageHistory.fromJson(json),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.name,
              'name',
              'episodicMemories',
            ),
          ),
        );
      });

      test('U13: malformed inner message (not a Map) throws ArgumentError naming messages[0]', () {
        final json = <String, dynamic>{
          'messages': <dynamic>['not a map'],
          'episodicMemories': <dynamic>[],
        };

        expect(
          () => AgentMessageHistory.fromJson(json),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.name,
              'name',
              contains('messages[0]'),
            ),
          ),
        );
      });

      test(
        'U14: malformed inner memory (missing id) throws ArgumentError naming episodicMemories[0]',
        () {
          final json = <String, dynamic>{
            'messages': <dynamic>[],
            'episodicMemories': <dynamic>[
              <String, dynamic>{
                // missing 'id' — EpisodicMemory.fromJson will throw.
                'summary': 'a summary',
              },
            ],
          };

          expect(
            () => AgentMessageHistory.fromJson(json),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                contains('episodicMemories[0]'),
              ),
            ),
          );
        },
      );
    });

    // ----------------------------------------------------------------
    // Group E — purity pin (FR-007)
    // ----------------------------------------------------------------
    group('purity', () {
      test('U15: appendMessages returns a new value; receiver unchanged', () {
        final original = AgentMessageHistory(
          messages: [UserMessage.text('first')],
          episodicMemories: const [],
        );

        final appended = original.appendMessages([UserMessage.text('second')]);

        expect(appended == original, isFalse);
        expect(original.messages, hasLength(1));
        expect(appended.messages, hasLength(2));
      });

      test('U16: addMemory returns a new value; receiver unchanged', () {
        final original = AgentMessageHistory(
          messages: [UserMessage.text('first')],
          episodicMemories: const [],
        );

        final added = original.addMemory(_memory('snap-1', 'g1'));

        expect(added == original, isFalse);
        expect(original.episodicMemories, isEmpty);
        expect(added.episodicMemories, hasLength(1));
      });

      test('U17: truncate returns a new value; receiver unchanged', () {
        final original = AgentMessageHistory(
          messages: [
            UserMessage.text('first'),
            UserMessage.text('second'),
            UserMessage.text('third'),
          ],
          episodicMemories: const [],
        );

        final truncated = original.truncate(1);

        expect(truncated == original, isFalse);
        expect(original.messages, hasLength(3));
        expect(truncated.messages, hasLength(1));
      });
    });
  });
}
