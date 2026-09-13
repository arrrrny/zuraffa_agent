// HAND-CURATED — spec 107 (issue arrrrny/zuraffa_agent#121).
//
// ZuraffaConfig — the runtime configuration aggregate: one value object
// carrying the six configuration sections the engine already has, plus the
// cross-cutting `validate()` that decides whether a configuration is
// runnable. Sections are individually optional; `validate()` returns typed
// issues (`missing` / `outOfRange` / `incompatible`) instead of throwing,
// so an operator sees every problem at once, at startup.
//
// Hand-curated plain-Dart value object per the house precedent (spec 081 /
// 104): compiles without build_runner; constitution IX exemption recorded.

import '../domain/entities/compaction_strategy/compaction_strategy.dart';
import '../domain/entities/engine_loop/engine_loop.dart';
import '../domain/entities/mcp_transport/mcp_transport.dart';
import '../domain/entities/provider_config/provider_config.dart';
import '../domain/entities/stop_policy/stop_policy.dart';
import '../domain/entities/yaml_agent_spec/yaml_agent_spec.dart';

/// A configuration problem found by [ZuraffaConfig.validate].
sealed class ConfigIssue {
  const ConfigIssue();

  /// Human-readable, operator-facing description of the problem.
  String get message;
}

/// A section is absent but required by another configured section.
final class ConfigIssueMissing extends ConfigIssue {
  final String section;

  /// The configured section(s) that require [section].
  final List<String> requiredBy;

  const ConfigIssueMissing({required this.section, required this.requiredBy});

  @override
  String get message =>
      'missing configuration: [$section] is required by ${requiredBy.join(', ')}';

  @override
  bool operator ==(Object other) =>
      other is ConfigIssueMissing &&
      other.section == section &&
      _listEquality.equals(other.requiredBy, requiredBy);

  @override
  int get hashCode =>
      Object.hash('missing', section, _listEquality.hash(requiredBy));

  @override
  String toString() => message;
}

/// A configured value is outside its legal bounds.
final class ConfigIssueOutOfRange extends ConfigIssue {
  final String section;
  final String field;

  /// The offending value.
  final Object? value;
  final String boundDescription;

  const ConfigIssueOutOfRange({
    required this.section,
    required this.field,
    required this.value,
    required this.boundDescription,
  });

  @override
  String get message =>
      'out of range: [$section.$field] is $value ($boundDescription)';

  @override
  bool operator ==(Object other) =>
      other is ConfigIssueOutOfRange &&
      other.section == section &&
      other.field == field &&
      other.value == value &&
      other.boundDescription == boundDescription;

  @override
  int get hashCode =>
      Object.hash('outOfRange', section, field, value, boundDescription);

  @override
  String toString() => message;
}

/// Two configured sections contradict each other.
final class ConfigIssueIncompatible extends ConfigIssue {
  final String sectionA;
  final String sectionB;
  final String reason;

  const ConfigIssueIncompatible({
    required this.sectionA,
    required this.sectionB,
    required this.reason,
  });

  @override
  String get message => 'incompatible: [$sectionA] and [$sectionB] — $reason';

  @override
  bool operator ==(Object other) =>
      other is ConfigIssueIncompatible &&
      other.sectionA == sectionA &&
      other.sectionB == sectionB &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash('incompatible', sectionA, sectionB, reason);

  @override
  String toString() => message;
}

/// List equality/hash helpers (no collection package dependency).
class _ListEquality {
  const _ListEquality();

  bool equals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int hash(List<String>? list) => Object.hashAll(list ?? const <String>[]);
}

const _listEquality = _ListEquality();

/// The runtime configuration aggregate (issue #121): six optional sections;
/// [validate] decides runnability.
class ZuraffaConfig {
  final ProviderConfig? providerConfig;
  final YamlAgentSpec? agentSpec;
  final EngineLoop? engineLoop;
  final McpTransport? mcpTransport;
  final StopPolicy? stopPolicy;
  final CompactionStrategy? compactionStrategy;

  const ZuraffaConfig({
    this.providerConfig,
    this.agentSpec,
    this.engineLoop,
    this.mcpTransport,
    this.stopPolicy,
    this.compactionStrategy,
  });

  /// Validates the configuration, returning every problem found (empty =
  /// runnable). Deterministic order: outOfRange, missing, incompatible.
  List<ConfigIssue> validate() {
    final issues = <ConfigIssue>[];

    // ---- outOfRange -------------------------------------------------
    final loop = engineLoop;
    if (loop != null && loop.maxTurns <= 0) {
      issues.add(
        ConfigIssueOutOfRange(
          section: 'engineLoop',
          field: 'maxTurns',
          value: loop.maxTurns,
          boundDescription: 'must be > 0',
        ),
      );
    }
    final provider = providerConfig;
    if (provider != null && provider.timeoutMs <= 0) {
      issues.add(
        ConfigIssueOutOfRange(
          section: 'providerConfig',
          field: 'timeoutMs',
          value: provider.timeoutMs,
          boundDescription: 'must be > 0',
        ),
      );
    }
    final policy = stopPolicy;
    if (policy != null && policy.wallClockTimeout < Duration.zero) {
      issues.add(
        ConfigIssueOutOfRange(
          section: 'stopPolicy',
          field: 'wallClockTimeout',
          value: policy.wallClockTimeout,
          boundDescription: 'must be >= Duration.zero',
        ),
      );
    }

    // ---- missing ----------------------------------------------------
    if (loop != null && provider == null) {
      issues.add(
        ConfigIssueMissing(
          section: 'providerConfig',
          requiredBy: const ['engineLoop'],
        ),
      );
    }

    // ---- incompatible -----------------------------------------------
    final compaction = compactionStrategy;
    if (loop != null &&
        compaction != null &&
        compaction.sessionId != loop.sessionId) {
      issues.add(
        ConfigIssueIncompatible(
          sectionA: 'engineLoop',
          sectionB: 'compactionStrategy',
          reason:
              'the loop is scoped to session "${loop.sessionId}" but the '
              'compaction strategy targets "${compaction.sessionId}"',
        ),
      );
    }

    return List.unmodifiable(issues);
  }

  @override
  bool operator ==(Object other) =>
      other is ZuraffaConfig &&
      other.providerConfig == providerConfig &&
      other.agentSpec == agentSpec &&
      other.engineLoop == engineLoop &&
      other.mcpTransport == mcpTransport &&
      other.stopPolicy == stopPolicy &&
      other.compactionStrategy == compactionStrategy;

  @override
  int get hashCode => Object.hash(
    providerConfig,
    agentSpec,
    engineLoop,
    mcpTransport,
    stopPolicy,
    compactionStrategy,
  );

  @override
  String toString() =>
      'ZuraffaConfig(provider: ${providerConfig != null}, '
      'agentSpec: ${agentSpec != null}, engineLoop: ${engineLoop != null}, '
      'mcpTransport: ${mcpTransport != null}, stopPolicy: ${stopPolicy != null}, '
      'compaction: ${compactionStrategy != null})';
}
