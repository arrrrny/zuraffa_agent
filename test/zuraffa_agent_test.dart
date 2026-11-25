// Factory + facade tests (FR-003, SC-001): open returns pi's own Conversation,
// config is validated, the lifecycle port is driven, and a failed open surfaces
// the pi error as-is (no wrapper outcome type).
import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('AgentRuntimeFactory', () {
    test('open returns a pi Conversation built over in-memory ports', () async {
      final lifecycle = InMemoryAgentLifecyclePort();
      final factory = AgentRuntimeFactory(
        config: _config(),
        ports: _ports(lifecycle),
      );
      final conversation = await factory.open();
      expect(conversation, isA<Conversation>());
      expect(lifecycle.calls, ['opening', 'opened']);
    });

    test('the ZuraffaAgent facade opens the same pi Conversation', () async {
      final agent = ZuraffaAgent(config: _config(), ports: _ports());
      final conversation = await agent.open();
      expect(conversation, isA<Conversation>());
    });

    test('an empty modelProvider is rejected at construction', () {
      expect(
        () => AgentRuntimeFactory(
          config: _config(provider: ''),
          ports: _ports(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('an empty modelId is rejected at construction', () {
      expect(
        () => AgentRuntimeFactory(
          config: _config(modelId: ''),
          ports: _ports(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a failed open surfaces the error and closes the lifecycle', () async {
      final lifecycle = InMemoryAgentLifecyclePort();
      final factory = AgentRuntimeFactory(
        config: _config(),
        ports: _ports(lifecycle),
        adapter: const _ThrowingAdapter(),
      );
      await expectLater(factory.open(), throwsA(isA<StateError>()));
      expect(lifecycle.calls, ['opening', 'closed']);
    });
  });
}

AgentRuntimeConfig _config({String? provider, String? modelId}) =>
    AgentRuntimeConfig(
      modelProvider: provider ?? 'scripted',
      modelId: modelId ?? 'scripted-model',
      systemPrompt: 'You are a test.',
      toolNames: const [],
    );

AgentPortRegistry _ports([AgentLifecyclePort? lifecycle]) => AgentPortRegistry(
  credentials: InMemoryAgentCredentialPort(),
  storage: InMemoryAgentStoragePort(),
  egress: InMemoryAgentEgressPort(),
  telemetry: InMemoryAgentTelemetryPort(),
  artifacts: InMemoryAgentArtifactPort(),
  approvals: InMemoryAgentApprovalPort(),
  lifecycle: lifecycle ?? InMemoryAgentLifecyclePort(),
);

class _ThrowingAdapter implements PiRuntimeAdapter {
  const _ThrowingAdapter();

  @override
  Future<Conversation> open(
    AgentRuntimeConfig config,
    AgentPortRegistry ports,
    AgentExtensionHooks hooks,
  ) async => throw StateError('pi construction failed');
}
