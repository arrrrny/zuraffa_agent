// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider for the LlmClient data layer. Resolves the active client
// from configuration (ProviderConfig) and performs real chat-completion calls
// through LlmHttpTransport (the allowlisted platform-I/O boundary). This
// replaces the previous UnimplementedError stub (spec 051).
//
// Secrets (apiKey) and egress (proxyUrl) are injected at construction rather
// than stored on the serializable ProviderConfig value object (Constitution:
// config-driven, not hard-coded).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/llm_client/chat_completion.dart';
import '../../../domain/entities/llm_client/chat_message.dart';
import '../../../domain/entities/llm_client/llm_client.dart';
import '../../../domain/entities/provider_config/provider_config.dart';
import '../../../domain/services/llm_client_service.dart';
import 'llm_http_transport.dart';

class LlmClientProvider
    with Loggable, FailureHandler
    implements LlmClientService {
  final ProviderConfig config;
  final String apiKey;
  final String? proxyUrl;
  final LlmHttpTransport _transport;

  LlmClientProvider({
    required this.config,
    required this.apiKey,
    this.proxyUrl,
    LlmHttpTransport? transport,
  }) : _transport = transport ?? LlmHttpTransport();

  String get _model =>
      config.models.isNotEmpty ? config.models.first : '';

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

  /// Performs a real chat completion through the configured transport.
  ///
  /// Extra capability beyond the LlmClientService contract; used by the agent
  /// runtime and the integration test to drive the model end-to-end.
  Future<ChatCompletion> complete(List<ChatMessage> messages) {
    return _transport.complete(
      baseUrl: config.baseUrl,
      apiKey: apiKey,
      proxyUrl: proxyUrl,
      model: _model,
      messages: messages,
      timeout: Duration(milliseconds: config.timeoutMs),
    );
  }
}
