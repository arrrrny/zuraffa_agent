// HAND-CURATED — engine-loop turn executor.
//
// Drives a single engine turn: sends the conversation to the configured LLM
// client and returns the parsed completion. Enforces the loop's turn cap so a
// caller cannot exceed EngineLoop.maxTurns. This is the atomic "agent talks to
// the model" step; multi-turn looping (tool dispatch, stop policies, steering
// drain) is composed by the caller on top of runTurn. See spec 045 / issue #2.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/engine_loop/engine_loop.dart';
import '../../../domain/entities/llm_client/chat_completion.dart';
import '../../../domain/entities/llm_client/chat_message.dart';
import '../llm_client/llm_client_provider.dart';

/// Executes one turn of the engine loop against a configured LLM client.
class EngineLoopExecutor {
  EngineLoopExecutor(this.loop, this.llmClient);

  final EngineLoop loop;
  final LlmClientProvider llmClient;

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
      throw StateError(
        'turn $turnNumber exceeds loop cap ${loop.maxTurns}',
      );
    }
    return llmClient.complete(messages);
  }
}
