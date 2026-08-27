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
  });
}
