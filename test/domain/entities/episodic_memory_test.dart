// Tests for lib/src/domain/entities/episodic_memory/episodic_memory.dart —
// Spec 009 US2. Behavior U1 — see
// specs/009-context-compression-llm/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/episodic_memory/episodic_memory.dart';
import 'package:zuraffa_agent/src/types.dart';

void main() {
  group('EpisodicMemory (U1)', () {
    test('carries id, XML summary, and original messages with JSON round-trip', () {
      final messages = [
        UserMessage.text('We must decide the auth approach.'),
        AssistantMessage.text('Decision: use OAuth 2.1 with PKCE.'),
        UserMessage.text('File state: lib/auth.dart created.'),
      ];
      const snapshot = '<state_snapshot><overall_goal>ship auth</overall_goal>'
          '<key_knowledge>OAuth chosen</key_knowledge>'
          '<file_system_state>lib/auth.dart</file_system_state>'
          '<recent_actions>auth spike</recent_actions>'
          '<current_plan>integrate</current_plan></state_snapshot>';

      final memory = EpisodicMemory(
        id: 'mem_001',
        summary: snapshot,
        messages: messages,
      );

      expect(memory.id, 'mem_001');
      expect(memory.summary, snapshot);
      expect(memory.messages, hasLength(3));
      expect(memory.messages.first, isA<UserMessage>());

      final json = memory.toJson();
      expect(json['id'], 'mem_001');
      expect(json['summary'], snapshot);
      expect(json['messages'], hasLength(3));

      final restored = EpisodicMemory.fromJson(json);
      expect(restored.id, 'mem_001');
      expect(restored.summary, snapshot);
      expect(restored.messages, hasLength(3));
      expect(restored.messages[1], isA<AssistantMessage>());
      // Round-tripped messages preserve content (value semantics).
      final originalText =
          ((messages[1] as AssistantMessage).content.first as TextBlock).text;
      final restoredText = ((restored.messages[1] as AssistantMessage).content
          .first as TextBlock).text;
      expect(restoredText, originalText);
    });
  });
}
