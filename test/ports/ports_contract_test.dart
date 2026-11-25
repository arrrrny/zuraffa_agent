// Per-port contract suite (FR-008, SC-002): every pure-Dart in-memory adapter
// satisfies the same contract a production adapter must satisfy. The suite runs
// against the in-memory adapters here with no per-adapter branching; a host's
// production adapter runs the identical assertions.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('AgentCredentialPort contract', () {
    test('resolve/store/clear round-trip', () async {
      final port = InMemoryAgentCredentialPort();
      expect(await port.resolveApiKey('openai'), isNull);
      await port.storeApiKey('openai', 'sk-test');
      expect(await port.resolveApiKey('openai'), 'sk-test');
      await port.clearApiKey('openai');
      expect(await port.resolveApiKey('openai'), isNull);
    });
  });

  group('AgentStoragePort contract', () {
    test(
      'open yields a usable pi SessionStorage and close releases it',
      () async {
        final port = InMemoryAgentStoragePort();
        final storage = await port.open();
        expect(storage, isA<SessionStorage>());
        await port.close();
      },
    );
  });

  group('AgentEgressPort contract', () {
    test(
      'send records the request and returns the scripted response',
      () async {
        final port = InMemoryAgentEgressPort(
          response: const AgentHttpResponse(statusCode: 201),
        );
        final response = await port.send(
          const AgentHttpRequest(method: 'GET', url: 'https://example.test'),
        );
        expect(response.statusCode, 201);
        expect(port.requests.single.url, 'https://example.test');
      },
    );
  });

  group('AgentTelemetryPort contract', () {
    test('records spans, events, and errors', () {
      final port = InMemoryAgentTelemetryPort();
      port.recordSpan(const AgentSpan('span'));
      port.recordEvent(const AgentTelemetryEvent('event'));
      port.recordError(StateError('boom'), null);
      expect(port.spans, hasLength(1));
      expect(port.events, hasLength(1));
      expect(port.errors, hasLength(1));
    });
  });

  group('AgentArtifactPort contract', () {
    test(
      'store returns a descriptor and resolve round-trips the bytes',
      () async {
        final port = InMemoryAgentArtifactPort();
        final descriptor = await port.store('screenshot', [1, 2, 3]);
        expect(descriptor.kind, 'screenshot');
        expect(descriptor.byteCount, 3);
        expect(await port.resolve(descriptor.id), [1, 2, 3]);
        expect(await port.resolve('unknown'), isNull);
      },
    );
  });

  group('AgentApprovalPort contract', () {
    test('request records and returns the scripted decision', () async {
      final port = InMemoryAgentApprovalPort(decision: ApprovalDecision.denied);
      final decision = await port.request(
        const AgentApprovalRequest(id: 'a1', prompt: 'allow?'),
      );
      expect(decision, ApprovalDecision.denied);
      expect(port.requests.single.id, 'a1');
    });
  });

  group('AgentLifecyclePort contract', () {
    test('records the callback order', () async {
      final port = InMemoryAgentLifecyclePort();
      await port.onOpening();
      await port.onOpened();
      await port.onClosing();
      await port.onClosed();
      expect(port.calls, ['opening', 'opened', 'closing', 'closed']);
    });
  });
}
