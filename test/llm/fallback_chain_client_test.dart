// Tests for lib/src/llm/fallback_chain_client.dart — Spec 008 US1.
// Behaviors U10..U18 — see specs/008-fallback-chain-runtime/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/fallback_chain_client.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'fake_llm_client.dart';
import 'fake_llm_clock.dart';

void main() {
  late FakeLlmClock clock;

  setUp(() {
    clock = FakeLlmClock();
  });

  FallbackChainClient makeChain(List<FakeLlmClient> clients,
          {String policyMode = 'restart', int maxConsecutiveFailures = 3}) =>
      FallbackChainClient(
        providers: [
          for (final c in clients) (id: c.providerName, client: c),
        ],
        policyMode: policyMode,
        maxConsecutiveFailures: maxConsecutiveFailures,
        clock: clock,
      );

  group('FallbackChainClient (U10..U18)', () {
    test('U10: generate() advances to provider B when A fails with a connection error and B serves', () async {
      final a = FakeLlmClient(
        providerName: 'a',
        outcomes: [
          const ScriptedOutcome(
              error: LlmNetworkException(provider: 'a', cause: 'refused')),
        ],
      );
      final b = FakeLlmClient(
        providerName: 'b',
        outcomes: [
          const ScriptedOutcome(response: LlmResponse(content: 'from-b')),
        ],
      );
      final chain = makeChain([a, b]);

      final response = await chain
          .generate(LlmRequest(messages: [UserMessage.text('hi')]));

      expect(response.content, 'from-b');
      expect(a.generateCalls, 1);
      expect(b.generateCalls, 1);
    });
  });
}
