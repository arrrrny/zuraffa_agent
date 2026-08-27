// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.
//

import 'llm_clock.dart';
import 'llm_client.dart';
import 'llm_transport.dart';

bool _isRetryableStatus(int status) => status == 429 || status >= 500;

/// Retry configuration (spec 007 FR-006).
class RetryConfig {
  /// Total attempts including the first try.
  final int maxAttempts;

  /// Backoff base in milliseconds; grows exponentially per attempt.
  final int baseDelayMs;

  /// Upper bound for a single backoff delay.
  final int maxDelayMs;

  const RetryConfig({
    this.maxAttempts = 4,
    this.baseDelayMs = 500,
    this.maxDelayMs = 30000,
  });
}

/// Sends [request] through [transport] honoring the retry policy for
/// 429/5xx/connection failures (spec 007 FR-006).
Future<LlmHttpResponse> sendWithRetry({
  required LlmTransport transport,
  required LlmHttpRequest request,
  required RetryConfig config,
  required LlmClock clock,
  required String provider,
  int Function(int coreDelayMs)? jitter,
}) async {
  var attempt = 0;
  while (true) {
    attempt += 1;
    final LlmHttpResponse response;
    try {
      response = await transport.send(request);
    } on LlmNetworkException {
      if (attempt >= config.maxAttempts) rethrow;
      await clock.sleep(_delayFor(attempt, config, jitter));
      continue;
    }
    if (response.isOk) return response;
    if (!_isRetryableStatus(response.statusCode) ||
        attempt >= config.maxAttempts) {
      throw LlmHttpException(
        provider: provider,
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    }
    await clock.sleep(_delayFor(attempt, config, jitter));
  }
}

int _delayFor(
  int attempt,
  RetryConfig config,
  int Function(int coreDelayMs)? jitter,
) {
  final core = config.baseDelayMs << (attempt - 1);
  final wobble = jitter == null ? 0 : jitter(core);
  return core + wobble;
}
