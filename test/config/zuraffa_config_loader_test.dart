// spec 107 (issue #121) — ZuraffaConfigLoader: YAML document + environment
// map loaders with spec-104-style diagnostics.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/config/zuraffa_config_loader.dart';

const _fullYaml = '''
provider:
  id: p1
  providerKind: openai
  baseUrl: https://llm.example.internal/api
  models: [internal/model]
  timeoutMs: 30000
agent_spec:
  id: spec-1
  name: research
  toolAllowlist: [search, read_file]
  systemPrompt: Research the topic.
engine_loop:
  id: loop-1
  sessionId: s1
  maxTurns: 8
  wallClockTimeoutMs: 60000
  repetitionThreshold: 5
mcp_transport:
  id: mcp-1
  transportType: sse
  endpoint: https://mcp.example.internal/sse
  authRequired: true
stop_policy:
  id: stop-1
  maxTurns: 16
  wallClockTimeoutMs: 0
  repetitionThreshold: 5
  enabled: true
compaction:
  id: comp-1
  sessionId: s1
  retainEntryIds: []
  summarizeEntryIds: []
  artifactRefs: []
  compactedAt: 0
''';

void main() {
  group('spec 107 — ZuraffaConfigLoader.fromYaml', () {
    test('U6: full document → every section populated', () {
      final config = ZuraffaConfigLoader.fromYaml(_fullYaml);
      expect(config.providerConfig?.id, 'p1');
      expect(
        config.providerConfig?.baseUrl,
        'https://llm.example.internal/api',
      );
      expect(config.providerConfig?.models, ['internal/model']);
      expect(config.providerConfig?.timeoutMs, 30000);
      expect(config.agentSpec?.id, 'spec-1');
      expect(config.agentSpec?.toolAllowlist, ['search', 'read_file']);
      expect(config.engineLoop?.sessionId, 's1');
      expect(config.engineLoop?.maxTurns, 8);
      expect(config.mcpTransport?.endpoint, 'https://mcp.example.internal/sse');
      expect(config.mcpTransport?.authRequired, isTrue);
      expect(config.stopPolicy?.maxTurns, 16);
      expect(config.compactionStrategy?.sessionId, 's1');
      expect(config.validate(), isEmpty);
    });

    test(
      'U7: partial document → only present sections; unknown keys ignored',
      () {
        final config = ZuraffaConfigLoader.fromYaml('''
engine_loop:
  id: loop-1
  sessionId: s1
  maxTurns: 4
  wallClockTimeoutMs: 0
  repetitionThreshold: 0
totally_unknown_section:
  future: true
''');
        expect(config.engineLoop?.maxTurns, 4);
        expect(config.providerConfig, isNull);
        expect(config.agentSpec, isNull);
        expect(config.mcpTransport, isNull);
        expect(config.stopPolicy, isNull);
        expect(config.compactionStrategy, isNull);
      },
    );

    test('U8: wrong-typed known field → ArgumentError naming the field', () {
      expect(
        () => ZuraffaConfigLoader.fromYaml('''
engine_loop:
  id: loop-1
  sessionId: s1
  maxTurns: "eight"
  wallClockTimeoutMs: 0
  repetitionThreshold: 0
'''),
        throwsA(
          predicate(
            (Object e) =>
                e is ArgumentError &&
                e.toString().contains('engine_loop.maxTurns'),
          ),
        ),
      );
    });
  });

  group('spec 107 — ZuraffaConfigLoader.fromEnv', () {
    test('U9: full map → corresponding sections populated', () {
      final config = ZuraffaConfigLoader.fromEnv({
        'ZFA_PROVIDER_BASE_URL': 'https://env.example.internal/api',
        'ZFA_PROVIDER_PROVIDER_KIND': 'openai',
        'ZFA_PROVIDER_MODEL': 'internal/model',
        'ZFA_PROVIDER_TIMEOUT_MS': '45000',
        'ZFA_AGENT_SPEC_ID': 'env-spec',
        'ZFA_AGENT_SPEC_NAME': 'env-agent',
        'ZFA_AGENT_SPEC_SYSTEM_PROMPT': 'Be brief.',
        'ZFA_ENGINE_LOOP_MAX_TURNS': '6',
        'ZFA_ENGINE_LOOP_SESSION_ID': 'env-session',
        'ZFA_MCP_TRANSPORT_ENDPOINT': 'https://mcp.example.internal/sse',
        'ZFA_STOP_POLICY_MAX_TURNS': '12',
      });
      expect(
        config.providerConfig?.baseUrl,
        'https://env.example.internal/api',
      );
      expect(config.providerConfig?.models, ['internal/model']);
      expect(config.providerConfig?.timeoutMs, 45000);
      expect(config.agentSpec?.id, 'env-spec');
      expect(config.engineLoop?.maxTurns, 6);
      expect(config.mcpTransport?.endpoint, 'https://mcp.example.internal/sse');
      expect(config.stopPolicy?.maxTurns, 12);
    });

    test('U10: partial map + unknown vars + unparsable numeric', () {
      final partial = ZuraffaConfigLoader.fromEnv({
        'ZFA_ENGINE_LOOP_MAX_TURNS': '3',
        'ZFA_SOMETHING_ELSE': 'ignored',
        'UNRELATED': 'also ignored',
      });
      expect(partial.engineLoop?.maxTurns, 3);
      expect(partial.providerConfig, isNull);

      expect(
        () => ZuraffaConfigLoader.fromEnv({
          'ZFA_ENGINE_LOOP_MAX_TURNS': 'many',
          'ZFA_ENGINE_LOOP_SESSION_ID': 's1',
          'ZFA_ENGINE_LOOP_WALL_CLOCK_TIMEOUT_MS': '1000',
          'ZFA_ENGINE_LOOP_REPETITION_THRESHOLD': '0',
        }),
        throwsA(
          predicate(
            (Object e) =>
                e is ArgumentError &&
                e.toString().contains('ZFA_ENGINE_LOOP_MAX_TURNS'),
          ),
        ),
      );
    });
  });

  _readmeAcceptance();
}

void _readmeAcceptance() {
  // A1/A3 (SC-001/SC-005): the README's example document is the contract —
  // it must parse, validate clean, and round-trip every field.
  test(
    'A1/A3: the README example document parses and validates clean',
    () async {
      final readme = File('README.md').readAsStringSync();
      expect(readme, contains('## Configuring the engine'));
      final section = readme.split('## Configuring the engine').last;
      final fence = section.indexOf('```yaml');
      expect(fence, greaterThanOrEqualTo(0), reason: 'README example missing');
      final start = section.indexOf('\n', fence) + 1;
      final end = section.indexOf('```', start);
      final example = section.substring(start, end);

      final config = ZuraffaConfigLoader.fromYaml(example);
      expect(config.validate(), isEmpty);
      expect(
        config.providerConfig?.baseUrl,
        'https://llm.example.internal/api',
      );
      expect(config.engineLoop?.sessionId, 's1');
      expect(config.mcpTransport?.authRequired, isTrue);
      expect(config.compactionStrategy?.sessionId, 's1');
    },
  );
}
