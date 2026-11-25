// AuditRecorder tests (FR-005, SC-006, contracts/observability.md).
//
// Every hook outcome yields an AgentAuditRecord written through
// AgentTelemetryPort, never with secrets by default.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('AuditRecorder', () {
    test('records an audit row as a telemetry event', () {
      final telemetry = InMemoryAgentTelemetryPort();
      final recorder = AuditRecorder(telemetry: telemetry);
      recorder.record(
        AgentAuditRecord(
          id: 'a1',
          at: DateTime.utc(2026, 11, 25),
          phase: 'tool-call',
          outcome: 'deny',
          redacted: false,
          unredactedOptIn: false,
        ),
      );
      expect(telemetry.events, hasLength(1));
      final event = telemetry.events.single;
      expect(event.name, 'agent.audit');
      expect(event.attributes['outcome'], 'deny');
      expect(event.attributes['phase'], 'tool-call');
    });

    test('a helper builds and records a typed outcome', () {
      final telemetry = InMemoryAgentTelemetryPort();
      final recorder = AuditRecorder(telemetry: telemetry);
      final record = recorder.recordOutcome(
        phase: 'provider-request',
        outcome: 'redact',
        redacted: true,
      );
      expect(record.outcome, 'redact');
      expect(record.redacted, isTrue);
      expect(telemetry.events.single.attributes['outcome'], 'redact');
    });
  });
}
