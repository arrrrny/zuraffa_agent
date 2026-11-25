// Extension-seam tests (FR-009, SC-005): the bootstrap composes installed
// extensions into pi hooks, and the factory hands the composed hooks to the
// pi construction boundary. With no extension the wrapper contributes nothing.
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('ExtensionBootstrap.compose', () {
    const bootstrap = ExtensionBootstrap();

    test('zero extensions yields all-null hooks', () {
      final hooks = bootstrap.compose(const []);
      expect(hooks.isEmpty, isTrue);
      expect(hooks.beforeToolCall, isNull);
      expect(hooks.afterToolCall, isNull);
      expect(hooks.transformContext, isNull);
      expect(hooks.convertToLlm, isNull);
    });

    test('an extension contributes only the hooks it sets', () {
      final extension = ZuraffaExtension(
        id: 'test',
        beforeToolCall: (ctx, {isAborted}) async =>
            const BeforeToolCallResult(reason: 'denied'),
      );
      final hooks = bootstrap.compose([extension]);
      expect(hooks.beforeToolCall, isNotNull);
      expect(hooks.afterToolCall, isNull);
      expect(hooks.transformContext, isNull);
      expect(hooks.convertToLlm, isNull);
    });

    test(
      'beforeToolCall chains in order and short-circuits on non-null',
      () async {
        final calls = <String>[];
        final first = ZuraffaExtension(
          id: 'first',
          beforeToolCall: (ctx, {isAborted}) async {
            calls.add('first');
            return null;
          },
        );
        final second = ZuraffaExtension(
          id: 'second',
          beforeToolCall: (ctx, {isAborted}) async {
            calls.add('second');
            return const BeforeToolCallResult(reason: 'stop');
          },
        );
        final third = ZuraffaExtension(
          id: 'third',
          beforeToolCall: (ctx, {isAborted}) async {
            calls.add('third');
            return null;
          },
        );
        final hooks = bootstrap.compose([first, second, third]);
        final result = await hooks.beforeToolCall!(_beforeCtx());
        expect(calls, [
          'first',
          'second',
        ]); // third never runs after short-circuit
        expect(result?.reason, 'stop');
      },
    );

    test(
      'transformContext threads each hook over the previous output',
      () async {
        final a = ZuraffaExtension(
          id: 'a',
          transformContext: (messages, {isAborted}) async => [
            ...messages,
            _msg('a'),
          ],
        );
        final b = ZuraffaExtension(
          id: 'b',
          transformContext: (messages, {isAborted}) async => [
            ...messages,
            _msg('b'),
          ],
        );
        final hooks = bootstrap.compose([a, b]);
        final out = await hooks.transformContext!(const []);
        expect(out.length, 2);
        expect(out.every((m) => m is UserMessage), isTrue);
      },
    );
  });

  group('factory -> adapter wiring', () {
    test('composed hooks reach the pi construction boundary', () async {
      final adapter = _CapturingAdapter();
      final factory = AgentRuntimeFactory(
        config: _config(),
        ports: _ports(),
        adapter: adapter,
      );
      final extension = ZuraffaExtension(
        id: 'ext',
        afterToolCall: (ctx, {isAborted}) async =>
            const AfterToolCallResult(isError: true),
      );
      await factory.open(extensions: [extension]);
      expect(adapter.lastHooks.afterToolCall, isNotNull);
      expect(adapter.lastHooks.beforeToolCall, isNull);
    });

    test('no extension -> the adapter receives all-null hooks', () async {
      final adapter = _CapturingAdapter();
      final factory = AgentRuntimeFactory(
        config: _config(),
        ports: _ports(),
        adapter: adapter,
      );
      await factory.open();
      expect(adapter.lastHooks.isEmpty, isTrue);
    });
  });
}

AgentMessage _msg(String text) => UserMessage.text(text);

BeforeToolCallContext _beforeCtx() => BeforeToolCallContext(
  toolCallId: 'call-1',
  toolName: 'x',
  args: const {},
  overrideArgs: (_) {},
);

AgentRuntimeConfig _config() => AgentRuntimeConfig(
  modelProvider: 'scripted',
  modelId: 'scripted-model',
  systemPrompt: 'You are a test.',
  toolNames: const [],
);

AgentPortRegistry _ports() => AgentPortRegistry(
  credentials: InMemoryAgentCredentialPort(),
  storage: InMemoryAgentStoragePort(),
  egress: InMemoryAgentEgressPort(),
  telemetry: InMemoryAgentTelemetryPort(),
  artifacts: InMemoryAgentArtifactPort(),
  approvals: InMemoryAgentApprovalPort(),
  lifecycle: InMemoryAgentLifecyclePort(),
);

/// A [PiRuntimeAdapter] that records the hooks it was handed and returns a
/// real (in-memory) pi Conversation, so the wiring is asserted without a
/// provider call.
class _CapturingAdapter implements PiRuntimeAdapter {
  AgentExtensionHooks lastHooks = AgentExtensionHooks.none;

  @override
  Future<Conversation> open(
    AgentRuntimeConfig config,
    AgentPortRegistry ports,
    AgentExtensionHooks hooks,
  ) async {
    lastHooks = hooks;
    final storage = await ports.storage.open();
    return Conversation.create(storage);
  }
}
