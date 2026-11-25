/// Writes [AgentAuditRecord] rows through the host's [AgentTelemetryPort]
/// (FR-005, SC-006, contracts/observability.md).
///
/// Every hook outcome — allow, deny, redact, failClosed, approvalGranted,
/// approvalDenied, approvalExpired, durableUnavailable, mcpUnavailable — is
/// recorded here as a telemetry event named `agent.audit`. The record carries
/// no raw payload: [AgentAuditRecord.redacted] marks scrubbing and
/// [AgentAuditRecord.unredactedOptIn] marks an explicit host opt-in.
library;

import '../governance/entities/agent_audit_record.dart';
import '../ports/agent_telemetry_port.dart';

/// Records audit rows for governance/hook outcomes.
class AuditRecorder {
  final AgentTelemetryPort _telemetry;

  AuditRecorder({required AgentTelemetryPort telemetry})
    : _telemetry = telemetry;

  /// The telemetry event name every audit row is written under.
  static const String eventName = 'agent.audit';

  /// Writes [record] as a telemetry event.
  void record(AgentAuditRecord record) {
    _telemetry.recordEvent(
      AgentTelemetryEvent(
        eventName,
        attributes: {
          'id': record.id,
          'at': record.at.toIso8601String(),
          'phase': record.phase,
          'outcome': record.outcome,
          'redacted': record.redacted,
          'unredactedOptIn': record.unredactedOptIn,
          if (record.error != null) 'error': record.error,
        },
      ),
    );
  }

  /// Builds and records a typed outcome row with a fresh id and timestamp.
  AgentAuditRecord recordOutcome({
    required String phase,
    required String outcome,
    bool redacted = false,
    bool unredactedOptIn = false,
    String? error,
    DateTime? at,
  }) {
    final record = AgentAuditRecord(
      id: _nextId(),
      at: at ?? DateTime.now().toUtc(),
      phase: phase,
      outcome: outcome,
      redacted: redacted,
      unredactedOptIn: unredactedOptIn,
      error: error,
    );
    this.record(record);
    return record;
  }

  int _seq = 0;
  String _nextId() => 'audit-${_seq++}';
}
