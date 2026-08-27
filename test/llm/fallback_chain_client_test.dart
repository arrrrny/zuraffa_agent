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

    test('U13: all providers failing throws a chain-exhausted error carrying every provider error', () async {
      final a = FakeLlmClient(providerName: 'a', outcomes: [
        const ScriptedOutcome(
            error: LlmNetworkException(provider: 'a', cause: 'refused')),
        const ScriptedOutcome(
            error: LlmNetworkException(provider: 'a', cause: 'refused again')),
      ]);
      final b = FakeLlmClient(providerName: 'b', outcomes: [
        const ScriptedOutcome(
            error: LlmHttpException(
                provider: 'b', statusCode: 503, body: 'down')),
      ]);
      final chain = makeChain([a, b]);

      await expectLater(
        chain.generate(LlmRequest(messages: [UserMessage.text('hi')])),
        throwsA(isA<LlmFallbackExhaustedException>()
            .having((e) => e.errorsByProvider.keys.toList(), 'providers',
                ['a', 'b'])
            .having((e) => e.errorsByProvider['a'], 'error-a',
                isA<LlmNetworkException>())
            .having((e) => e.errorsByProvider['b'], 'error-b',
                isA<LlmHttpException>())),
      );
      expect(a.generateCalls, 1);
      expect(b.generateCalls, 1);
    });

    test('U14: an open breaker skips its provider entirely (no call reaches it)', () async {
      final a = FakeLlmClient(providerName: 'a', outcomes: [
        // Trips the breaker on its own (maxConsecutiveFailures=1).
        const ScriptedOutcome(
            error: LlmNetworkException(provider: 'a', cause: 'refused')),
        // Would succeed if called again — it must NOT be called.
        const ScriptedOutcome(response: LlmResponse(content: 'a-recovered-early')),
      ]);
      final b = FakeLlmClient(providerName: 'b', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: 'from-b')),
        const ScriptedOutcome(response: LlmResponse(content: 'from-b-again')),
      ]);
      final chain = makeChain([a, b], maxConsecutiveFailures: 1);

      // First call: A fails (trips its breaker), B serves.
      expect(
          (await chain
                  .generate(LlmRequest(messages: [UserMessage.text('x')])))
              .content,
          'from-b');
      expect(a.generateCalls, 1);

      // Second call: A's breaker is open — A is skipped, B serves again.
      expect(
          (await chain
                  .generate(LlmRequest(messages: [UserMessage.text('x')])))
              .content,
          'from-b-again');
      expect(a.generateCalls, 1); // still one call: the open breaker gated it
      expect(b.generateCalls, 2);
    });

    test('U15: after cooldown, a half-open probe routes real traffic back to A on success and CLOSES the breaker', () async {
      // maxConsecutiveFailures=3: after the probe closes the breaker, A must
      // fail three more times before tripping again — which pins the
      // closed-vs-stuck-half-open distinction.
      final a = FakeLlmClient(providerName: 'a', outcomes: [
        const ScriptedOutcome(
            error: LlmNetworkException(provider: 'a', cause: 'refused')),
        const ScriptedOutcome(
            error: LlmNetworkException(provider: 'a', cause: 'refused')),
        const ScriptedOutcome(
            error: LlmNetworkException(provider: 'a', cause: 'refused')),
        const ScriptedOutcome(response: LlmResponse(content: 'a-probe-ok')),
        const ScriptedOutcome(
            error: LlmHttpException(
                provider: 'a', statusCode: 503, body: 'blip')),
        const ScriptedOutcome(response: LlmResponse(content: 'a-steady')),
      ]);
      final b = FakeLlmClient(providerName: 'b', outcomes: [
        const ScriptedOutcome(response: LlmResponse(content: 'b-1')),
        const ScriptedOutcome(response: LlmResponse(content: 'b-2')),
        const ScriptedOutcome(response: LlmResponse(content: 'b-3')),
        const ScriptedOutcome(response: LlmResponse(content: 'b-4')),
        const ScriptedOutcome(response: LlmResponse(content: 'b-5')),
      ]);
      final chain = makeChain([a, b], maxConsecutiveFailures: 3);
      final ask = () => chain.generate(LlmRequest(messages: [UserMessage.text('x')]));

      // Three failures trip A's breaker; B serves all three.
      expect((await ask()).content, 'b-1');
      expect((await ask()).content, 'b-2');
      expect((await ask()).content, 'b-3');
      expect(a.generateCalls, 3);

      // Cooldown elapses -> half-open -> the probe routes back to A.
      await clock.sleep(60000);
      expect((await ask()).content, 'a-probe-ok');

      // One more failure (503) is NOT enough to re-trip a CLOSED breaker:
      // B serves, and the NEXT call must go back to A (not skip it).
      expect((await ask()).content, 'b-4');
      expect((await ask()).content, 'a-steady');
      expect(a.generateCalls, 6);
    });

    test('U16: stream() mid-stream failure on A restarts on B — partial chunks then a complete stream, never silent truncation', () async {
      final a = FakeLlmClient(providerName: 'a', outcomes: [
        ScriptedOutcome(
          chunks: [
            const LlmResponseChunk(content: 'partial-'),
          ],
          streamError:
              const LlmNetworkException(provider: 'a', cause: 'reset'),
        ),
      ]);
      final b = FakeLlmClient(providerName: 'b', outcomes: [
        ScriptedOutcome(
          chunks: [
            const LlmResponseChunk(content: 'full-'),
            const LlmResponseChunk(content: 'answer', isComplete: true),
          ],
        ),
      ]);
      final chain = makeChain([a, b]);

      final chunks = await chain
          .stream(LlmRequest(messages: [UserMessage.text('hi')]))
          .toList();

      // A's partial chunk is preserved, then B's complete stream follows.
      expect(chunks.map((c) => c.content).toList(),
          ['partial-', 'full-', 'answer']);
      expect(chunks.last.isComplete, isTrue);
      expect(a.streamCalls, 1);
      expect(b.streamCalls, 1);
    });
  });
}
