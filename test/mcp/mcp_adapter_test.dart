// McpAdapter tests (FR-006, SC-008, contracts/mcp-adapter.md).
//
// MCP delegates to pi-mcp (an McpDelegate) when present; the wrapper only
// contributes governance/telemetry metadata. With no delegate the adapter
// fails with a typed mcpUnavailable outcome and ships no second client.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('McpAdapter', () {
    test('listTools delegates and records a telemetry tap', () async {
      final telemetry = InMemoryAgentTelemetryPort();
      final adapter = McpAdapter(
        delegate: InMemoryMcpDelegate(tools: const [McpTool('t1', 'a tool')]),
        telemetry: telemetry,
      );
      final tools = await adapter.listTools();
      expect(tools.single.name, 't1');
      expect(telemetry.events, isNotEmpty);
    });

    test('callTool delegates and returns the result', () async {
      final adapter = McpAdapter(
        delegate: InMemoryMcpDelegate(),
        telemetry: InMemoryAgentTelemetryPort(),
      );
      final result = await adapter.callTool('t1', {'x': 1});
      expect(result.output, contains('t1'));
    });

    test('a missing delegate yields typed mcpUnavailable (SC-008)', () async {
      final telemetry = InMemoryAgentTelemetryPort();
      final adapter = McpAdapter(delegate: null, telemetry: telemetry);
      expect(
        () => adapter.listTools(),
        throwsA(isA<McpUnavailableException>()),
      );
      expect(
        telemetry.events.any(
          (e) => e.attributes['outcome'] == 'mcpUnavailable',
        ),
        isTrue,
      );
    });

    test('governance tool-name prefixing is mcp__server__tool', () {
      expect(McpAdapter.prefix('github', 'search'), 'mcp__github__search');
    });
  });
}
