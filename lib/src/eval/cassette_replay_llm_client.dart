// Cassette replay client for the eval harness (spec 006 FR-001).
//
// Wraps the LLM seam the engine already depends on (`LlmClientProvider`) and
// serves recorded completions from a `GoldenMission`'s cassette instead of
// calling the provider. Replay is strict by construction: once the recordings
// are exhausted the client throws rather than reaching the network, so a
// cassette that no longer covers the mission fails the eval loudly instead of
// quietly turning into a live run (and a surprise bill).
//
// The cassette's `completions` list is the recorded turn sequence, consumed in
// order. `eventOrder`, when present, is the event-type sequence the recording
// observed; the harness compares a replayed mission's emitted events against it.

import '../data/providers/llm_client/llm_client_provider.dart';
import '../domain/entities/golden_mission/golden_mission.dart';
import '../domain/entities/llm_client/chat_completion.dart';
import '../domain/entities/llm_client/chat_message.dart';
import '../domain/entities/provider_config/provider_config.dart';

/// An [LlmClientProvider] that replays recorded completions from a cassette.
class CassetteReplayLlmClient extends LlmClientProvider {
  CassetteReplayLlmClient({
    required List<Map<String, dynamic>> completions,
    this.eventOrder = const [],
    ProviderConfig? config,
  })  : _completions = List.unmodifiable(completions),
        super(
          config: config ??
              const ProviderConfig(
                id: 'cassette-replay',
                providerKind: 'replay',
                baseUrl: 'cassette://replay',
                models: ['replay'],
                timeoutMs: 1,
              ),
          apiKey: 'replay-no-key',
        );

  /// Builds a replay client from [mission]'s cassette.
  ///
  /// Reads `completions` (the recorded turns) and `eventOrder` (the recorded
  /// event-type sequence). A cassette missing `completions` yields a client
  /// that is already exhausted, which fails on the first turn rather than
  /// silently going live.
  factory CassetteReplayLlmClient.fromGoldenMission(GoldenMission mission) {
    final raw = mission.cassette['completions'];
    final order = mission.cassette['eventOrder'];
    return CassetteReplayLlmClient(
      completions: [
        if (raw is List)
          for (final entry in raw)
            if (entry is Map<String, dynamic>) entry,
      ],
      eventOrder: [
        if (order is List)
          for (final e in order) '$e',
      ],
    );
  }

  final List<Map<String, dynamic>> _completions;

  /// The event-type sequence recorded alongside the completions. Empty when the
  /// cassette carries none.
  final List<String> eventOrder;

  int _cursor = 0;
  int _liveCallCount = 0;

  /// How many recordings have been served so far.
  int get consumed => _cursor;

  /// Total recordings in the cassette.
  int get recordingCount => _completions.length;

  /// True once every recording has been served.
  bool get exhausted => _cursor >= _completions.length;

  /// How many times this client fell through to a live provider call. Always 0:
  /// the counter exists so a replayed eval can assert it, and so a future
  /// change that reintroduces live fallthrough fails the assertion.
  int get liveCallCount => _liveCallCount;

  /// Serves the next recorded completion.
  ///
  /// Throws [StateError] when the cassette is exhausted — replay never falls
  /// through to the live provider.
  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    if (exhausted) {
      throw StateError(
        'CassetteReplayLlmClient exhausted after $_cursor recording(s): '
        'the cassette does not cover this mission. Re-record it rather than '
        'replaying against a live provider.',
      );
    }
    final record = _completions[_cursor++];
    final usage = record['usage'];
    return ChatCompletion(
      content: record['content'] as String? ?? '',
      reasoning: record['reasoning'] as String?,
      finishReason: record['finishReason'] as String? ?? 'stop',
      usage: usage is Map<String, dynamic>
          ? TokenUsage.fromJson(usage)
          : const TokenUsage(
              promptTokens: 0,
              completionTokens: 0,
              totalTokens: 0,
            ),
    );
  }
}
