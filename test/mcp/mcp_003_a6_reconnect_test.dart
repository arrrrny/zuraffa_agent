// Spec 003 — acceptance behavior A6: an SSE connection dropping mid-mission
// reconnects (with backoff) and resumes tool listing/calls.
//
// This is the acceptance-level claim, not the unit one: a single client
// instance survives TWO drops at two different points of a mission — once while
// listing tools, once while calling one — reopens the wire behind an
// exponential backoff, and both operations return their real results
// afterwards. The recorded delays make the backoff observable, and the delay
// sequence restarting at the initial value proves the policy was reset by the
// intervening success rather than marching toward exhaustion.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import 'package:zuraffa_agent/src/mcp/sse_mcp_client.dart';

import '_fake_wire.dart';

class TransportDropped implements Exception {
  const TransportDropped();
  @override
  String toString() => 'TransportDropped';
}

void main() {
  test('A6: a mid-mission SSE drop reconnects with backoff and resumes both '
      'tool listing and tool calls', () async {
    final wire = FakeMcpWire();
    final delays = <Duration>[];

    final client = SseMcpClient(
      transport: const McpTransport(
        id: 'sse-a6',
        transportType: 'sse',
        endpoint: 'https://example.invalid/sse',
        authRequired: true,
      ),
      wireFactory: (_) => wire,
      now: () => DateTime.utc(2026, 8, 28),
      delay: (d) async => delays.add(d),
    );

    await client.connect();
    expect(wire.openCallCount, 1);

    // Drop #1: mid-listing. The retry after reconnect returns the listing.
    wire.enqueueNext(const TransportDropped());
    wire.enqueueNext(const McpWireResponseOk({
      'tools': [
        {'name': 'search', 'description': 'search the web'},
      ],
    }));

    final tools = await client.listTools();
    expect(tools.map((t) => t.name), ['search']);
    expect(wire.openCallCount, 2, reason: 'the wire was reopened once');
    expect(delays, [const Duration(milliseconds: 100)]);
    expect(client.state, McpClientState.connected);

    // Drop #2: mid-call, later in the same mission on the same client.
    wire.enqueueNext(const TransportDropped());
    wire.enqueueNext(const McpWireResponseOk({'content': 'lisbon is sunny'}));

    final result = await client.callTool('search', {'q': 'weather'});
    expect(result, isA<McpCallOk>());
    expect((result as McpCallOk).result['content'], 'lisbon is sunny');
    expect(wire.openCallCount, 3);

    // The second drop's backoff restarted at the initial delay: the successful
    // listing in between reset the policy instead of escalating toward
    // exhaustion.
    expect(delays, [
      const Duration(milliseconds: 100),
      const Duration(milliseconds: 100),
    ]);
    expect(client.state, McpClientState.connected);

    await client.disconnect();
  });
}
