// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback) and
// issue arrrrny/zuraffa_agent#124 (seam dual-path resolution).
//
// Concrete provider for the LlmClient data layer. Resolves the active client
// from configuration (ProviderConfig) and performs real chat-completion calls
// through the spec-007 LLM seam: OpenAiCompatibleClient over an LlmTransport
// (IoLlmTransport by default — the allowlisted platform-I/O adapter).
//
// Issue #124: this used to be a parallel path — complete() called
// LlmHttpTransport.complete() directly, bypassing LlmClient, so retries,
// breakers and fallback chains never applied to the provider the engine
// drives in production. It now routes through the same seam the spec-007
// clients use: a caller may inject a full LlmClient (`client:` — e.g. a
// FallbackChainClient with breakers) or just a seam transport (`transport:` —
// wrapped in an OpenAiCompatibleClient), and the default builds the canonical
// stack over IoLlmTransport.
//
// Secrets (apiKey) and egress (proxyUrl) are injected at construction rather
// than stored on the serializable ProviderConfig value object (Constitution:
// config-driven, not hard-coded). proxyUrl and ProviderConfig.timeoutMs are
// forwarded to the default IoLlmTransport (HTTP CONNECT egress +
// connectionTimeout); a caller-injected `transport`/`client` owns its own
// egress configuration.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/llm_client/chat_completion.dart';
import '../../../domain/entities/llm_client/chat_message.dart';
import '../../../domain/entities/llm_client/llm_client.dart';
import '../../../domain/entities/provider_config/provider_config.dart';
import '../../../domain/services/llm_client_service.dart';
import '../../../llm/io_llm_transport.dart';
import '../../../llm/llm_client.dart' as llm;
import '../../../llm/llm_transport.dart';
import '../../../llm/openai_compatible_client.dart';
import '../../../types.dart';

class LlmClientProvider
    with Loggable, FailureHandler
    implements LlmClientService {
  final ProviderConfig config;
  final String apiKey;
  final String? proxyUrl;
  final llm.LlmClient _client;

  LlmClientProvider({
    required this.config,
    required this.apiKey,
    this.proxyUrl,
    llm.LlmClient? client,
    LlmTransport? transport,
  }) : _client =
           client ??
           OpenAiCompatibleClient(
             providerName: config.id,
             baseUrl: config.baseUrl,
             model: config.models.isNotEmpty ? config.models.first : '',
             apiKey: apiKey,
             transport:
                 transport ??
                 IoLlmTransport(
                   provider: config.id,
                   connectionTimeout: Duration(milliseconds: config.timeoutMs),
                   proxyUrl: proxyUrl,
                 ),
           );

  String get _model => config.models.isNotEmpty ? config.models.first : '';

  /// Returns the active LlmClient snapshot resolved from configuration.
  @override
  Future<LlmClient> current(NoParams params) async {
    return LlmClient(
      id: config.id,
      providerName: config.id,
      model: _model,
      supportsStreaming: true,
      supportsThinking: true,
    );
  }

  /// Returns the count of configured/usable clients.
  @override
  Future<int> count(NoParams params) async => 1;

  /// Performs a real chat completion through the canonical LLM seam.
  ///
  /// Extra capability beyond the LlmClientService contract; used by the agent
  /// runtime and the integration test to drive the model end-to-end. Routed
  /// through [llm.LlmClient] (issue #124) — the same seam the spec-007
  /// clients use — so retry, circuit breakers and fallback chains apply to
  /// this path too.
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    final response = await _client.generate(_toLlmRequest(messages));
    return _toChatCompletion(response);
  }

  /// Converts the legacy [ChatMessage] transcript into the seam's
  /// [llm.LlmRequest].
  ///
  /// A leading `system` message becomes [llm.LlmRequest.systemPrompt] (the
  /// wire position the spec-007 clients emit); a later `system` message falls
  /// back to a user message. `tool` transcripts carry no tool-call identity in
  /// the ChatMessage value object, so they map to a ToolResultMessage with
  /// empty ids (the legacy wire form omitted tool_call_id entirely).
  llm.LlmRequest _toLlmRequest(List<ChatMessage> messages) {
    String? systemPrompt;
    final converted = <AgentMessage>[];
    for (final message in messages) {
      if (message.role == 'system' && systemPrompt == null) {
        systemPrompt = message.content;
        continue;
      }
      switch (message.role) {
        case 'assistant':
          converted.add(
            AssistantMessage(
              content: [
                TextBlock(message.content),
                if (message.thinking != null)
                  ThinkingBlock(thinking: message.thinking!),
              ],
            ),
          );
        case 'tool':
          converted.add(
            ToolResultMessage(
              toolCallId: '',
              toolName: '',
              content: message.content,
            ),
          );
        default:
          converted.add(UserMessage(content: [TextBlock(message.content)]));
      }
    }
    return llm.LlmRequest(systemPrompt: systemPrompt, messages: converted);
  }

  /// Projects the seam response back onto the legacy [ChatCompletion] shape.
  ///
  /// `thinking` (gateway reasoning) becomes `reasoning`; usage tokens map
  /// input/output -> prompt/completion with the total computed as their sum.
  ChatCompletion _toChatCompletion(llm.LlmResponse response) {
    return ChatCompletion(
      content: response.content,
      reasoning: response.thinking,
      finishReason: response.finishReason,
      usage: TokenUsage(
        promptTokens: response.usage.inputTokens,
        completionTokens: response.usage.outputTokens,
        totalTokens: response.usage.inputTokens + response.usage.outputTokens,
      ),
    );
  }
}
