// spec 107 (issue #121) — ZuraffaConfig aggregate + typed validation.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/config/zuraffa_config.dart';
import 'package:zuraffa_agent/src/domain/entities/compaction_strategy/compaction_strategy.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/yaml_agent_spec/yaml_agent_spec.dart';

const provider = ProviderConfig(
  id: 'p1',
  providerKind: 'openai',
  baseUrl: 'https://llm.example.internal/api',
  models: ['internal/model'],
  timeoutMs: 30000,
);

const spec = YamlAgentSpec(
  id: 'spec-1',
  name: 'research',
  toolAllowlist: ['search'],
  systemPrompt: 'Research.',
);

EngineLoop loop({String sessionId = 's1', int maxTurns = 8}) => EngineLoop(
  id: 'loop-1',
  sessionId: sessionId,
  maxTurns: maxTurns,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

const transport = McpTransport(
  id: 'mcp-1',
  transportType: 'sse',
  endpoint: 'https://mcp.example.internal/sse',
  authRequired: true,
);

final stopPolicy = StopPolicy(
  id: 'stop-1',
  maxTurns: 16,
  wallClockTimeout: Duration.zero,
  repetitionThreshold: 5,
);

final compaction = CompactionStrategy(
  id: 'comp-1',
  sessionId: 's1',
  retainEntryIds: const [],
  summarizeEntryIds: const [],
  artifactRefs: const [],
  compactedAt: 0,
);

ZuraffaConfig fullConfig({EngineLoop? engineLoop}) => ZuraffaConfig(
  providerConfig: provider,
  agentSpec: spec,
  engineLoop: engineLoop ?? loop(),
  mcpTransport: transport,
  stopPolicy: stopPolicy,
  compactionStrategy: compaction,
);

void main() {
  group('spec 107 — ZuraffaConfig aggregate', () {
    test('U1: carries all six sections verbatim, each nullable', () {
      final config = fullConfig();
      expect(config.providerConfig, same(provider));
      expect(config.agentSpec, same(spec));
      expect(config.engineLoop?.sessionId, 's1');
      expect(config.mcpTransport, same(transport));
      expect(config.stopPolicy, same(stopPolicy));
      expect(config.compactionStrategy, same(compaction));

      final empty = ZuraffaConfig();
      expect(empty.providerConfig, isNull);
      expect(empty.agentSpec, isNull);
      expect(empty.engineLoop, isNull);
      expect(empty.mcpTransport, isNull);
      expect(empty.stopPolicy, isNull);
      expect(empty.compactionStrategy, isNull);
    });

    test('U2: a fully-populated configuration validates to an empty list', () {
      expect(fullConfig().validate(), isEmpty);
    });

    test('U3: engine loop without a provider section → missing issue', () {
      final config = ZuraffaConfig(engineLoop: loop());
      final issues = config.validate();
      final missing = issues.whereType<ConfigIssueMissing>().toList();
      expect(missing, hasLength(1));
      expect(missing.single.section, 'providerConfig');
      expect(missing.single.requiredBy, contains('engineLoop'));
    });

    test(
      'U4: non-positive budgets → outOfRange issues naming section+field',
      () {
        final issues = ZuraffaConfig(engineLoop: loop(maxTurns: 0)).validate();
        final outOfRange = issues.whereType<ConfigIssueOutOfRange>().toList();
        expect(
          outOfRange.map(
            (ConfigIssueOutOfRange i) => '${i.section}.${i.field}',
          ),
          contains('engineLoop.maxTurns'),
        );

        final badTimeout = ZuraffaConfig(
          providerConfig: const ProviderConfig(
            id: 'p1',
            providerKind: 'openai',
            baseUrl: 'https://llm.example.internal/api',
            models: ['m'],
            timeoutMs: 0,
          ),
        ).validate().whereType<ConfigIssueOutOfRange>().toList();
        expect(
          badTimeout.map(
            (ConfigIssueOutOfRange i) => '${i.section}.${i.field}',
          ),
          contains('providerConfig.timeoutMs'),
        );
      },
    );

    test('U5: engine loop and compaction scoped to different sessions → '
        'incompatible issue', () {
      final config = fullConfig(engineLoop: loop(sessionId: 's1'));
      final mismatched = ZuraffaConfig(
        engineLoop: config.engineLoop!,
        mcpTransport: transport,
        stopPolicy: stopPolicy,
        compactionStrategy: CompactionStrategy(
          id: 'comp-2',
          sessionId: 'other-session',
          retainEntryIds: const [],
          summarizeEntryIds: const [],
          artifactRefs: const [],
          compactedAt: 0,
        ),
      );
      final issues = mismatched.validate();
      final incompatible = issues.whereType<ConfigIssueIncompatible>().toList();
      expect(incompatible, hasLength(1));
      expect(incompatible.single.reason, contains('session'));
    });
  });
}
