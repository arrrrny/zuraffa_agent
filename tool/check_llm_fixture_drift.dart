// LLM fixture drift check — issue #128 AC-3 ("CI script that re-fetches
// fixtures from provider docs to detect API drift").
//
// Every recorded provider fixture pins wire-format field names. This script
// re-fetches each provider's CURRENT, machine-readable API reference and
// verifies the pinned keys are still documented:
//
//   openai    — openai-openapi repo (CreateChatCompletionResponse schema)
//   anthropic — anthropic-sdk-python type sources (generated FROM the
//               internal OpenAPI spec, so field names ARE the wire names)
//   gemini    — googleapis generativelanguage v1beta proto
//
// A missing key means the provider renamed/removed a field we pin — time to
// re-record fixtures and refresh snapshots BEFORE the contract tests start
// failing obscurely.
//
// Usage:
//   dart run tool/check_llm_fixture_drift.dart                 # full check
//   dart run tool/check_llm_fixture_drift.dart --report <path> # + JSON file
//   dart run tool/check_llm_fixture_drift.dart --offline       # local only
//
// Exit codes: 0 = no drift, 1 = drift detected or a source was unreachable.
// The nightly workflow runs this NON-BLOCKING (continue-on-error) and
// uploads the report as an artifact.
library;

import 'dart:convert';
import 'dart:io';

/// One provider's drift contract: the wire keys our fixtures/snapshots pin,
/// each verified against a fetched source document.
class _Source {
  final String name;
  final Uri url;
  final List<String> pinnedKeys;

  const _Source(this.name, this.url, this.pinnedKeys);
}

class _Provider {
  final String id;
  final List<_Source> sources;

  const _Provider(this.id, this.sources);
}

final _providers = [
  _Provider('openai', [
    _Source(
      'openai-openapi (CreateChatCompletionResponse)',
      Uri.parse(
        'https://raw.githubusercontent.com/openai/openai-openapi/master/openapi.yaml',
      ),
      [
        // ChatCompletionResponse top-level + the keys our fixtures pin.
        'choices',
        'message',
        'finish_reason',
        'usage',
        'prompt_tokens',
        'completion_tokens',
        'cached_tokens',
        'reasoning_tokens',
      ],
    ),
  ]),
  _Provider('anthropic', [
    _Source(
      'anthropic-sdk-python types/message.py',
      Uri.parse(
        'https://raw.githubusercontent.com/anthropics/anthropic-sdk-python/main/src/anthropic/types/message.py',
      ),
      ['content', 'stop_reason', 'usage', 'role'],
    ),
    _Source(
      'anthropic-sdk-python types/usage.py',
      Uri.parse(
        'https://raw.githubusercontent.com/anthropics/anthropic-sdk-python/main/src/anthropic/types/usage.py',
      ),
      ['input_tokens', 'output_tokens', 'cache_read_input_tokens'],
    ),
  ]),
  _Provider('gemini', [
    _Source(
      'googleapis generativelanguage v1beta proto',
      Uri.parse(
        'https://raw.githubusercontent.com/googleapis/googleapis/master/google/ai/generativelanguage/v1beta/generative_service.proto',
      ),
      [
        // Proto field names are snake_case; the JSON wire names
        // (usageMetadata, promptTokenCount, ...) are the camelCase
        // projections of these — a rename here IS a wire rename.
        'GenerateContentResponse',
        'candidates',
        'usage_metadata',
        'prompt_token_count',
        'candidates_token_count',
        'cached_content_token_count',
        'thoughts_token_count',
      ],
    ),
  ]),
];

/// The raw fixtures each provider directory must still carry (the snapshot
/// tests consume them; drift here is a broken lane, not API drift).
const _requiredFixtures = [
  'generate.json',
  'generate_multimodal.json',
  'stream.sse',
  'error_500.json',
  'rate_limited.json',
];

Future<void> main(List<String> args) async {
  final offline = args.contains('--offline');
  final reportIndex = args.indexOf('--report');
  final reportPath = reportIndex >= 0 && reportIndex + 1 < args.length
      ? args[reportIndex + 1]
      : null;

  final report = <String, dynamic>{
    'checkedAt': DateTime.now().toUtc().toIso8601String(),
    'offline': offline,
    'providers': <String, dynamic>{},
  };
  var drifted = false;

  for (final provider in _providers) {
    stdout.writeln('checking ${provider.id}...');
    final providerReport = <String, dynamic>{
      'sources': <Map<String, dynamic>>[],
      'fixtures': <Map<String, dynamic>>[],
      'drifted': false,
    };

    // 1. Local fixture presence + parseability.
    for (final fixture in _requiredFixtures) {
      final path = 'test/fixtures/llm/${provider.id}/$fixture';
      final file = File(path);
      final exists = file.existsSync();
      var parseable = false;
      if (exists && fixture.endsWith('.json')) {
        try {
          jsonDecode(file.readAsStringSync());
          parseable = true;
        } on FormatException {
          parseable = false;
        }
      } else if (exists) {
        parseable = true; // stream.sse is a line document
      }
      final ok = exists && parseable;
      if (!ok) drifted = true;
      providerReport['fixtures'] = [
        ...providerReport['fixtures'] as List,
        {
          'fixture': fixture,
          'exists': exists,
          'parseable': parseable,
          'ok': ok,
        },
      ];
    }

    // 2. Snapshot siblings must exist (the snapshot lane depends on them).
    for (final snapshot in [
      'generate.expected.json',
      'generate_multimodal.expected.json',
      'stream.expected.json',
    ]) {
      final exists = File(
        'test/fixtures/llm/${provider.id}/$snapshot',
      ).existsSync();
      if (!exists) drifted = true;
      providerReport['fixtures'] = [
        ...providerReport['fixtures'] as List,
        {
          'fixture': snapshot,
          'exists': exists,
          'parseable': exists,
          'ok': exists,
        },
      ];
    }

    // 3. Remote documentation re-fetch (skipped in --offline mode).
    if (!offline) {
      for (final source in provider.sources) {
        stdout.writeln('  fetching ${source.url}');
        final body = await _fetch(source.url);
        final sourceReport = <String, dynamic>{
          'source': source.name,
          'url': source.url.toString(),
          'fetched': body != null,
        };
        if (body == null) {
          // An unreachable doc is a check failure (network blip or the doc
          // moved) — surfaced, never silently ignored.
          drifted = true;
          sourceReport['missingKeys'] = ['<source unreachable>'];
        } else {
          final missing = [
            for (final key in source.pinnedKeys)
              if (!body.contains(key)) key,
          ];
          sourceReport['missingKeys'] = missing;
          if (missing.isNotEmpty) {
            drifted = true;
            stdout.writeln(
              '  DRIFT: keys missing from ${source.name}: $missing',
            );
          } else {
            stdout.writeln('  all ${source.pinnedKeys.length} pinned keys OK');
          }
        }
        providerReport['sources'] = [
          ...providerReport['sources'] as List,
          sourceReport,
        ];
      }
    }

    providerReport['drifted'] = drifted;
    report['providers'][provider.id] = providerReport;
  }

  report['drifted'] = drifted;
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  if (reportPath != null) {
    File(reportPath).writeAsStringSync('$encoded\n');
    stdout.writeln('report written to $reportPath');
  } else {
    stdout.writeln(encoded);
  }

  exit(drifted ? 1 : 0);
}

Future<String?> _fetch(Uri url) async {
  try {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) {
      stdout.writeln('  HTTP ${response.statusCode} from $url');
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    client.close();
    return body;
  } on IOException catch (error) {
    stdout.writeln('  fetch failed: $error');
    return null;
  }
}
