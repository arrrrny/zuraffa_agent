// AgentLog — the structured-logging facade over `package:logging`
// (spec 112, issue #119).
//
// Delivery contract: the engine NEVER prints. Every record is emitted
// through a pinned named logger under the `zuraffa.agent.` hierarchy and
// reaches a consumer only after `ZuraffaLogging.install` attaches a sink;
// before install, emission is silent, never throws, and costs an
// `isLoggable` check.
//
// Level policy (spec 112 FR-002):
//   FINE    — transport bytes (wire payloads, framing details)
//   INFO    — lifecycle (turn/mission start, completion, outcomes)
//   WARNING — resilience events (retry scheduled, breaker open)
//   SEVERE  — terminal failures (mission failed, provider dead)

import 'dart:async';

import 'package:logging/logging.dart';

/// The install point for consumers: wires the hierarchy level and the
/// consumer-injected record sink. Before [install], no record goes
/// anywhere — the engine ships with zero console output by design.
abstract final class ZuraffaLogging {
  /// Root of the pinned logger hierarchy: `zuraffa.agent.<subsystem>`.
  static const String hierarchyRoot = 'zuraffa.agent';

  static StreamSubscription<LogRecord>? _subscription;

  /// Attaches [onRecord] as the record sink and sets the hierarchy
  /// [level]. Installing again replaces the previous sink (never stacks).
  static void install({
    Level level = Level.ALL,
    void Function(LogRecord record)? onRecord,
  }) {
    Logger.root.level = level;
    _subscription?.cancel();
    _subscription = onRecord == null
        ? null
        : Logger.root.onRecord.listen(onRecord);
  }

  /// Detaches the sink and restores the pre-install state.
  static void reset() {
    install(level: Level.ALL, onRecord: null);
  }
}

/// Named subsystem loggers + the level policy + the adoption-site
/// emission helpers (spec 112 FR-001..FR-005).
abstract final class AgentLog {
  /// The pinned subsystem names (spec 112 FR-001) — a public contract;
  /// new subsystems join this set by spec change only.
  static const List<String> subsystems = [
    'llm',
    'mcp',
    'engine',
    'eval',
    'session',
    'eventBus',
  ];

  /// Returns the logger for [subsystem] — `zuraffa.agent.<subsystem>`.
  /// Throws [ArgumentError] for any name outside the pinned
  /// [subsystems] set: off-hierarchy loggers would break consumer
  /// routing by name.
  static Logger logger(String subsystem) {
    if (!subsystems.contains(subsystem)) {
      throw ArgumentError.value(
        subsystem,
        'subsystem',
        'unknown subsystem — pinned set: $subsystems',
      );
    }
    return Logger('${ZuraffaLogging.hierarchyRoot}.$subsystem');
  }

  static Logger get llm => logger('llm');
  static Logger get mcp => logger('mcp');
  static Logger get engine => logger('engine');
  static Logger get eval => logger('eval');
  static Logger get session => logger('session');
  static Logger get eventBus => logger('eventBus');

  // -- Level policy (spec 112 FR-002). -------------------------------------

  /// Transport bytes: wire payloads, framing details.
  static const Level transportLevel = Level.FINE;

  /// Turn/mission lifecycle: starts, completions, outcomes.
  static const Level lifecycleLevel = Level.INFO;

  /// Resilience events: retry scheduled, breaker open.
  static const Level resilienceLevel = Level.WARNING;

  /// Terminal failures: the operation died and will not retry.
  static const Level terminalLevel = Level.SEVERE;

  /// The policy table: event class -> pinned level.
  static Map<String, Level> levelPolicy() => const {
    'transport': transportLevel,
    'lifecycle': lifecycleLevel,
    'resilience': resilienceLevel,
    'terminal': terminalLevel,
  };

  // -- Adoption-site helpers (spec 112 FR-005). ----------------------------

  /// WARNING record for a scheduled LLM retry — attempt number, backoff
  /// delay, and the triggering error. Skips message formatting when the
  /// record would be filtered.
  static void retryWarning({
    required int attempt,
    required Duration delay,
    required Object error,
  }) {
    if (!llm.isLoggable(resilienceLevel)) return;
    llm.log(
      resilienceLevel,
      'retry scheduled: attempt=$attempt '
      'delay=${delay.inMilliseconds}ms error=$error',
    );
  }

  /// INFO record for the mission lifecycle — id + outcome only, never
  /// payload content.
  static void missionInfo({
    required String missionId,
    required String outcome,
  }) {
    if (!engine.isLoggable(lifecycleLevel)) return;
    engine.log(lifecycleLevel, 'mission $missionId: $outcome');
  }

  /// Documentation self-check (spec 112 FR-006): throws [ArgumentError]
  /// naming the missing section when the shipped ARCHITECTURE.md logging
  /// section loses any of the three required coverage areas — the
  /// hierarchy, the level policy, or the sink recipe. Tests pass the
  /// real doc's sections here so docs and code can not silently drift.
  static void document({
    required String hierarchy,
    required String policy,
    required String sinkRecipe,
  }) {
    for (final entry in {
      'hierarchy': hierarchy,
      'policy': policy,
      'sinkRecipe': sinkRecipe,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError('logging docs section missing: ${entry.key}');
      }
    }
  }
}
