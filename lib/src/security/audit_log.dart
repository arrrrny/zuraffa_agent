// Issue arrrrny/zuraffa_agent#132 — the security audit trail.
//
// `EngineEventLog` records lifecycle events and `UsageLedger` token counts,
// but nothing recorded the security surface: who configured which provider,
// which tool ran with which arguments (as hashes, not payloads), which
// approval decisions were made, and how breakers moved. [AuditLog] is that
// interface; [SinkAuditLog] routes each event into an [AuditSink] (the
// durable, append-only [JsonlAuditSink] by convention) and mirrors one
// structured record onto the O-1 logger hierarchy
// (`zuraffa.agent.audit`) per the spec 112 delivery discipline — silent
// unless installed, isLoggable-gated, never payload-bearing.
//
// Pattern: plain-Dart read/write projection like UsageLedger
// (lib/src/usage_ledger.dart) — no @Zorphy, no dart:io here (the sink owns
// the file I/O), no new deps (constitution Principles VII/IX).

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'audit_hashing.dart';

/// The security event classes of the audit trail (issue #132 AC).
enum AuditCategory { providerConfig, toolCall, approval, breaker }

/// The dotted action strings — stable identifiers, safe to route on.
abstract final class AuditActions {
  static const String providerConfigured = 'provider.configured';
  static const String toolInvoked = 'tool.invoked';
  static const String approvalGranted = 'approval.granted';
  static const String approvalDenied = 'approval.denied';
  static const String breakerTransitioned = 'breaker.transitioned';
}

/// One immutable audit record. [details] carries names, decisions and
/// HASHES only — raw argument or result payloads must never enter an
/// entry; the interface hashes them on the way in.
class AuditEntry {
  AuditEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.action,
    Map<String, Object?>? details,
  }) : details = Map<String, Object?>.unmodifiable(details ?? const {});

  /// Unique record id (uuid v4).
  final String id;

  /// When the event was recorded (UTC).
  final DateTime timestamp;

  final AuditCategory category;

  /// One of the stable [AuditActions] strings.
  final String action;

  /// Names + hashes + decisions; never raw payloads. Unmodifiable.
  final Map<String, Object?> details;

  /// Serialized form: versioned for forward compatibility.
  Map<String, dynamic> toJson() => {
    'v': 1,
    'id': id,
    'ts': timestamp.toUtc().toIso8601String(),
    'category': category.name,
    'action': action,
    'details': details,
  };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['ts'] as String).toUtc(),
    category: AuditCategory.values.byName(json['category'] as String),
    action: json['action'] as String,
    details: {
      for (final entry in (json['details'] as Map? ?? const {}).entries)
        '${entry.key}': entry.value as Object?,
    },
  );

  /// Equality THROUGH the serialized form (UsageLedger precedent, spec 083):
  /// two entries are equal iff their JSON forms serialize identically.
  late final String _encoded = jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditEntry && other._encoded == _encoded);

  @override
  int get hashCode => _encoded.hashCode;

  @override
  String toString() => 'AuditEntry($_encoded)';
}

/// The security audit surface (issue #132 AC): provider config changes,
/// tool-call invocations (name + args hash + result hash, NOT raw
/// payloads), approval decisions, and breaker state transitions.
abstract interface class AuditLog {
  /// Records that a provider's configuration was set or changed. Secret
  /// material (API keys) is not part of [ProviderConfig] and must never be
  /// passed here.
  Future<void> providerConfigChanged({
    required String providerId,
    required String providerKind,
    required String baseUrl,
    required List<String> models,
    required int timeoutMs,
    String? actor,
  });

  /// Records one tool invocation. [arguments] and [result] are hashed
  /// ([auditHash]) before anything is stored — implementations must never
  /// persist them raw.
  Future<void> toolCallInvoked({
    required String toolName,
    required Map<String, dynamic> arguments,
    String? result,
    required bool success,
    String? requestId,
    String? actor,
  });

  /// Records an approval-surface decision ([approved] granted/denied) for
  /// the request [requestId].
  Future<void> approvalDecision({
    required String requestId,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool approved,
    String? actor,
  });

  /// Records a breaker state transition (`closed`/`open`/`halfOpen`).
  Future<void> breakerTransition({
    required String providerId,
    required String from,
    required String to,
    String? actor,
  });
}

/// A durable destination for [AuditEntry] records. The audit trail's write
/// contract: appends only, in call order. Implemented by [JsonlAuditSink]
/// (durable, append-only JSONL).
abstract interface class AuditSink {
  Future<void> append(AuditEntry entry);

  /// The entries visible in the active view, oldest first. Corrupt lines
  /// (tears) are skipped — never repaired in place.
  Future<List<AuditEntry>> entries();
}

/// The default [AuditLog]: builds an [AuditEntry] per event, appends it to
/// the [AuditSink], and mirrors one structured record onto the pinned
/// `zuraffa.agent.audit` logger (on the O-1 hierarchy root, so existing
/// consumer sinks receive it; adding the name to the pinned
/// [AgentLog.subsystems] set is a spec change left out of this issue).
class SinkAuditLog implements AuditLog {
  SinkAuditLog({
    required AuditSink sink,
    DateTime Function()? clock,
    Logger? logger,
  }) : _sink = sink,
       _clock = clock ?? DateTime.now,
       _logger = logger ?? Logger(auditLoggerName);

  /// The pinned audit logger name — under the [ZuraffaLogging] hierarchy
  /// root `zuraffa.agent.`.
  static const String auditLoggerName = 'zuraffa.agent.audit';

  final AuditSink _sink;
  final DateTime Function() _clock;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> providerConfigChanged({
    required String providerId,
    required String providerKind,
    required String baseUrl,
    required List<String> models,
    required int timeoutMs,
    String? actor,
  }) {
    return _record(
      AuditCategory.providerConfig,
      AuditActions.providerConfigured,
      {
        'providerId': providerId,
        'providerKind': providerKind,
        'baseUrl': baseUrl,
        'models': List<String>.of(models),
        'timeoutMs': timeoutMs,
        'actor': ?actor,
      },
    );
  }

  @override
  Future<void> toolCallInvoked({
    required String toolName,
    required Map<String, dynamic> arguments,
    String? result,
    required bool success,
    String? requestId,
    String? actor,
  }) {
    final resultHash = result == null ? null : auditHash(result);
    return _record(AuditCategory.toolCall, AuditActions.toolInvoked, {
      'toolName': toolName,
      'argsHash': auditHash(arguments),
      'resultHash': ?resultHash,
      'success': success,
      'requestId': ?requestId,
      'actor': ?actor,
    });
  }

  @override
  Future<void> approvalDecision({
    required String requestId,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool approved,
    String? actor,
  }) {
    return _record(
      AuditCategory.approval,
      approved ? AuditActions.approvalGranted : AuditActions.approvalDenied,
      {
        'requestId': requestId,
        'toolName': toolName,
        'argsHash': auditHash(arguments),
        'actor': ?actor,
      },
      level: approved ? Level.INFO : Level.WARNING,
    );
  }

  @override
  Future<void> breakerTransition({
    required String providerId,
    required String from,
    required String to,
    String? actor,
  }) {
    return _record(AuditCategory.breaker, AuditActions.breakerTransitioned, {
      'providerId': providerId,
      'from': from,
      'to': to,
      'actor': ?actor,
    }, level: Level.WARNING);
  }

  /// Builds, appends, and mirrors. The durable append happens first: the
  /// trail never depends on the logger being installed.
  Future<void> _record(
    AuditCategory category,
    String action,
    Map<String, Object?> details, {
    Level level = Level.INFO,
  }) async {
    final entry = AuditEntry(
      id: _uuid.v4(),
      timestamp: _clock().toUtc(),
      category: category,
      action: action,
      details: details,
    );
    await _sink.append(entry);
    if (!_logger.isLoggable(level)) return;
    _logger.log(
      level,
      'audit ${entry.action} ${entry.category.name}: '
      '${entry.details}',
    );
  }
}
