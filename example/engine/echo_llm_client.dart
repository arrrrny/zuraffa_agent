// A scripted LLM client: no network, no API key. It echoes the last
// user message back as the completion content and finishes the mission.

import 'package:zuraffa_agent/zuraffa_agent.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';

class EchoLlmClient extends LlmClientProvider {
  EchoLlmClient()
      : super(
          config: const ProviderConfig(
            id: 'echo',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['echo-1'],
            timeoutMs: 1,
          ),
          apiKey: 'not-a-real-key',
        );

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    final lastUser = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => const ChatMessage(role: 'user', content: '(empty)'),
    );
    return ChatCompletion(
      content: 'You asked: ${lastUser.content}. '
          'This mission ran fully in-process.',
      finishReason: 'stop',
      usage: const TokenUsage(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
    );
  }
}
