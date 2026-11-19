// Spec 117 (issue arrrrny/zuraffa_agent#190) — the lean, generic
// function-calling loop over the typed seam.
//
// Stack A (LlmClient + the sealed AgentMessage family) is the surface that
// ships to production; Stack B (the engine MissionRunner over ChatMessage)
// is deliberately internal. This file is the adoption answer the issue asks
// for in its option (a): a minimal runtime a downstream consumer composes
// over the barrel exports alone —
//
//   messages in -> LlmClient.generate -> LlmResponse.toolCalls dispatched
//   through a caller-supplied executor -> results appended as
//   ToolResultMessage -> repeat until a natural stop.
//
// It carries:
//   - budget + max-call enforcement that fails HONESTLY (a typed failure,
//     never a silent truncation);
//   - a per-tool-result middleware plug-in point (the PII scrubber is the
//     first real consumer), each transform seeing the result before it
//     enters the transcript;
//   - a provider-error boundary, so a dead client settles as a typed
//     failure instead of a thrown exception.
//
// Everything is injected; the loop holds no ambient state and performs no
// IO. A downstream consumer (e.g. zik_zak's 1219 order-agent brain) ports
// its hand-rolled FC loop onto this and keeps only its tool bodies.

import '../types.dart';
import 'llm_client.dart';

/// Executes one tool call and returns its result message.
///
/// The executor owns the actual tool dispatch — the loop never knows what a
/// tool does. A thrown error is caught by the loop and converted into an
/// [AgentMessage] tool-result with [ToolResultMessage.isError] set, so a
/// failing tool never crashes the mission.
typedef ToolExecutor = Future<ToolResultMessage> Function(LlmToolCall call);

/// Transforms a tool result after execution and before it is appended to the
/// transcript (spec 117 middleware seam). Return the message to store —
/// mutate [result] or return a new one. The first production consumer is a
/// PII scrubber over the result content.
typedef ToolResultMiddleware =
    ToolResultMessage Function(ToolResultMessage result);

/// Immutable configuration for a [LlmToolLoop] run.
class ToolLoopConfig {
  /// System prompt sent on the first turn (null → none).
  final String? systemPrompt;

  /// Tools advertised to the model (null → none advertised).
  final List<LlmToolSpec>? tools;

  /// Sampling temperature, forwarded verbatim.
  final double? temperature;

  /// Max output tokens, forwarded verbatim.
  final int? maxTokens;

  /// Tool-choice directive, forwarded verbatim (e.g. `'auto'`, `'required'`).
  final String? toolChoice;

  /// Upper bound on the TOTAL number of tool calls executed across the run.
  ///
  /// The loop stops and reports [ToolLoopBudgetExceeded] once this many
  /// calls have run — it never silently drops a call the model asked for.
  /// Null → unbounded (only [maxTurns] can stop the loop).
  final int? maxToolCalls;

  /// Upper bound on the number of `generate()` turns. Each iteration of the
  /// loop is one turn; the cap is enforced before each generate so a
  /// runaway model cannot spin forever. Null → unbounded.
  final int? maxTurns;

  /// Creates a loop configuration.
  const ToolLoopConfig({
    this.systemPrompt,
    this.tools,
    this.temperature,
    this.maxTokens,
    this.toolChoice,
    this.maxToolCalls,
    this.maxTurns,
  });

  /// Returns a copy with the non-null [maxToolCalls] / [maxTurns] overrides
  /// applied (the [LlmToolLoop] constructor's budget shorthands).
  ToolLoopConfig _withOverrides({int? maxToolCalls, int? maxTurns}) {
    return ToolLoopConfig(
      systemPrompt: systemPrompt,
      tools: tools,
      temperature: temperature,
      maxTokens: maxTokens,
      toolChoice: toolChoice,
      maxToolCalls: maxToolCalls ?? this.maxToolCalls,
      maxTurns: maxTurns ?? this.maxTurns,
    );
  }
}

/// Base type for every way a [LlmToolLoop] run can end without a natural
/// stop. Sealed so a caller can `switch` exhaustively over the failure
/// modes.
sealed class ToolLoopFailure {
  /// A human-readable summary.
  String get message;

  /// The transcript accumulated up to the failure, in order.
  List<AgentMessage> get messages;
}

/// The tool-call budget ([ToolLoopConfig.maxToolCalls]) was reached while the
/// model was still requesting tools — an honest stop, not a truncation.
class ToolLoopBudgetExceeded implements ToolLoopFailure {
  /// How many tool calls actually executed before the budget stopped them.
  final int executed;

  /// The configured limit.
  final int limit;

  /// The transcript at the stop.
  @override
  final List<AgentMessage> messages;

  /// Creates a budget-exceeded failure.
  const ToolLoopBudgetExceeded({
    required this.executed,
    required this.limit,
    required this.messages,
  });

  @override
  String get message =>
      'tool-call budget exhausted: $executed/$limit calls executed';
}

/// The turn budget ([ToolLoopConfig.maxTurns]) was reached while the model
/// was still requesting tools.
class ToolLoopTurnBudgetExceeded implements ToolLoopFailure {
  /// How many turns ran.
  final int turns;

  /// The configured limit.
  final int limit;

  /// The transcript at the stop.
  @override
  final List<AgentMessage> messages;

  /// Creates a turn-budget-exceeded failure.
  const ToolLoopTurnBudgetExceeded({
    required this.turns,
    required this.limit,
    required this.messages,
  });

  @override
  String get message => 'turn budget exhausted: $turns/$limit turns ran';
}

/// The LLM client threw while generating — a typed boundary so the caller
/// reacts to the failure instead of catching a raw exception.
class ToolLoopProviderError implements ToolLoopFailure {
  /// The error the client threw.
  final Object cause;

  /// The stack trace, when one was attached.
  final StackTrace? stackTrace;

  /// The transcript at the failure.
  @override
  final List<AgentMessage> messages;

  /// Creates a provider-error failure.
  const ToolLoopProviderError({
    required this.cause,
    this.stackTrace,
    required this.messages,
  });

  @override
  String get message => 'llm client failed: $cause';
}

/// The terminal result of a [LlmToolLoop] run.
class ToolLoopResult {
  /// Whether the model reached a natural stop (`finishReason == 'stop'`).
  final bool finished;

  /// The failure that stopped the loop early, or null on a natural stop.
  final ToolLoopFailure? failure;

  /// The full transcript: the seed messages followed by every assistant
  /// turn and tool-result message appended during the run.
  final List<AgentMessage> messages;

  /// Every tool call executed across the run, in order.
  final List<LlmToolCall> toolCalls;

  /// The config the run used (echoed for caller convenience).
  final ToolLoopConfig config;

  /// Creates a loop result.
  const ToolLoopResult({
    required this.finished,
    required this.failure,
    required this.messages,
    required this.toolCalls,
    required this.config,
  });
}

/// A minimal, generic function-calling runtime over the typed seam.
///
/// Compose it over any [LlmClient] whose [LlmResponse] parses real
/// `tool_calls` (the shipped `OpenAiCompatibleClient` does). The loop owns
/// only the turn/dispatch/budget cycle; the tool bodies, the transcript
/// policy and the result transforms are all injected.
class LlmToolLoop {
  final LlmClient _client;
  final ToolExecutor _execute;
  final List<ToolResultMiddleware> _middleware;
  final ToolLoopConfig _config;

  /// Creates a tool loop.
  ///
  /// [config] defaults to an empty [ToolLoopConfig]; [middleware] runs in
  /// order on every tool result before it is appended to the transcript.
  /// [maxToolCalls] and [maxTurns] are shorthands that override the matching
  /// [config] fields, so the common "just cap the budget" case needs no
  /// config object.
  LlmToolLoop(
    this._client,
    this._execute, {
    ToolLoopConfig config = const ToolLoopConfig(),
    List<ToolResultMiddleware> middleware = const [],
    int? maxToolCalls,
    int? maxTurns,
  }) : _config = config._withOverrides(
         maxToolCalls: maxToolCalls,
         maxTurns: maxTurns,
       ),
       _middleware = List.unmodifiable(middleware);

  /// Runs the loop to completion.
  ///
  /// [seed] is the opening transcript (typically one [UserMessage]); the
  /// returned [ToolLoopResult.messages] contains it plus everything the run
  /// appended. The loop stops on the model's first natural `finishReason ==
  /// 'stop'`, on a budget/turn cap (honest failure), or when the client
  /// throws (typed [ToolLoopProviderError]).
  Future<ToolLoopResult> run(List<AgentMessage> seed) async {
    final messages = <AgentMessage>[...seed];
    final executed = <LlmToolCall>[];
    var turns = 0;

    while (true) {
      if (_config.maxTurns != null && turns >= _config.maxTurns!) {
        return ToolLoopResult(
          finished: false,
          failure: ToolLoopTurnBudgetExceeded(
            turns: turns,
            limit: _config.maxTurns!,
            messages: List.unmodifiable(messages),
          ),
          messages: List.unmodifiable(messages),
          toolCalls: List.unmodifiable(executed),
          config: _config,
        );
      }
      turns++;

      final LlmResponse response;
      try {
        response = await _client.generate(
          LlmRequest(
            systemPrompt: _config.systemPrompt,
            messages: List.unmodifiable(messages),
            tools: _config.tools,
            temperature: _config.temperature,
            maxTokens: _config.maxTokens,
            toolChoice: _config.toolChoice,
          ),
        );
      } on Object catch (error, stackTrace) {
        return ToolLoopResult(
          finished: false,
          failure: ToolLoopProviderError(
            cause: error,
            stackTrace: stackTrace,
            messages: List.unmodifiable(messages),
          ),
          messages: List.unmodifiable(messages),
          toolCalls: List.unmodifiable(executed),
          config: _config,
        );
      }

      final hasToolCalls = response.toolCalls.isNotEmpty;

      // Append the assistant's turn to the transcript exactly as the model
      // produced it: text + any tool-call blocks.
      final assistantBlocks = <ContentBlock>[
        if (response.content.isNotEmpty) TextBlock(response.content),
        if (response.thinking != null && response.thinking!.isNotEmpty)
          ThinkingBlock(thinking: response.thinking!),
        for (final call in response.toolCalls)
          ToolCallBlock(
            id: call.id,
            name: call.name,
            arguments: call.arguments,
          ),
      ];
      messages.add(AssistantMessage(content: assistantBlocks));

      // A natural stop is `finishReason == 'stop'` with no outstanding tool
      // calls. Any other finish reason with no calls (e.g. 'length') is a
      // cut-off turn, not a stop — the loop continues.
      if (!hasToolCalls && response.finishReason == 'stop') {
        return ToolLoopResult(
          finished: true,
          failure: null,
          messages: List.unmodifiable(messages),
          toolCalls: List.unmodifiable(executed),
          config: _config,
        );
      }

      if (!hasToolCalls) {
        // No tool calls to run but not a natural stop: continue to the next
        // turn (the next generate sees the partial assistant message).
        continue;
      }

      for (final call in response.toolCalls) {
        if (_config.maxToolCalls != null &&
            executed.length >= _config.maxToolCalls!) {
          return ToolLoopResult(
            finished: false,
            failure: ToolLoopBudgetExceeded(
              executed: executed.length,
              limit: _config.maxToolCalls!,
              messages: List.unmodifiable(messages),
            ),
            messages: List.unmodifiable(messages),
            toolCalls: List.unmodifiable(executed),
            config: _config,
          );
        }

        executed.add(call);
        messages.add(_applyMiddleware(await _runTool(call)));
      }
    }
  }

  /// Runs one tool call, converting a thrown error into an error result so a
  /// failing tool never crashes the mission.
  Future<ToolResultMessage> _runTool(LlmToolCall call) async {
    try {
      return await _execute(call);
    } on Object catch (error) {
      return ToolResultMessage(
        toolCallId: call.id,
        toolName: call.name,
        content: 'tool execution failed: $error',
        isError: true,
      );
    }
  }

  ToolResultMessage _applyMiddleware(ToolResultMessage result) {
    var current = result;
    for (final transform in _middleware) {
      current = transform(current);
    }
    return current;
  }
}
