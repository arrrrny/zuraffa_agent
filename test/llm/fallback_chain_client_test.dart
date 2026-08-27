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

    test('U11: generate() advances on 5xx and on a 429 that exhausted retries; fails fast on other 4xx', () async {
      final chainFiveHundred = makeChain([
        FakeLlmClient(providerName: 'a', outcomes: [
          const ScriptedOutcome(
              error: LlmHttpException(
                  provider: 'a', statusCode: 500, body: 'boom')),
        ]),
        FakeLlmClient(providerName: 'b', outcomes: [
          const ScriptedOutcome(response: LlmResponse(content: 'after-5xx')),
        ]),
      ]);
      expect(
          (await chainFiveHundred
                  .generate(LlmRequest(messages: [UserMessage.text('x')])))
              .content,
          'after-5xx');

      final chainRateLimited = makeChain([
        FakeLlmClient(providerName: 'a', outcomes: [
          const ScriptedOutcome(
              error: LlmHttpException(
                  provider: 'a', statusCode: 429, body: 'slow down')),
        ]),
        FakeLlmClient(providerName: 'b', outcomes: [
          const ScriptedOutcome(response: LlmResponse(content: 'after-429')),
        ]),
      ]);
      expect(
          (await chainRateLimited
                  .generate(LlmRequest(messages: [UserMessage.text('x')])))
              .content,
          'after-429');

      final forbiddenA = FakeLlmClient(providerName: 'a', outcomes: [
        const ScriptedOutcome(
            error: LlmHttpException(
                provider: 'a', statusCode: 403, body: 'forbidden')),
      ]);
      final forbiddenB = FakeLlmClient(providerName: 'b', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: 'never')),
      ]);
      final chainForbidden = makeChain([forbiddenA, forbiddenB]);
      await expectLater(
        chainForbidden.generate(LlmRequest(messages: [UserMessage.text('x')])),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
      // Failed fast: provider B was never called.
      expect(forbiddenB.generateCalls, 0);
    });

    test('U12: generate() advances on context-overflow errors (400 + context-length body)', () async {
      final chain = makeChain([
        FakeLlmClient(providerName: 'a', outcomes: [
          const ScriptedOutcome(
              error: LlmHttpException(
                  provider: 'a',
                  statusCode: 400,
                  body:
                      '{"error":{"message":"This model maximum context length is 8192 tokens"}}')),
        ]),
        FakeLlmClient(providerName: 'b', outcomes: [
          const ScriptedOutcome(response: LlmResponse(content: 'big-context-b')),
        ]),
      ]);

      final response = await chain
          .generate(LlmRequest(messages: [UserMessage.text('huge')]));
      expect(response.content, 'big-context-b');
    });
  });
}
