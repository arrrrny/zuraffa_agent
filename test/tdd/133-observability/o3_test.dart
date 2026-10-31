// Tests for issue arrrrny/zuraffa_agent#133 — O-3: HealthCheck service.
//
// The service aggregates health probes into one HealthReport with a JSON
// contract consumers can mount as /health or /readyz:
//   - circuit-breaker states
//   - MCP client states
//   - last-LLM-error tracker
//   - session-storage free space (injected getter — pure core, no dart:io)

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_guard.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';
import 'package:zuraffa_agent/src/observability/health_check.dart';

class FixedLlmClock implements LlmClock {
  FixedLlmClock(this.fixed);
  DateTime fixed;
  @override
  DateTime now() => fixed;
  @override
  Future<void> sleep(int milliseconds) async {}
}

class FakeMcpClient implements McpClient {
  FakeMcpClient(this._state);

  McpClientState _state;
  @override
  McpClientState get state => _state;
  set state(McpClientState value) => _state = value;

  @override
  McpTransport get transport => const McpTransport(
    id: 't1',
    transportType: 'in-proc',
    endpoint: 'local',
    authRequired: false,
  );

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<List<McpToolDescriptor>> listTools() async => const [];

  @override
  Future<McpCallResult> callTool(
    String name,
    Map<String, dynamic> arguments, {
    McpCallOptions? options,
  }) async => const McpCallOk({});

  @override
  Stream<void> get onToolsChanged => const Stream.empty();

  @override
  Stream<void> get onReconnected => const Stream.empty();
}

void main() {
  group('133 O-3 — HealthCheck service', () {
    test('all-healthy probes aggregate to an ok report', () async {
      final service = HealthCheckService(
        probes: [
          BreakerHealthProbe([
            CircuitBreaker(
              providerId: 'p1',
              clock: FixedLlmClock(DateTime.utc(2026, 1, 1)),
            ),
          ]),
          McpHealthProbe([FakeMcpClient(McpClientState.connected)]),
          SessionStorageSpaceProbe(freeSpaceBytes: () => 1 << 30),
        ],
      );

      final report = await service.check();

      expect(report.status, HealthStatus.ok);
      expect(report.results.map((r) => r.name).toList(), [
        'circuit_breakers',
        'mcp_clients',
        'session_storage_space',
      ]);
    });

    test(
      'open breaker degrades; failed MCP client is unhealthy; worst wins',
      () async {
        final clock = FixedLlmClock(DateTime.utc(2026, 1, 1));
        final openBreaker = CircuitBreaker(providerId: 'p2', clock: clock)
          ..recordFailure()
          ..recordFailure()
          ..recordFailure();
        final service = HealthCheckService(
          probes: [
            BreakerHealthProbe([openBreaker]),
            McpHealthProbe([FakeMcpClient(McpClientState.failed)]),
          ],
        );

        final report = await service.check();

        expect(report.status, HealthStatus.unhealthy);
        expect(report.results[0].status, HealthStatus.degraded);
        expect(report.results[1].status, HealthStatus.unhealthy);
      },
    );

    test(
      'last-LLM-error probe: recorded error degrades, success clears it',
      () async {
        final tracker = LastLlmErrorTracker();
        final probe = LastLlmErrorProbe(tracker);

        final before = await probe.probe();
        expect(before.status, HealthStatus.ok);

        tracker.recordError(
          StateError('429 too many requests'),
          provider: 'kilo',
        );
        final afterError = await probe.probe();
        expect(afterError.status, HealthStatus.degraded);
        expect(afterError.details['provider'], 'kilo');
        expect(afterError.details['error'], contains('429'));

        tracker.recordSuccess();
        final afterSuccess = await probe.probe();
        expect(afterSuccess.status, HealthStatus.ok);
      },
    );

    test(
      'session-storage space probe: unknown is ok, low space degrades',
      () async {
        const unknown = SessionStorageSpaceProbe();
        expect((await unknown.probe()).status, HealthStatus.ok);

        final healthy = SessionStorageSpaceProbe(freeSpaceBytes: () => 1 << 30);
        expect((await healthy.probe()).status, HealthStatus.ok);

        final low = SessionStorageSpaceProbe(
          freeSpaceBytes: () => 1024,
          warningThresholdBytes: 64 * 1024 * 1024,
        );
        final result = await low.probe();
        expect(result.status, HealthStatus.degraded);
        expect(result.details['freeSpaceBytes'], 1024);
      },
    );

    test(
      'the report serializes to the documented /health JSON contract',
      () async {
        final service = HealthCheckService(
          probes: [
            McpHealthProbe([FakeMcpClient(McpClientState.connected)]),
          ],
          clock: () => DateTime.utc(2026, 1, 1, 12, 30),
        );

        final json = (await service.check()).toJson();

        expect(json['status'], 'ok');
        expect(json['checkedAt'], '2026-01-01T12:30:00.000Z');
        final checks = json['checks'] as List;
        expect(checks, hasLength(1));
        expect((checks.single as Map)['name'], 'mcp_clients');
        expect((checks.single as Map)['status'], 'ok');
      },
    );

    test('a service with no probes reports ok', () async {
      final report = await HealthCheckService().check();
      expect(report.status, HealthStatus.ok);
      expect(report.results, isEmpty);
    });
  });
}
