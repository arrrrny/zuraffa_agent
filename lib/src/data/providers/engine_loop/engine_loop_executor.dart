// HAND-CURATED — engine-loop turn executor.
//
// Drives a single engine turn: sends the conversation to the configured LLM
// client and returns the parsed completion. Enforces the loop's turn cap so a
// caller cannot exceed EngineLoop.maxTurns. This is the atomic "agent talks to
// the model" step; multi-turn looping (tool dispatch, stop policies, steering
// drain) is composed by the caller on top of runTurn. See spec 045 / issue #2.
//
// runTurnStream (issue #123) is the streaming counterpart of runTurn: it
// consumes the LLM client's chunk stream and hands it to the caller through a
// bounded buffer, so a slow consumer pauses the provider instead of growing
// without bound.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/engine_loop/engine_loop.dart';
import '../../../domain/entities/llm_client/chat_completion.dart';
import '../../../domain/entities/llm_client/chat_message.dart';
import '../../../llm/llm_client.dart';
import '../llm_client/llm_client_provider.dart';
import 'bounded_stream_buffer.dart';

/// Executes one turn of the engine loop against a configured LLM client.
class EngineLoopExecutor {
  /// [streamBufferCapacity] bounds the chunk buffer between the provider's
  /// streaming response and the consumer of [runTurnStream] (issue #123).
  /// See [boundedStream] for the pause/backpressure contract; the default
  /// (64) is generous for token-sized deltas.
  EngineLoopExecutor(
    this.loop,
    this.llmClient, {
    this.streamBufferCapacity = 64,
  }) {
    if (streamBufferCapacity < 1) {
      throw ArgumentError.value(
        streamBufferCapacity,
        'streamBufferCapacity',
        'must be >= 1',
      );
    }
  }

  final EngineLoop loop;
  final LlmClientProvider llmClient;

  /// High watermark of the chunk buffer backing [runTurnStream].
  final int streamBufferCapacity;

  /// Runs a single turn for [turnNumber] and returns the model completion.
  ///
  /// Throws [StateError] when [turnNumber] is not positive or exceeds
  /// [EngineLoop.maxTurns].
  Future<ChatCompletion> runTurn(
    List<ChatMessage> messages, {
    required int turnNumber,
  }) async {
    if (turnNumber < 1) {
      throw StateError('turnNumber must be >= 1, got $turnNumber');
    }
    if (turnNumber > loop.maxTurns) {
      throw StateError('turn $turnNumber exceeds loop cap ${loop.maxTurns}');
    }
    return llmClient.complete(messages);
  }

  /// Streams a single turn for [turnNumber] as
  /// `Stream<LlmResponseChunk>` (issue #123).
  ///
  /// The turn cap is enforced exactly like [runTurn]: a [StateError] is
  /// thrown synchronously — before the stream is subscribed — when
  /// [turnNumber] is not positive or exceeds [EngineLoop.maxTurns].
  ///
  /// ## Streaming contract
  ///
  /// The returned stream forwards the LLM client's chunks through a bounded
  /// buffer ([streamBufferCapacity]; see [boundedStream] for the full
  /// contract). In short:
  ///
  /// * **Incremental.** Chunks are delivered as the provider emits them —
  ///   content deltas, thinking deltas, tool-call chunks, and the final
  ///   `isComplete` chunk carry the same shapes as the provider clients'
  ///   `stream()` surface.
  /// * **Pausing is safe.** A consumer that pauses the subscription stops
  ///   the flow after at most [streamBufferCapacity] buffered chunks, and
  ///   the provider stream itself is paused — the HTTP socket goes quiet
  ///   (TCP backpressure) instead of the client buffering unboundedly. No
  ///   chunk is lost or reordered by pausing; on resume, buffered chunks
  ///   deliver first, then the provider is released.
  /// * **Errors and completion.** Provider errors surface on the stream's
  ///   error channel in producer order; the stream completes after the
  ///   provider's final chunk. Cancelling the subscription closes the
  ///   provider connection.
  Stream<LlmResponseChunk> runTurnStream(
    List<ChatMessage> messages, {
    required int turnNumber,
  }) {
    if (turnNumber < 1) {
      throw StateError('turnNumber must be >= 1, got $turnNumber');
    }
    if (turnNumber > loop.maxTurns) {
      throw StateError('turn $turnNumber exceeds loop cap ${loop.maxTurns}');
    }
    return boundedStream(
      llmClient.streamComplete(messages),
      capacity: streamBufferCapacity,
    );
  }
}
