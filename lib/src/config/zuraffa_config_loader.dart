// HAND-CURATED — spec 107 (issue arrrrny/zuraffa_agent#121).
//
// ZuraffaConfigLoader — turns operator-facing inputs (a YAML document, an
// environment map) into a [ZuraffaConfig]. Inputs are INJECTED (document
// string / map), keeping runtime paths dart:io-free (constitution VII):
// callers read files or `Platform.environment` themselves.
//
// Diagnostics follow the spec 104 loader precedent: wrong-typed known
// fields are `ArgumentError`s naming the field; unknown keys are ignored
// (forward compatibility — a newer document must not crash an older
// engine).

import 'package:yaml/yaml.dart';

import '../domain/entities/compaction_strategy/compaction_strategy.dart';
import '../domain/entities/engine_loop/engine_loop.dart';
import '../domain/entities/mcp_transport/mcp_transport.dart';
import '../domain/entities/provider_config/provider_config.dart';
import '../domain/entities/stop_policy/stop_policy.dart';
import '../domain/entities/yaml_agent_spec/yaml_agent_spec.dart';
import 'zuraffa_config.dart';

/// The environment variable names understood by
/// [ZuraffaConfigLoader.fromEnv], documented here as the single source of
/// truth mirrored in the README.
abstract final class ZuraffaEnvVars {
  static const providerBaseUrl = 'ZFA_PROVIDER_BASE_URL';
  static const providerKind = 'ZFA_PROVIDER_PROVIDER_KIND';
  static const providerModel = 'ZFA_PROVIDER_MODEL';
  static const providerTimeoutMs = 'ZFA_PROVIDER_TIMEOUT_MS';
  static const agentSpecId = 'ZFA_AGENT_SPEC_ID';
  static const agentSpecName = 'ZFA_AGENT_SPEC_NAME';
  static const agentSpecSystemPrompt = 'ZFA_AGENT_SPEC_SYSTEM_PROMPT';
  static const engineLoopMaxTurns = 'ZFA_ENGINE_LOOP_MAX_TURNS';
  static const engineLoopSessionId = 'ZFA_ENGINE_LOOP_SESSION_ID';
  static const engineLoopWallClockTimeoutMs =
      'ZFA_ENGINE_LOOP_WALL_CLOCK_TIMEOUT_MS';
  static const engineLoopRepetitionThreshold =
      'ZFA_ENGINE_LOOP_REPETITION_THRESHOLD';
  static const mcpTransportEndpoint = 'ZFA_MCP_TRANSPORT_ENDPOINT';
  static const mcpTransportType = 'ZFA_MCP_TRANSPORT_TYPE';
  static const stopPolicyMaxTurns = 'ZFA_STOP_POLICY_MAX_TURNS';
}

class ZuraffaConfigLoader {
  /// Parses a YAML document into a [ZuraffaConfig]. Unknown top-level keys
  /// are ignored; wrong-typed known fields throw `ArgumentError` naming
  /// the field.
  static ZuraffaConfig fromYaml(String source) {
    final doc = loadYaml(source);
    if (doc is! YamlMap) {
      throw ArgumentError.value(
        source,
        'source',
        'top-level YAML document must be a mapping',
      );
    }
    return ZuraffaConfig(
      providerConfig: _provider(_map(doc, 'provider')),
      agentSpec: _agentSpec(_map(doc, 'agent_spec')),
      engineLoop: _engineLoop(_map(doc, 'engine_loop')),
      mcpTransport: _mcpTransport(_map(doc, 'mcp_transport')),
      stopPolicy: _stopPolicy(_map(doc, 'stop_policy')),
      compactionStrategy: _compaction(_map(doc, 'compaction')),
    );
  }

  /// Maps environment variables (injected — the caller supplies the map) to
  /// a [ZuraffaConfig]. Absent variables leave sections absent; unknown
  /// variables are ignored; unparsable numeric values throw `ArgumentError`
  /// naming the variable.
  static ZuraffaConfig fromEnv(Map<String, String> env) {
    String? v(String key) {
      final value = env[key];
      return (value == null || value.isEmpty) ? null : value;
    }

    int? intVar(String key) {
      final raw = v(key);
      if (raw == null) return null;
      final parsed = int.tryParse(raw);
      if (parsed == null) {
        throw ArgumentError.value(raw, key, 'must be an integer');
      }
      return parsed;
    }

    final baseUrl = v(ZuraffaEnvVars.providerBaseUrl);
    final providerModel = v(ZuraffaEnvVars.providerModel);
    final providerConfig = baseUrl == null
        ? null
        : ProviderConfig(
            id: 'env',
            providerKind: v(ZuraffaEnvVars.providerKind) ?? 'openai',
            baseUrl: baseUrl,
            models: [providerModel ?? ''],
            timeoutMs: intVar(ZuraffaEnvVars.providerTimeoutMs) ?? 30000,
          );

    final specId = v(ZuraffaEnvVars.agentSpecId);
    final agentSpec = specId == null
        ? null
        : YamlAgentSpec(
            id: specId,
            name: v(ZuraffaEnvVars.agentSpecName) ?? specId,
            toolAllowlist: const [],
            systemPrompt: v(ZuraffaEnvVars.agentSpecSystemPrompt) ?? '',
          );

    final maxTurns = intVar(ZuraffaEnvVars.engineLoopMaxTurns);
    final loopSession = v(ZuraffaEnvVars.engineLoopSessionId);
    final engineLoop = maxTurns == null && loopSession == null
        ? null
        : EngineLoop(
            id: 'env',
            sessionId: loopSession ?? 'env',
            maxTurns: maxTurns ?? 100,
            wallClockTimeoutMs:
                intVar(ZuraffaEnvVars.engineLoopWallClockTimeoutMs) ?? 0,
            repetitionThreshold:
                intVar(ZuraffaEnvVars.engineLoopRepetitionThreshold) ?? 5,
          );

    final endpoint = v(ZuraffaEnvVars.mcpTransportEndpoint);
    final mcpTransport = endpoint == null
        ? null
        : McpTransport(
            id: 'env',
            transportType: v(ZuraffaEnvVars.mcpTransportType) ?? 'sse',
            endpoint: endpoint,
            authRequired: false,
          );

    final policyMaxTurns = intVar(ZuraffaEnvVars.stopPolicyMaxTurns);
    final stopPolicy = policyMaxTurns == null
        ? null
        : StopPolicy(
            id: 'env',
            maxTurns: policyMaxTurns,
            wallClockTimeout: Duration.zero,
            repetitionThreshold: 5,
          );

    return ZuraffaConfig(
      providerConfig: providerConfig,
      agentSpec: agentSpec,
      engineLoop: engineLoop,
      mcpTransport: mcpTransport,
      stopPolicy: stopPolicy,
    );
  }

  // ---- YAML helpers --------------------------------------------------

  static YamlMap? _map(YamlMap doc, String key) {
    final value = doc[key];
    if (value == null) return null;
    if (value is! YamlMap) {
      throw ArgumentError.value(value, key, 'section must be a mapping');
    }
    return value;
  }

  static String _string(YamlMap section, String key, String path) {
    final value = section[key];
    if (value is! String) {
      throw ArgumentError.value(value, '$path.$key', 'must be a string');
    }
    return value;
  }

  static int _int(YamlMap section, String key, String path) {
    final value = section[key];
    if (value is! int) {
      throw ArgumentError.value(value, '$path.$key', 'must be an integer');
    }
    return value;
  }

  static List<String> _strings(YamlMap section, String key, String path) {
    final value = section[key];
    if (value is! YamlList) {
      throw ArgumentError.value(value, '$path.$key', 'must be a list');
    }
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }

  static ProviderConfig? _provider(YamlMap? section) {
    if (section == null) return null;
    const path = 'provider';
    return ProviderConfig(
      id: _string(section, 'id', path),
      providerKind: _string(section, 'providerKind', path),
      baseUrl: _string(section, 'baseUrl', path),
      models: _strings(section, 'models', path),
      timeoutMs: _int(section, 'timeoutMs', path),
    );
  }

  static YamlAgentSpec? _agentSpec(YamlMap? section) {
    if (section == null) return null;
    const path = 'agent_spec';
    return YamlAgentSpec(
      id: _string(section, 'id', path),
      name: _string(section, 'name', path),
      toolAllowlist: _strings(section, 'toolAllowlist', path),
      systemPrompt: _string(section, 'systemPrompt', path),
    );
  }

  static EngineLoop? _engineLoop(YamlMap? section) {
    if (section == null) return null;
    const path = 'engine_loop';
    return EngineLoop(
      id: _string(section, 'id', path),
      sessionId: _string(section, 'sessionId', path),
      maxTurns: _int(section, 'maxTurns', path),
      wallClockTimeoutMs: _int(section, 'wallClockTimeoutMs', path),
      repetitionThreshold: _int(section, 'repetitionThreshold', path),
    );
  }

  static McpTransport? _mcpTransport(YamlMap? section) {
    if (section == null) return null;
    const path = 'mcp_transport';
    final authRequired = section['authRequired'];
    return McpTransport(
      id: _string(section, 'id', path),
      transportType: _string(section, 'transportType', path),
      endpoint: _string(section, 'endpoint', path),
      authRequired: authRequired is bool ? authRequired : false,
    );
  }

  static StopPolicy? _stopPolicy(YamlMap? section) {
    if (section == null) return null;
    const path = 'stop_policy';
    final wallClockTimeoutMs = _int(section, 'wallClockTimeoutMs', path);
    final enabled = section['enabled'];
    return StopPolicy(
      id: _string(section, 'id', path),
      maxTurns: _int(section, 'maxTurns', path),
      wallClockTimeout: Duration(milliseconds: wallClockTimeoutMs),
      repetitionThreshold: _int(section, 'repetitionThreshold', path),
      enabled: enabled is bool ? enabled : true,
    );
  }

  static CompactionStrategy? _compaction(YamlMap? section) {
    if (section == null) return null;
    const path = 'compaction';
    return CompactionStrategy(
      id: _string(section, 'id', path),
      sessionId: _string(section, 'sessionId', path),
      retainEntryIds: _strings(section, 'retainEntryIds', path),
      summarizeEntryIds: _strings(section, 'summarizeEntryIds', path),
      artifactRefs: _strings(section, 'artifactRefs', path),
      compactedAt: _int(section, 'compactedAt', path),
    );
  }
}
