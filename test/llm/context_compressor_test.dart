// Tests for lib/src/llm/context_compressor.dart — Spec 009 US1/US3.
// Behaviors U3..U11 — see specs/009-context-compression-llm/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/context_compressor.dart';
import 'package:zuraffa_agent/src/compaction.dart' show estimateContextTokens;
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
          'msg-$i: ${'x' * charsPerMessage}\nDecision: use approach $i.'),
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

    test('U5: the compression prompt names the five XML sections and carries the older messages', () async {
      final history = bigHistory(messages: 20, charsPerMessage: 400);
      final client = FakeLlmClient(providerName: 'compressor', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: fiveSectionSnapshot)),
      ]);
      final compressor = makeCompressor(
        client,
        settings: const ContextCompressionSettings(
            tokenThreshold: 500, keepRecentMessages: 5),
      );

      await compressor.compress(history);

      final request = client.requests.single;
      // The system prompt demands the exact five-section XML contract.
      expect(request.systemPrompt, contains('<overall_goal>'));
      expect(request.systemPrompt, contains('<key_knowledge>'));
      expect(request.systemPrompt, contains('<file_system_state>'));
      expect(request.systemPrompt, contains('<recent_actions>'));
      expect(request.systemPrompt, contains('<current_plan>'));
      // The older messages are the conversation payload (15 of 20).
      expect(request.messages, hasLength(15));
      expect(request.messages.first, same(history.first));
    });

    test('U6: an invalid XML snapshot (missing sections) falls back to the heuristic summarizer', () async {
      final history = bigHistory(messages: 20, charsPerMessage: 400);
      final client = FakeLlmClient(providerName: 'compressor', outcomes: [
        const ScriptedOutcome(
            response: LlmResponse(content: 'sure, here is a summary without xml')),
      ]);
      final compressor = makeCompressor(
        client,
        settings: const ContextCompressionSettings(
            tokenThreshold: 500, keepRecentMessages: 5),
      );

      final result = await compressor.compress(history);

      expect(result.strategy, CompressionStrategy.heuristic);
      // Heuristic fallback still produces the five-section XML shape.
      expect(result.snapshot, contains('<state_snapshot>'));
      expect(result.snapshot, contains('<overall_goal>'));
      expect(result.snapshot, contains('<current_plan>'));
      expect(result.compressedMessages, hasLength(15));
      expect(result.preservedMessages, hasLength(5));
    });

    test('U7: an LLM error falls back to the heuristic summarizer (SC-003)', () async {
      final history = bigHistory(messages: 20, charsPerMessage: 400);
      final client = FakeLlmClient(providerName: 'compressor', outcomes: [
        const ScriptedOutcome(
            error: LlmHttpException(
                provider: 'compressor', statusCode: 503, body: 'down')),
      ]);
      final compressor = makeCompressor(
        client,
        settings: const ContextCompressionSettings(
            tokenThreshold: 500, keepRecentMessages: 5),
      );

      final result = await compressor.compress(history);

      expect(result.strategy, CompressionStrategy.heuristic);
      expect(result.snapshot, contains('<state_snapshot>'));
      expect(result.preservedMessages, hasLength(5));
      // The heuristic path extracts Decision lines from the cut messages.
      expect(result.snapshot, contains('use approach'));
      // The LLM was attempted (and only once).
      expect(client.generateCalls, 1);
    });

    test('U8: compression creates an EpisodicMemory entry (snapshot + originals) retrievable from the store', () async {
      final history = bigHistory(messages: 20, charsPerMessage: 400);
      final client = FakeLlmClient(providerName: 'compressor', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: fiveSectionSnapshot)),
      ]);
      final compressor = makeCompressor(
        client,
        settings: const ContextCompressionSettings(
            tokenThreshold: 500, keepRecentMessages: 5),
      );

      final result = await compressor.compress(history);

      final memory = result.memory;
      expect(memory, isNotNull);
      expect(memory!.summary, fiveSectionSnapshot);
      expect(memory.messages, hasLength(15));

      // The entry is in the store and retrievable with its originals.
      expect(compressor.store.entries, hasLength(1));
      final retrieved = compressor.store.retrieve(memory.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.summary, fiveSectionSnapshot);
      expect(retrieved.messages, hasLength(15));
    });

    test('U9: a 100-message conversation compresses to <3000 total tokens (SC-001)', () async {
      final history = bigHistory(messages: 100, charsPerMessage: 400);
      final client = FakeLlmClient(providerName: 'compressor', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: fiveSectionSnapshot)),
      ]);
      final compressor = makeCompressor(
        client,
        settings: const ContextCompressionSettings(
            tokenThreshold: 5000, keepRecentMessages: 10),
      );

      final result = await compressor.compress(history);

      final snapshotTokens = (result.snapshot.length / 4).ceil();
      final preservedTokens = estimateContextTokens(result.preservedMessages);
      expect(snapshotTokens + preservedTokens, lessThan(3000));
      expect(result.compressedMessages, hasLength(90));
      expect(result.preservedMessages, hasLength(10));
    });
  });
}
