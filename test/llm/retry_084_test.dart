// Spec 084 — R4 LLM client retry & backoff: transient-error resilience
// (issue #95, parent epic #5).
//
// RED surface (new behavior):
//   T2  Network exhaustion → terminal LlmNetworkException with the original
//       cause, attempts == maxAttempts, toString naming the attempt count.
//   T3  HTTP exhaustion → LlmHttpException with attempts == maxAttempts,
//       exhaustion named in toString, status/body intact.
//   T5  Retry-After: 7200 with maxDelayMs: 250 → sleep exactly 7200000 ms
//       (the 3600s ceiling this spec deletes; unclamped by any bound).
//
// Pins (existing behavior, previously unguarded):
//   T1  One network error then 200 → recovers with one backoff delay [100].
//   T6  Retry-After: 90 with maxDelayMs: 250 → 90000 (directive beats cap).
//   T7  Negative Retry-After → treated as 0.
//   T8  openStreamWithRetry: 429 + Retry-After: 3 then 200 → sleep [3000].
//   T9  Determinism: same script + jitter run twice → identical sleeps.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

const _socketReset = 'SocketException: connection reset';

void main() {
  late LlmHttpRequest request;

  setUp(() {
    request = LlmHttpRequest(uri: Uri.parse('https://api.test/v1/chat'));
  });

  group('spec 084 — network-error path (FR-001, FR-004, FR-005)', () {
    test('T1 (pin): one network error then 200 recovers with one backoff',
        () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(networkError: _socketReset),
          const ScriptedResponse(statusCode: 200, body: '{}'),
        ],
      );

      final resp = await sendWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(
            maxAttempts: 4, baseDelayMs: 100, maxDelayMs: 250),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(resp.statusCode, 200);
      expect(clock.sleeps, [100]);
      expect(transport.requests.length, 2);
    });

    test('T2: network exhaustion → terminal typed error with attempts',
        () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: List.filled(
            3, const ScriptedResponse(networkError: _socketReset)),
      );

      await expectLater(
        sendWithRetry(
          transport: transport,
          request: request,
          config: const RetryConfig(
              maxAttempts: 3, baseDelayMs: 100, maxDelayMs: 250),
          clock: clock,
          provider: 'openai',
          jitter: (_) => 0,
        ),
        throwsA(isA<LlmNetworkException>().having(
            (e) => e.attempts, 'attempts', 3).having(
            (e) => e.cause.toString(), 'cause preserved',
            contains(_socketReset)).having(
            (e) => e.toString(), 'toString names exhaustion',
            contains('after 3 attempts'))),
      );
      // 3 attempts → 2 sleeps between them.
      expect(clock.sleeps, [100, 200]);
      expect(transport.requests.length, 3);
    });

    test('T3: HTTP exhaustion → LlmHttpException with attempts', () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: List.filled(3, const ScriptedResponse(statusCode: 503, body: 'down')),
      );

      await expectLater(
        sendWithRetry(
          transport: transport,
          request: request,
          config: const RetryConfig(
              maxAttempts: 3, baseDelayMs: 100, maxDelayMs: 250),
          clock: clock,
          provider: 'openai',
          jitter: (_) => 0,
        ),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.attempts, 'attempts', 3)
            .having((e) => e.statusCode, 'status preserved', 503)
            .having((e) => e.body, 'body preserved', 'down')
            .having((e) => e.toString(), 'toString names exhaustion',
                contains('after 3 attempts'))),
      );
      expect(clock.sleeps, [100, 200]);
    });
  });

  group('spec 084 — Retry-After unclamped (FR-003)', () {
    test(
        'T5: Retry-After: 7200 with maxDelayMs: 250 → sleep exactly '
        '7200000', () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 429,
            headers: {'retry-after': '7200'},
            body: 'rate limited for two hours',
          ),
          const ScriptedResponse(statusCode: 200, body: '{}'),
        ],
      );

      await sendWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(
            maxAttempts: 3, baseDelayMs: 100, maxDelayMs: 250),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(clock.sleeps, [7200000],
          reason: 'the server directive is honored unclamped — not bounded '
              'by maxDelayMs (250) nor by any fixed ceiling (the old 3600s '
              'cap would have slept 3600000)');
    });

    test('T6 (pin): Retry-After: 90 with maxDelayMs: 250 → 90000', () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 429,
            headers: {'retry-after': '90'},
            body: 'rate limited',
          ),
          const ScriptedResponse(statusCode: 200, body: '{}'),
        ],
      );

      await sendWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(
            maxAttempts: 3, baseDelayMs: 100, maxDelayMs: 250),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(clock.sleeps, [90000]);
    });

    test('T7 (pin): negative Retry-After is treated as 0', () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 429,
            headers: {'retry-after': '-5'},
            body: 'rate limited',
          ),
          const ScriptedResponse(statusCode: 200, body: '{}'),
        ],
      );

      await sendWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(
            maxAttempts: 3, baseDelayMs: 100, maxDelayMs: 250),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(clock.sleeps, [0]);
    });
  });

  group('spec 084 — stream parity + determinism (FR-006, FR-007)', () {
    test('T8 (pin): openStreamWithRetry honors Retry-After on the initial '
        'exchange', () async {
      final clock = FakeLlmClock();
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 429,
            headers: {'retry-after': '3'},
            body: 'rate limited',
          ),
          const ScriptedResponse(statusCode: 200, lines: []),
        ],
      );

      final resp = await openStreamWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(
            maxAttempts: 3, baseDelayMs: 100, maxDelayMs: 250),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(resp.isOk, isTrue);
      expect(clock.sleeps, [3000]);
    });

    test('T9 (pin): identical runs record identical sleep sequences',
        () async {
      Future<List<int>> run() async {
        final clock = FakeLlmClock();
        final transport = FakeLlmTransport(
          provider: 'openai',
          script: [
            ...List.filled(
                4, const ScriptedResponse(statusCode: 500, body: 'x')),
            const ScriptedResponse(statusCode: 200, body: '{}'),
          ],
        );
        await sendWithRetry(
          transport: transport,
          request: request,
          config: const RetryConfig(
              maxAttempts: 5, baseDelayMs: 100, maxDelayMs: 250),
          clock: clock,
          provider: 'openai',
          jitter: (m) => m ~/ 3,
        );
        return clock.sleeps;
      }

      final first = await run();
      final second = await run();
      expect(first, second,
          reason: 'the injected clock makes backoff deterministic');
      // 100+33=133; 200+66=266 → capped at 250; 400+133 → 250; 800+266 → 250.
      expect(first, [133, 250, 250, 250]);
    });
  });
}
