// Tests for lib/src/llm/retry.dart — Spec 007 (FR-006: retry with exponential
// backoff for 429/5xx). Behaviors U4..U9 — see
// specs/007-llm-provider-clients/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

void main() {
  late LlmHttpRequest request;
  late FakeLlmClock clock;

  setUp(() {
    request = LlmHttpRequest(uri: Uri.parse('https://api.test/v1/chat'));
    clock = FakeLlmClock();
  });

  group('retry policy (U4..U9)', () {
    test('U4: a 429 then success is retried exactly once with one backoff delay', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(statusCode: 429, body: 'rate limited'),
          const ScriptedResponse(statusCode: 200, body: '{"ok":1}'),
        ],
      );

      final response = await sendWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(maxAttempts: 3, baseDelayMs: 100),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"ok":1}');
      expect(transport.requests, hasLength(2));
      expect(clock.sleeps, [100]);
    });

    test('U5: a 5xx then success is retried and succeeds', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(statusCode: 503, body: 'overloaded'),
          const ScriptedResponse(statusCode: 500, body: 'boom'),
          const ScriptedResponse(statusCode: 200, body: '{"ok":2}'),
        ],
      );

      final response = await sendWithRetry(
        transport: transport,
        request: request,
        config: const RetryConfig(maxAttempts: 4, baseDelayMs: 100),
        clock: clock,
        provider: 'openai',
        jitter: (_) => 0,
      );

      expect(response.statusCode, 200);
      expect(transport.requests, hasLength(3));
      expect(clock.sleeps, [100, 200]);
    });

    test('U6: exhausted retries throw the last HTTP error after maxAttempts attempts', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: List.filled(5, const ScriptedResponse(statusCode: 503, body: 'down')),
      );

      await expectLater(
        sendWithRetry(
          transport: transport,
          request: request,
          config: const RetryConfig(maxAttempts: 3, baseDelayMs: 100),
          clock: clock,
          provider: 'openai',
          jitter: (_) => 0,
        ),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having((e) => e.body, 'body', 'down')),
      );
      expect(transport.requests, hasLength(3));
      expect(clock.sleeps, [100, 200]);
    });

    test('U7: a non-retryable 4xx is thrown immediately with zero retries', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(statusCode: 401, body: '{"error":"bad key"}'),
        ],
      );

      await expectLater(
        sendWithRetry(
          transport: transport,
          request: request,
          config: const RetryConfig(maxAttempts: 5, baseDelayMs: 100),
          clock: clock,
          provider: 'openai',
          jitter: (_) => 0,
        ),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
      expect(transport.requests, hasLength(1));
      expect(clock.sleeps, isEmpty);
    });

    test('U8: backoff delays grow exponentially, are capped, and jitter is deterministic', () async {
      // 4 failures then success -> 4 backoff delays: 100, 200, 400, 800.
      Future<List<int>> delays(int Function(int core) jitter) async {
        final transport = FakeLlmTransport(
          provider: 'openai',
          script: [
            ...List.filled(4, const ScriptedResponse(statusCode: 500, body: 'x')),
            const ScriptedResponse(statusCode: 200, body: '{}'),
          ],
        );
        final localClock = FakeLlmClock();
        await sendWithRetry(
          transport: transport,
          request: request,
          config: const RetryConfig(
              maxAttempts: 5, baseDelayMs: 100, maxDelayMs: 250),
          clock: localClock,
          provider: 'openai',
          jitter: jitter,
        );
        return localClock.sleeps;
      }

      // Zero jitter: exponential growth then capped at maxDelayMs.
      expect(await delays((_) => 0), [100, 200, 250, 250]);
      // Deterministic jitter (half the core delay, capped overall).
      expect(await delays((m) => m ~/ 2), [150, 250, 250, 250]);
    });
  });
}
