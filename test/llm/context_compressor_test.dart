// Tests for lib/src/llm/context_compressor.dart — Spec 009 US1/US3.
// Behaviors U3..U11 — see specs/009-context-compression-llm/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/context_compressor.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'fake_llm_client.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'fake_llm_clock.dart';

const fiveSectionSnapshot = '<state_snapshot>\n'
    '  <overall_goal>Ship the auth feature.</overall_goal>\n'
    '  <key_knowledge>OAuth 2.1 with PKCE chosen; token lifetime 15m.</key_knowledge>\n'
    '  <file_system_state>lib/auth.dart created (214 lines); tests pending.</file_system_state>\n'
    '  <recent_actions>Auth spike run; RFC 7636 reviewed.</recent_actions>\n'
    '  <current_plan>Integrate token refresh next.</current_plan>\n'
    '</state_snapshot>';

/// Builds a message list whose estimated tokens exceed [minTokens].
List<AgentMessage> bigHistory({int messages = 100, int charsPerMessage = 400}) =>
    List.generate(
      messages,
      (i) => UserMessage.text(
          'msg-$i: ${'x' * charsPerMessage} Decision: use approach $i.'),
    );

void main() {
  late FakeLlmClock clock;

  setUp(() {
    clock = FakeLlmClock();
  });

  LLMBasedContextCompressor makeCompressor(
    FakeLlmClient client, {
    ContextCompressionSettings settings = const ContextCompressionSettings(),
  }) =>
      LLMBasedContextCompressor(client: client, settings: settings);

  group('LLMBasedContextCompressor (U3..U11)', () {
    test('U3: below tokenThreshold compress() returns an identity result (no LLM call, no memory entry)', () async {
      final client = FakeLlmClient(providerName: 'compressor', outcomes: const []);
      final compressor = makeCompressor(client);

      final result =
          await compressor.compress([UserMessage.text('short history')]);

      expect(result.strategy, CompressionStrategy.none);
      expect(result.snapshot, isEmpty);
      expect(result.preservedMessages, hasLength(1));
      expect(result.compressedMessages, isEmpty);
      expect(result.memory, isNull);
      expect(client.generateCalls, 0);
      expect(compressor.store.entries, isEmpty);
    });

    test('U4: above threshold the LLM is called once; the last keepRecentMessages stay verbatim; older messages are compressed', () async {
      final history = bigHistory(messages: 30, charsPerMessage: 400); // ~3000 tokens > 64000? no ->
      final client = FakeLlmClient(providerName: 'compressor', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: fiveSectionSnapshot)),
      ]);
      final compressor = makeCompressor(
        client,
        settings: const ContextCompressionSettings(
          tokenThreshold: 1000, // ~30*100 tokens > threshold
          keepRecentMessages: 5,
        ),
      );

      final result = await compressor.compress(history);

      expect(client.generateCalls, 1);
      expect(result.strategy, CompressionStrategy.llm);
      expect(result.snapshot, fiveSectionSnapshot);
      expect(result.compressedMessages, hasLength(25));
      expect(result.preservedMessages, hasLength(5));
      // Recent messages preserved verbatim (same values, same order).
      expect(
        result.preservedMessages.map((m) => (m as UserMessage).content.first),
        equals(history
            .sublist(25)
            .map((m) => (m as UserMessage).content.first)
            .toList()),
      );
    });
  });
}
