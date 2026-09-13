// Hand-stepped acceptance subject (spec 112, AC-5): a scripted transport
// that fails once then succeeds must yield exactly one WARNING retry
// record carrying attempt, delay, and the error. Returns the message.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';

class _A5Transport implements LlmTransport {
  int calls = 0;
  @override
  Future<LlmHttpResponse> send(LlmHttpRequest request) async {
    calls++;
    if (calls == 1) {
      throw const LlmNetworkException(provider: 'scripted', cause: 'boom');
    }
    return const LlmHttpResponse(statusCode: 200);
  }

  @override
  Future<LlmStreamResponse> openStream(LlmHttpRequest request) =>
      throw UnimplementedError('A5 exercises the retry path only');
}

class _A5Clock implements LlmClock {
  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(0);
  @override
  Future<void> sleep(int milliseconds) async {}
}

Future<Map<String, Object?>> subject_a5() async {
  ZuraffaLogging.reset();
  final sink = MemoryLogSink();
  ZuraffaLogging.install(level: Level.WARNING, onRecord: sink.add);
  final transport = _A5Transport();
  await sendWithRetry(
    transport: transport,
    request: LlmHttpRequest(uri: Uri.parse('https://a5.test/v1')),
    config: const RetryConfig(maxAttempts: 3, baseDelayMs: 250),
    clock: _A5Clock(),
    provider: 'scripted',
  );
  ZuraffaLogging.reset();
  final warning = sink.firstWhereMessage('retry scheduled');
  return {'calls': transport.calls, 'message': warning?.message ?? ''};
}
