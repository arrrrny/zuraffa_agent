// Issue arrrrny/zuraffa_agent#4 (R3) — spec-003 A1 behavioral coverage.
//
// Until this file the engine ToolRegistry (lib/src/engine/tool_registry.dart)
// existed only as an abstract interface: McpToolAdapter's header says "no
// concrete registry required to test — a fake suffices", and the audit
// (specs/003-tools-and-mcp/tdd/verification.md, finding F3) records that NO
// test resolves a call across tool origins at a real registry. InMemoryToolRegistry
// is that concrete one-namespace registry:
//
//   - DDA-registered tools live under their bare id (native namespace);
//   - generated (AgentPlugin usecase) tools are namespaced `gen:<id>`;
//   - remote MCP tools are namespaced `mcp:<serverId>:<id>` (the
//     McpToolAdapter convention — it may pass a pre-qualified id, the
//     registry qualifies a bare one);
//   - collisions are REJECTED at registration with a NamespaceCollisionEvent,
//     never silently overwritten (AgentTool.id doc + issue #4 AC "namespace
//     collision safety across in-proc + remote sources");
//   - resolve() answers qualified names exactly, and a bare name only when
//     it unambiguously names one registered tool.

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/engine/in_memory_tool_registry.dart';
import 'package:zuraffa_agent/src/engine/tool_registry.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_guard.dart' show McpCallOptions;
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_adapter.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';

/// Minimal McpClient stub for the adapter integration test (same shape as
/// the fake in test/mcp/mcp_tool_adapter_test.dart).
class _FakeMcpClient implements McpClient {
  @override
  final McpTransport transport;
  List<McpToolDescriptor> nextTools = const [];

  _FakeMcpClient(this.transport);

  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<McpToolDescriptor>> listTools() async => nextTools;
  @override
  Future<McpCallResult> callTool(
    String n,
    Map<String, dynamic> a, {
    McpCallOptions? options,
  }) async => const McpCallError(code: 'not-implemented', message: 'stub');
  @override
  Stream<void> get onToolsChanged => const Stream.empty();
  @override
  Stream<void> get onReconnected => const Stream.empty();
  @override
  McpClientState get state => McpClientState.connected;
}

AgentTool _dda() => const AgentTool(
  id: 'fetch',
  description: 'in-proc DDA fetch',
  riskTier: RiskTier.safe,
  executionMode: ExecutionMode.parallel,
  paramsSchema: {'type': 'object'},
);

AgentTool _generated() =>
    const AgentTool(id: 'create_report', description: 'usecase-generated');

AgentTool _mcpFetch() => const AgentTool(
  id: 'mcp:raptorr:fetch',
  description: 'remote raptorr fetch',
  riskTier: RiskTier.confirm,
);

void main() {
  group(
    'InMemoryToolRegistry — one namespace across origins (spec-003 A1)',
    () {
      test(
        'resolves DDA, generated and remote-MCP tools side by side',
        () async {
          final registry = InMemoryToolRegistry();
          await registry.registerDdaTool(_dda());
          await registry.registerGeneratedTool(_generated());
          await registry.registerMcpTool(_mcpFetch(), 'raptorr');

          final dda = await registry.resolve('fetch');
          final gen = await registry.resolve('gen:create_report');
          final mcp = await registry.resolve('mcp:raptorr:fetch');

          expect(dda?.description, 'in-proc DDA fetch');
          expect(dda?.riskTier, RiskTier.safe);
          expect(dda?.paramsSchema, {'type': 'object'});
          expect(gen?.description, 'usecase-generated');
          expect(mcp?.description, 'remote raptorr fetch');
          expect(mcp?.riskTier, RiskTier.confirm);

          final all = await registry.list();
          expect(
            all,
            hasLength(3),
            reason: 'all three origins share one registry',
          );
        },
      );

      test(
        'resolves a bare name when it unambiguously names one tool',
        () async {
          final registry = InMemoryToolRegistry();
          await registry.registerGeneratedTool(_generated());
          expect(
            await registry.resolve('create_report'),
            isNotNull,
            reason: 'bare name of the only generated tool resolves',
          );

          final mcpOnly = InMemoryToolRegistry();
          await mcpOnly.registerMcpTool(_mcpFetch(), 'raptorr');
          expect(await mcpOnly.resolve('fetch'), isNotNull);
        },
      );

      test(
        'an ambiguous bare name resolves to nothing (collision safety)',
        () async {
          final registry = InMemoryToolRegistry();
          await registry.registerGeneratedTool(
            const AgentTool(id: 'fetch', description: 'gen fetch'),
          );
          await registry.registerMcpTool(
            const AgentTool(id: 'mcp:other:fetch', description: 'remote fetch'),
            'other',
          );

          expect(
            await registry.resolve('fetch'),
            isNull,
            reason: 'two prefixed tools share the bare name — never guess',
          );
          expect(await registry.resolve('gen:fetch'), isNotNull);
          expect(await registry.resolve('mcp:other:fetch'), isNotNull);
        },
      );
    },
  );

  group(
    'InMemoryToolRegistry — collisions are rejected, never overwritten',
    () {
      test(
        'duplicate DDA registration throws and emits a collision event',
        () async {
          final registry = InMemoryToolRegistry();
          await registry.registerDdaTool(_dda());
          final events = <NamespaceCollisionEvent>[];
          final sub = registry.onCollision.listen(events.add);

          await expectLater(
            registry.registerDdaTool(
              const AgentTool(id: 'fetch', description: 'ATTACKER override'),
            ),
            throwsStateError,
          );

          // The original registration survives untouched.
          final resolved = await registry.resolve('fetch');
          expect(resolved?.description, 'in-proc DDA fetch');
          await Future<void>.delayed(Duration.zero);
          expect(events, hasLength(1));
          expect(events.single.toolName, 'fetch');
          expect(events.single.sources, containsAll(['dda']));
          expect(events.single.resolution, 'rejected');
          await sub.cancel();
        },
      );

      test(
        'cross-origin qualified collision (MCP re-register) is rejected too',
        () async {
          final registry = InMemoryToolRegistry();
          await registry.registerMcpTool(_mcpFetch(), 'raptorr');
          final events = <NamespaceCollisionEvent>[];
          final sub = registry.onCollision.listen(events.add);

          await expectLater(
            registry.registerMcpTool(
              const AgentTool(id: 'mcp:raptorr:fetch', description: 'v2'),
              'raptorr',
            ),
            throwsStateError,
          );

          expect(
            (await registry.resolve('mcp:raptorr:fetch'))?.description,
            'remote raptorr fetch',
          );
          await Future<void>.delayed(Duration.zero);
          expect(events.single.sources, containsAll(['mcp:raptorr']));
          await sub.cancel();
        },
      );

      test(
        'a bare MCP id is qualified with its server id automatically',
        () async {
          final registry = InMemoryToolRegistry();
          await registry.registerMcpTool(
            const AgentTool(id: 'list_files', description: 'bare from server'),
            'raptorr',
          );
          expect(
            (await registry.resolve('mcp:raptorr:list_files'))?.description,
            'bare from server',
          );
        },
      );
    },
  );

  group('InMemoryToolRegistry — McpToolAdapter integration', () {
    test(
      'remote MCP tools surface beside in-proc tools without clobbering them',
      () async {
        final registry = InMemoryToolRegistry();
        await registry.registerDdaTool(_dda());

        final client =
            _FakeMcpClient(
                const McpTransport(
                  id: 'raptorr',
                  transportType: 'sse',
                  endpoint: 'https://example.invalid/sse',
                  authRequired: true,
                ),
              )
              ..nextTools = const [
                McpToolDescriptor(
                  name: 'fetch',
                  description: 'remote raptorr fetch',
                ),
              ];
        final adapter = McpToolAdapter(
          client: client,
          registry: registry,
          serverId: 'raptorr',
          // Deterministic re-listing: a zero max-age makes every sync()
          // bypass the listing cache (the constant test clock alone would
          // serve the first listing forever).
          maxAge: Duration.zero,
          now: () => DateTime.utc(2026, 10, 31),
        );
        await adapter.sync();

        // Same bare name on both origins — both resolve, neither overwrote.
        expect(
          (await registry.resolve('fetch'))?.description,
          'in-proc DDA fetch',
        );
        expect(
          (await registry.resolve('mcp:raptorr:fetch'))?.description,
          'remote raptorr fetch',
        );
        expect(await registry.list(), hasLength(2));

        // A later sync where the remote tool vanished unregisters only it.
        client.nextTools = const [];
        await adapter.sync();
        expect(await registry.resolve('mcp:raptorr:fetch'), isNull);
        expect(
          (await registry.resolve('fetch'))?.description,
          'in-proc DDA fetch',
        );
      },
    );
  });

  group('InMemoryToolRegistry — unregister and unknown names', () {
    test('unregister removes exactly the addressed qualified name', () async {
      final registry = InMemoryToolRegistry();
      await registry.registerDdaTool(_dda());
      await registry.registerMcpTool(_mcpFetch(), 'raptorr');

      await registry.unregister('mcp:raptorr:fetch');
      expect(await registry.resolve('mcp:raptorr:fetch'), isNull);
      expect(await registry.resolve('fetch'), isNotNull);

      // Unknown names are a no-op, not an error (the adapter relies on this
      // for diffed re-registration).
      await registry.unregister('mcp:ghost:tool');
      expect(await registry.list(), hasLength(1));
    });

    test('resolve of an unknown name returns null', () async {
      final registry = InMemoryToolRegistry();
      expect(await registry.resolve('nope'), isNull);
    });
  });
}
