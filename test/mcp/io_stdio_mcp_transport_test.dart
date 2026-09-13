// Integration tests for `IoStdioMcpTransport` (spec 105, issue #107).
//
// Hermetic: every test spawns the mock MCP child in
// `test/mcp/_mock_stdio_mcp_server.dart` via the current VM executable —
// real subprocess I/O, no external services, no prebuilt binaries.
// Dialect contract: specs/105-production-mcp-transports/contracts/mcp-wire-dialect.md.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import '_mock_stdio_mcp_server.dart' show mockScriptPath;

final _scriptPath = File(mockScriptPath).absolute.path;

IoStdioMcpTransport _spawn(String mode) => IoStdioMcpTransport(
  executable: Platform.resolvedExecutable,
  args: [_scriptPath, mode],
);

const _echoDescriptor = {
  'name': 'echo',
  'description': 'Echoes arguments',
  'paramsSchema': {'type': 'object'},
};

void main() {
  group('spec-105 — IoStdioMcpTransport', () {
    test('U1: open spawns the mock child and reports open', () async {
      final transport = _spawn('echo');
      addTearDown(transport.close);
      await transport.open();
      expect(transport.isOpen, isTrue);
    });

    test('U2: tools/list round-trips the advertised descriptors', () async {
      final transport = _spawn('echo');
      addTearDown(transport.close);
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      final payload = (resp as McpWireResponseOk).payload;
      expect(payload['tools'], [_echoDescriptor]);
    });

    test(
      'U3: tools/call round-trips arguments and the session persists',
      () async {
        final transport = _spawn('echo');
        addTearDown(transport.close);
        await transport.open();
        final first = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {'x': 1}),
        );
        expect(first, isA<McpWireResponseOk>());
        expect((first as McpWireResponseOk).payload, {
          'echo': {'x': 1},
        });
        final second = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {'y': 'z'}),
        );
        expect((second as McpWireResponseOk).payload, {
          'echo': {'y': 'z'},
        });
      },
    );

    test('U4: constructor rejects an empty executable', () {
      expect(
        () => IoStdioMcpTransport(executable: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('U7: garbage lines are skipped and the session survives', () async {
      final transport = _spawn('garbage');
      addTearDown(transport.close);
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      // The junk must not have corrupted the answer: the exact descriptor
      // (not 999's empty list) comes back through the intact session.
      expect((resp as McpWireResponseOk).payload['tools'], [_echoDescriptor]);
    });

    test(
      'U5: a JSON-RPC error response maps to the typed error response',
      () async {
        final transport = _spawn('garbage');
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'boom', arguments: {}),
        );
        expect(resp, isA<McpWireResponseError>());
        final err = resp as McpWireResponseError;
        expect(err.code, '-32601');
        expect(err.message, 'tool exploded');
      },
    );

    test(
      'U8: a response with an unknown id is dropped; the real answer still resolves',
      () async {
        // garbage mode emits a result for id 999 (nobody asked) at startup.
        final transport = _spawn('garbage');
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(const McpWireRequestListTools());
        expect(resp, isA<McpWireResponseOk>());
        final payload = (resp as McpWireResponseOk).payload;
        expect(payload['tools'], [
          _echoDescriptor,
        ]); // the echo descriptor, not 999's
      },
    );

    test(
      'U6: the tools-changed notification is observed on notifications',
      () async {
        final transport = _spawn('notify');
        addTearDown(transport.close);
        // Subscribe BEFORE opening: the child writes at startup and
        // `notifications` is a broadcast stream — events emitted before a
        // listener attaches are dropped.
        final notificationFuture = transport.notifications.first.timeout(
          const Duration(seconds: 5),
        );
        await transport.open();
        expect(
          await notificationFuture,
          isA<McpWireNotificationToolsChanged>(),
        );
      },
    );

    test('U9: child exit flips isOpen off and fails sends typed', () async {
      final transport = _spawn('crash');
      await transport.open();
      final pending = transport.send(
        const McpWireRequestCallTool(name: 'crash', arguments: {}),
      );
      await expectLater(
        pending.timeout(const Duration(seconds: 10)),
        throwsA(isA<McpWireClosedException>()),
      );
      expect(transport.isOpen, isFalse);
      await expectLater(
        transport.send(const McpWireRequestListTools()),
        throwsA(isA<McpWireClosedException>()),
      );
    });

    test('U10: send before open fails typed', () async {
      final transport = _spawn('echo');
      await expectLater(
        transport.send(const McpWireRequestListTools()),
        throwsA(isA<McpWireClosedException>()),
      );
    });

    test('U11: double open and double close are no-ops', () async {
      final transport = _spawn('echo');
      addTearDown(transport.close);
      await transport.open();
      await transport.open(); // must not throw; session stays consistent
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      await transport.close();
      await transport.close(); // must not throw
      expect(transport.isOpen, isFalse);
    });

    test(
      'U12: close fails in-flight sends typed and shuts the streams down',
      () async {
        final transport = _spawn('slow');
        await transport.open();
        // Attach a listener at creation time: the rejection lands while
        // close() runs, before any later expect could subscribe.
        Object? captured;
        unawaited(
          transport
              .send(const McpWireRequestCallTool(name: 'echo', arguments: {}))
              .then(
                (_) {},
                onError: (Object e) {
                  captured = e;
                },
              ),
        );
        await transport.close(); // while the call is in flight
        expect(captured, isA<McpWireClosedException>());
        expect(transport.isOpen, isFalse);
        expect(transport.notifications, emitsDone);
        await expectLater(
          transport.send(const McpWireRequestListTools()),
          throwsA(isA<McpWireClosedException>()),
        );
      },
    );

    test(
      'A1: full stdio session — open, list, call, call, close (SC-001)',
      () async {
        final transport = _spawn('echo');
        addTearDown(transport.close);
        await transport.open();
        expect(transport.isOpen, isTrue);
        final list = await transport.send(const McpWireRequestListTools());
        final tools = ((list as McpWireResponseOk).payload['tools'] as List)
            .cast<Map<dynamic, dynamic>>();
        expect(tools.single['name'], 'echo');
        expect(tools.single['paramsSchema'], {'type': 'object'});
        final call = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {'k': 'v'}),
        );
        expect((call as McpWireResponseOk).payload, {
          'echo': {'k': 'v'},
        });
        final call2 = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {'n': 2}),
        );
        expect((call2 as McpWireResponseOk).payload, {
          'echo': {'n': 2},
        });
        await transport.close();
        expect(transport.isOpen, isFalse);
      },
    );
  });
}
