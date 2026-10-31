// Byte-level LLM wire-format snapshot tests — issue #128 AC-3.
//
// Every recorded provider fixture (test/fixtures/llm/<provider>/) is parsed
// by the REAL client (via the scripted transport) and the PARSED result is
// canonically serialized (snapshot_codec.dart) and compared BYTE-FOR-BYTE
// against the `*.expected.json` sibling:
//
//   generate.json            -> generate.expected.json        (LlmResponse)
//   generate_multimodal.json -> generate_multimodal.expected.json
//   stream.sse               -> stream.expected.json          (chunk stream)
//
// Why: the fixtures were previously asserted via deep `expect` — when a
// provider's wire format drifted, the failure was a bare "expected X got Y"
// with nothing to inspect. Now the failure is a byte-level diff report
// naming the first differing byte and line (see snapshot_codec.dart).
//
// Authoring/updating snapshots (maintainers, never CI):
//   ZURAFFA_SNAPSHOT_UPDATE=1 dart test test/snapshot
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/anthropic_client.dart';
import 'package:zuraffa_agent/src/llm/gemini_client.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/openai_compatible_client.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:zuraffa_agent/src/types.dart';

import '../llm/fake_llm_clock.dart';
import '../llm/fake_llm_transport.dart';
import 'snapshot_codec.dart';

const _fixtureRoot = 'test/fixtures/llm';

final _updateMode = Platform.environment['ZURAFFA_SNAPSHOT_UPDATE'] == '1';

/// One provider under snapshot: a client factory wired to scripted
/// transports plus the retry config the snapshots pin (single attempt —
/// snapshots must not depend on retry behavior).
class _ProviderHarness {
  final String id;
  final LlmClient Function(FakeLlmTransport transport) makeClient;

  const _ProviderHarness(this.id, this.makeClient);
}

LlmClient _openai(FakeLlmTransport transport) => OpenAiCompatibleClient(
  transport: transport,
  baseUrl: 'https://api.test/v1',
  model: 'test-model',
  apiKey: 'test-key',
  retryConfig: const RetryConfig(maxAttempts: 1),
  clock: FakeLlmClock(),
);

LlmClient _anthropic(FakeLlmTransport transport) => AnthropicClient(
  transport: transport,
  baseUrl: 'https://api.test/v1',
  model: 'test-model',
  apiKey: 'test-key',
  retryConfig: const RetryConfig(maxAttempts: 1),
  clock: FakeLlmClock(),
);

LlmClient _gemini(FakeLlmTransport transport) => GeminiClient(
  transport: transport,
  baseUrl: 'https://api.test/v1beta',
  model: 'test-model',
  apiKey: 'test-key',
  retryConfig: const RetryConfig(maxAttempts: 1),
  clock: FakeLlmClock(),
);

const _providers = [
  _ProviderHarness('openai', _openai),
  _ProviderHarness('anthropic', _anthropic),
  _ProviderHarness('gemini', _gemini),
];

/// The shared snapshot gate: canonically serialize the parsed response (or
/// assembled chunk stream) and byte-compare it against the `*.expected.json`
/// sibling (or author it in update mode).
Future<void> _expectSnapshot(
  String expectedFile,
  String Function() canonicalize,
) async {
  final actual = canonicalize();
  final expected = File(expectedFile);
  if (_updateMode) {
    await expected.writeAsString('$actual\n');
    // ignore: avoid_print
    print('snapshot updated: $expectedFile');
    return;
  }
  if (!expected.existsSync()) {
    fail(
      'missing snapshot sibling $expectedFile — author it with '
      'ZURAFFA_SNAPSHOT_UPDATE=1 dart test test/snapshot (issue #128)',
    );
  }
  final diff = byteDiff(await expected.readAsString(), actual);
  if (diff != null) {
    fail(
      'parsed LlmResponse no longer matches $expectedFile '
      '(wire format drift)\n$diff',
    );
  }
}

void main() {
  group('LLM wire-format snapshots (parsed vs *.expected.json siblings)', () {
    for (final provider in _providers) {
      group(provider.id, () {
        test('generate.json -> generate.expected.json', () async {
          final raw = await File(
            '$_fixtureRoot/${provider.id}/generate.json',
          ).readAsString();
          final transport = FakeLlmTransport(
            provider: provider.id,
            script: [ScriptedResponse(statusCode: 200, body: raw)],
          );
          final client = provider.makeClient(transport);
          final response = await client.generate(
            LlmRequest(messages: [UserMessage.text('hi')]),
          );
          await _expectSnapshot(
            '$_fixtureRoot/${provider.id}/generate.expected.json',
            () => canonicalResponse(response),
          );
        });

        test(
          'generate_multimodal.json -> generate_multimodal.expected.json',
          () async {
            final raw = await File(
              '$_fixtureRoot/${provider.id}/generate_multimodal.json',
            ).readAsString();
            final transport = FakeLlmTransport(
              provider: provider.id,
              script: [ScriptedResponse(statusCode: 200, body: raw)],
            );
            final client = provider.makeClient(transport);
            final response = await client.generate(
              LlmRequest(messages: [UserMessage.text('describe the image')]),
            );
            await _expectSnapshot(
              '$_fixtureRoot/${provider.id}/generate_multimodal.expected.json',
              () => canonicalResponse(response),
            );
          },
        );

        test(
          'stream.sse -> stream.expected.json (assembled chunk stream)',
          () async {
            final lines = File(
              '$_fixtureRoot/${provider.id}/stream.sse',
            ).readAsLinesSync().where((line) => line.isNotEmpty).toList();
            final transport = FakeLlmTransport(
              provider: provider.id,
              script: [ScriptedResponse(statusCode: 200, lines: lines)],
            );
            final client = provider.makeClient(transport);
            final chunks = await client
                .stream(LlmRequest(messages: [UserMessage.text('hi')]))
                .toList();
            await _expectSnapshot(
              '$_fixtureRoot/${provider.id}/stream.expected.json',
              () => canonicalChunks(chunks),
            );
          },
        );
      });
    }

    test('every provider directory carries the full expected-snapshot set', () {
      for (final provider in _providers) {
        for (final name in [
          'generate.expected.json',
          'generate_multimodal.expected.json',
          'stream.expected.json',
        ]) {
          final file = File('$_fixtureRoot/${provider.id}/$name');
          expect(
            file.existsSync(),
            isTrue,
            reason:
                '${provider.id}/$name missing — author snapshots with '
                'ZURAFFA_SNAPSHOT_UPDATE=1 dart test test/snapshot',
          );
        }
      }
    });
  });
}
