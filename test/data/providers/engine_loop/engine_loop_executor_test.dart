// Tests for the EngineLoopExecutor turn driver. Uses a fake LlmClientProvider
// so no network is touched.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';

class FakeLlmClient extends LlmClientProvider {
  FakeLlmClient()
      : super(
          config: const ProviderConfig(
            id: 'kilo',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['tencent/hy3:free'],
            timeoutMs: 1,
          ),
          apiKey: 'test-key',
        );

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    return ChatCompletion(
      content: 'turn-${messages.length}',
      finishReason: 'stop',
      usage: const TokenUsage(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
    );
  }
}

void main() {
  group('EngineLoopExecutor', () {
    final loop = const EngineLoop(
      id: 'default',
      sessionId: 's1',
      maxTurns: 3,
      wallClockTimeoutMs: 1000,
      repetitionThreshold: 2,
    );
    final executor = EngineLoopExecutor(loop, FakeLlmClient());

    test('runTurn delegates to the LLM client and returns the completion', () async {
      final completion = await executor.runTurn(
        const [ChatMessage(role: 'user', content: 'hi')],
        turnNumber: 1,
      );
      expect(completion.content, 'turn-1');
      expect(completion.finishReason, 'stop');
      expect(completion.usage.totalTokens, 2);
    });

    test('runTurn throws when turnNumber exceeds maxTurns', () async {
      expect(
        () => executor.runTurn(
          const [ChatMessage(role: 'user', content: 'hi')],
          turnNumber: 4,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('runTurn throws for non-positive turnNumber', () async {
      expect(
        () => executor.runTurn(
          const [ChatMessage(role: 'user', content: 'hi')],
          turnNumber: 0,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
