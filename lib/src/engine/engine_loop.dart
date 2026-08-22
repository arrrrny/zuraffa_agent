// Copyright 2024, ported patterns from pi_agent/dart_agent_core under MIT license
// Original: https://github.com/pi_agent/dart_agent_core
// MIT License - see LICENSE for details

/// Engine Loop public API for executing agent missions.
///
/// Implements a turn-based while-loop that executes missions by calling LLMs,
/// dispatching tools, and feeding results back until completion.
library;

import 'dart:async';
import 'dart:convert';

import '../domain/entities/engine_event/engine_event.dart';
import '../domain/entities/mission_config/mission_config.dart' show MissionConfig;
import '../domain/entities/mission_config/mission_config.dart' show MissionConfigSerialization;
import '../domain/entities/stop_policy/stop_policy.dart' show StopPolicy;
import '../domain/entities/stop_policy/stop_policy.dart' show StopPolicySerialization;
import '../domain/entities/tool_call_signature/tool_call_signature.dart' show ToolCallSignature;
import '../domain/entities/repetition_tracker/repetition_tracker.dart' show RepetitionTracker;
import 'steering.dart' show SteeringMessage, SteeringQueue;
import '../tools.dart' show ToolDispatcher;
import '../providers.dart' show LlmClient, ToolCall;

/// Configuration for mission execution.
class EngineConfig {
  /// Creates engine configuration.
  EngineConfig({
    required this.missionConfig,
    required this.llmClient,
    required this.toolDispatcher,
    this.stopPolicy,
    this.sessionStore,
    this.messageHistory = const [],
    this.toolDefinitions,
  });

  /// Mission configuration.
  final MissionConfig missionConfig;

  /// LLM client for provider communication.
  final LlmClient llmClient;

  /// Tool dispatcher for tool execution.
  final ToolDispatcher toolDispatcher;

  /// Stop policy for safety rails.
  final StopPolicy? stopPolicy;

  /// Optional session store for persistence.
  final Object? sessionStore;

  /// Prior conversation turns, already in OpenAI wire shape
  /// (`{role, content}` maps).
  ///
  /// Prepended verbatim at the very start of the assembled context, before the
  /// mission's initial prompt. Because an [EngineLoop] is single-use, this is
  /// how a caller carries a multi-message chat across engine instances.
  final List<Map<String, dynamic>> messageHistory;

  /// Full JSON-schema tool definitions passed to the provider verbatim.
  ///
  /// Each entry is an OpenAI tool definition
  /// (`{type: 'function', function: {name, description, parameters}}`). When
  /// null, the engine synthesizes name-only definitions from
  /// [MissionConfig.availableTools], which is enough for tools that take no
  /// arguments but cannot describe real parameters.
  final List<Map<String, dynamic>>? toolDefinitions;
}

/// Result of mission execution.
class MissionResult {
  /// Creates a mission result.
  MissionResult({
    required this.events,
    required this.finalOutcome,
    required this.totalTurns,
    this.finalText = '',
  });

  /// All events emitted during execution.
  final List<EngineEvent> events;

  /// Final outcome string.
  final String finalOutcome;

  /// Total number of turns executed.
  final int totalTurns;

  /// The assistant text produced across the whole mission.
  ///
  /// Non-empty per-turn texts joined with `\n`, in turn order. This is the same
  /// text streamed out as [TextDelta] events.
  final String finalText;
}

/// One completed turn, recorded in the shape it must be replayed to the
/// provider: the assistant message plus the `tool` replies it triggered.
class _TurnRecord {
  _TurnRecord({
    required this.content,
    required this.toolCalls,
    required this.toolResults,
  });

  /// Assistant content for this turn (may be empty).
  final String content;

  /// Tool calls the assistant requested in this turn (may be empty).
  final List<ToolCall> toolCalls;

  /// One `{toolCallId, content}` entry per executed tool call, in call order.
  final List<Map<String, String>> toolResults;
}

/// Main engine loop for executing agent missions.
///
/// **An instance is single-use.** [executeMission] closes the [events] stream
/// in its `finally` block, so the same [EngineLoop] cannot run a second
/// mission. Construct a new [EngineLoop] for every user turn and pass the prior
/// transcript through [EngineConfig.messageHistory].
class EngineLoop {
  /// Creates a new engine loop.
  EngineLoop(this._config) {
    _stopPolicy = _config.stopPolicy ??
        StopPolicy(
          maxTurns: 10,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 3,
          enabled: true,
        );
    _steeringQueue = SteeringQueue();
    _followUpQueue = <String>[];
    _eventController = StreamController<EngineEvent>.broadcast();
    _isRunning = false;
    _isAborted = false;
    _currentTurn = 0;
    _sequenceNumber = 0;
    _accumulatedThinking = '';
    _startTime = DateTime.now();
    _repetitionTracker = RepetitionTracker(callSignatures: {}, recentCalls: []);
    _lastToolSignature = '';
    _consecutiveRepetitions = 0;
  }

  final EngineConfig _config;
  late final StopPolicy _stopPolicy;
  late final SteeringQueue _steeringQueue;
  /// Queue of follow-up messages to continue mission after normal completion.
  late final List<String> _followUpQueue;
  late final StreamController<EngineEvent> _eventController;
  bool _isRunning = false;
  bool _isAborted = false;
  int _currentTurn = 0;
  int _sequenceNumber = 0;
  String _accumulatedThinking = '';
  // Completed turns in chronological order, used to rebuild the provider
  // context (assistant message + its tool replies) on every subsequent turn.
  final List<_TurnRecord> _turnRecords = [];
  // Non-empty assistant text per turn, joined into MissionResult.finalText.
  final List<String> _turnTexts = [];
  // Wall-clock timeout tracking
  late DateTime _startTime;
  // Repetition detection tracking
  late RepetitionTracker _repetitionTracker;
  // Track consecutive repetitions of the same tool signature
  String _lastToolSignature = '';
  int _consecutiveRepetitions = 0;

  /// Stream of all lifecycle events.
  Stream<EngineEvent> get events => _eventController.stream;

  /// Whether the engine is currently running.
  bool get isRunning => _isRunning;

  /// Whether the mission has been aborted.
  bool get isAborted => _isAborted;

  /// Current turn number (1-indexed).
  int get currentTurn => _currentTurn;

  /// Executes a mission from start to completion.
  ///
  /// Returns a [MissionResult] containing all events and the final outcome.
  Future<MissionResult> executeMission() async {
    if (_isRunning) {
      throw StateError('Engine is already running');
    }

    _isRunning = true;
    _isAborted = false;
    _currentTurn = 0;
    _sequenceNumber = 0;

    final events = <EngineEvent>[];
    final completer = Completer<MissionResult>();

    // Subscribe to events
    final subscription = _eventController.stream.listen(
      (event) {
        events.add(event);
        if (event is MissionCompleted) {
          completer.complete(MissionResult(
            events: List.from(events),
            finalOutcome: event.outcome,
            totalTurns: _currentTurn,
            finalText: _turnTexts.join('\n'),
          ));
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    try {
      // Emit MissionStarted event
      await _emitEvent(MissionStarted(
        eventId: _generateEventId(),
        sequenceNumber: _nextSequenceNumber(),
        timestamp: DateTime.now(),
        missionId: _config.missionConfig.missionId,
        config: _config.missionConfig.toJson(),
      ));

      // Main execution loop
      while (!_isAborted && !_shouldStop()) {
        _currentTurn++;
        final finishReason = await _executeTurn();

        // If LLM indicates completion (no more tool calls and has content)
        if (finishReason == 'stop') {
          // Check if there are follow-up messages to continue the mission
          if (_followUpQueue.isNotEmpty) {
            final followUpMessage = _followUpQueue.removeAt(0);
            // Add the follow-up as a steering message for the next turn
            _steeringQueue.enqueue(SteeringMessage(
              id: _generateEventId(),
              content: '[Follow-up]: $followUpMessage',
              injectionPoint: _currentTurn + 1,
            ));
            // Emit SteeringInjected event for the follow-up
            await _emitEvent(SteeringInjected(
              eventId: _generateEventId(),
              sequenceNumber: _nextSequenceNumber(),
              timestamp: DateTime.now(),
              missionId: _config.missionConfig.missionId,
              messageId: _generateEventId(),
              content: '[Follow-up]: $followUpMessage',
              injectionPoint: _currentTurn + 1,
            ));
            // Continue the loop - don't break
            continue;
          }
          break;
        }

        if (_isAborted) break;
      }

      // If loop ended without MissionCompleted, emit completion
      if (!_isAborted && !completer.isCompleted) {
        await _emitEvent(MissionCompleted(
          eventId: _generateEventId(),
          sequenceNumber: _nextSequenceNumber(),
          timestamp: DateTime.now(),
          missionId: _config.missionConfig.missionId,
          outcome: _determineOutcome(),
          errorMessage: _isAborted ? 'Mission aborted' : null,
          totalTurns: _currentTurn,
        ));
      }

      return await completer.future;
    } finally {
      await subscription.cancel();
      _isRunning = false;
      await _eventController.close();
    }
  }

  /// Injects a steering message to be processed before the next turn.
  ///
  /// The message will be added to the LLM context at the next turn boundary.
  /// Throws [StateError] if called after mission completion.
  void injectSteering(String message, {int? injectionPoint}) {
    if (!_isRunning) {
      throw StateError('Cannot inject steering: engine is not running');
    }
    if (_isAborted) {
      throw StateError('Cannot inject steering: mission has been aborted');
    }

    final point = injectionPoint ?? (_currentTurn + 1);
    _steeringQueue.enqueue(SteeringMessage(
      id: _generateEventId(),
      content: message,
      injectionPoint: point,
    ));

    // Emit SteeringInjected event
    _emitEvent(SteeringInjected(
      eventId: _generateEventId(),
      sequenceNumber: _nextSequenceNumber(),
      timestamp: DateTime.now(),
      missionId: _config.missionConfig.missionId,
      messageId: _generateEventId(),
      content: message,
      injectionPoint: point,
    ));
  }

  /// Adds a follow-up message to continue the mission after normal completion.
  ///
  /// Follow-up messages are processed when the LLM indicates completion (finishReason == 'stop').
  /// The mission will continue with the follow-up message as the next user input instead of ending.
  /// Throws [StateError] if called when the engine is not running.
  void addFollowUp(String message) {
    if (!_isRunning) {
      throw StateError('Cannot add follow-up: engine is not running');
    }
    _followUpQueue.add(message);
  }

  /// Aborts the currently running mission.
  ///
  /// Cancels in-flight operations and emits a final MissionCompleted event
  /// with outcome "error".
  Future<void> abort() async {
    if (!_isRunning) return;

    _isAborted = true;

    // Emit abort event
    await _emitEvent(MissionCompleted(
      eventId: _generateEventId(),
      sequenceNumber: _nextSequenceNumber(),
      timestamp: DateTime.now(),
      missionId: _config.missionConfig.missionId,
      outcome: 'error',
      errorMessage: 'Mission aborted by user',
      totalTurns: _currentTurn,
    ));
  }

  /// Checks if the stop policy conditions are met.
  bool _shouldStop() {
    if (!_stopPolicy.enabled) return false;
    if (_currentTurn >= _stopPolicy.maxTurns) return true;
    
    // Check wall-clock timeout
    final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    if (elapsedMs >= _stopPolicy.wallClockTimeoutMs) return true;
    
    // Check repetition detection
    if (_hasRepetitivePattern()) return true;
    
    return false;
  }

  /// Determines the final outcome based on stop conditions.
  String _determineOutcome() {
    if (_isAborted) return 'error';
    if (_currentTurn >= _stopPolicy.maxTurns) return 'max_turns_exceeded';
    
    final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    if (elapsedMs >= _stopPolicy.wallClockTimeoutMs) return 'timeout';
    
    if (_hasRepetitivePattern()) return 'loop_detected';
    
    return 'success';
  }

  /// Checks if the recent tool call pattern indicates repetition.
  bool _hasRepetitivePattern() {
    if (!_stopPolicy.enabled) return false;
    // repetitionThreshold = number of REPETITIONS allowed (not including first occurrence)
    // So threshold=3 means: 1st occurrence + 3 repetitions = 4 total before stopping
    // Stop when consecutive count EXCEEDS threshold (i.e., at threshold+1)
    return _consecutiveRepetitions > _stopPolicy.repetitionThreshold;
  }

  /// Records a tool call signature for repetition detection.
  void _recordToolCallSignature(ToolCall toolCall) {
    // Normalize arguments by sorting keys and removing non-deterministic fields
    final normalizedArgs = _normalizeArguments(toolCall.arguments);
    final signature = ToolCallSignature(
      toolName: toolCall.name,
      normalizedArgs: normalizedArgs,
    );
    // Key on the semantic fields only. [ToolCallSignature] is `autoId: true`,
    // so its generated `id` is a fresh uuid per instance and any key derived
    // from `toJson`/`toJsonLean` is unique every time — which silently
    // disabled repetition detection entirely.
    final signatureKey = '${signature.toolName}|${signature.normalizedArgs}';
    
    // Update call signatures count (for potential future use)
    final newCallSignatures = Map<String, int>.from(_repetitionTracker.callSignatures);
    newCallSignatures[signatureKey] = (newCallSignatures[signatureKey] ?? 0) + 1;
    
    // Update recent calls list
    final newRecentCalls = List<String>.from(_repetitionTracker.recentCalls);
    newRecentCalls.add(signatureKey);
    if (newRecentCalls.length > _stopPolicy.repetitionThreshold * 2) {
      newRecentCalls.removeAt(0);
    }
    
    _repetitionTracker = _repetitionTracker.copyWith(
      callSignatures: newCallSignatures,
      recentCalls: newRecentCalls,
    );
    
    // Track consecutive repetitions
    if (signatureKey == _lastToolSignature) {
      _consecutiveRepetitions++;
    } else {
      _lastToolSignature = signatureKey;
      _consecutiveRepetitions = 1;
    }
  }

  /// Normalizes tool arguments for consistent comparison.
  String _normalizeArguments(Map<String, dynamic> arguments) {
    // Sort keys for consistent ordering
    final sortedKeys = arguments.keys.toList()..sort();
    final buffer = StringBuffer('{');
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final value = arguments[key];
      if (i > 0) buffer.write(',');
      buffer.write('$key:');
      if (value is Map) {
        // Recursively normalize nested maps
        final nestedKeys = value.keys.toList()..sort();
        buffer.write('{');
        for (int j = 0; j < nestedKeys.length; j++) {
          final nk = nestedKeys[j];
          if (j > 0) buffer.write(',');
          buffer.write('$nk:${value[nk]}');
        }
        buffer.write('}');
      } else if (value is List) {
        // For lists, join elements
        buffer.write('[');
        for (int j = 0; j < value.length; j++) {
          if (j > 0) buffer.write(',');
          buffer.write(value[j]);
        }
        buffer.write(']');
      } else {
        buffer.write(value);
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Executes a single turn of the mission.
  ///
  /// Returns the finish reason: 'stop' (mission complete), 'tool_calls' (more tools needed),
  /// or 'length' (context length exceeded).
  Future<String> _executeTurn() async {
    // Emit TurnStarted
    await _emitEvent(TurnStarted(
      eventId: _generateEventId(),
      sequenceNumber: _nextSequenceNumber(),
      timestamp: DateTime.now(),
      missionId: _config.missionConfig.missionId,
      turnNumber: _currentTurn,
      messageIds: [], // TODO: Track message IDs
    ));

    try {
      // Assemble context with any steering messages
      final context = await _assembleContext();

      // Prefer the caller's real JSON schemas; fall back to name-only
      // definitions synthesized from the mission's available tools.
      final toolDefinitions = _config.toolDefinitions ??
          _config.missionConfig.availableTools.map((toolName) {
            return <String, dynamic>{
              'type': 'function',
              'function': {
                'name': toolName,
                'description': 'Tool: $toolName',
                'parameters': {
                  'type': 'object',
                  'properties': <String, dynamic>{},
                  'additionalProperties': true,
                },
              },
            };
          }).toList();

      // Call LLM using streaming to capture thinking deltas
      final stream = _config.llmClient.stream(
        messages: context,
        tools: toolDefinitions,
        config: {},
      );

      String accumulatedContent = '';
      final List<ToolCall> accumulatedToolCalls = [];
      String? finishReason;
      int thinkingDeltaIndex = 0;
      int textDeltaIndex = 0;

      await for (final chunk in stream) {
        if (_isAborted) break;

        // Handle thinking delta
        if (chunk.thinking != null && chunk.thinking!.isNotEmpty) {
          _accumulatedThinking += chunk.thinking!;
          await _emitEvent(ThinkingDelta(
            eventId: _generateEventId(),
            sequenceNumber: _nextSequenceNumber(),
            timestamp: DateTime.now(),
            missionId: _config.missionConfig.missionId,
            content: chunk.thinking!,
            deltaIndex: thinkingDeltaIndex,
            isComplete: false,
          ));
          thinkingDeltaIndex++;
        }

        // Accumulate and stream out content
        if (chunk.content.isNotEmpty) {
          accumulatedContent += chunk.content;
          await _emitEvent(TextDelta(
            eventId: _generateEventId(),
            sequenceNumber: _nextSequenceNumber(),
            timestamp: DateTime.now(),
            missionId: _config.missionConfig.missionId,
            content: chunk.content,
            deltaIndex: textDeltaIndex,
            isComplete: false,
          ));
          textDeltaIndex++;
        }

        // Accumulate tool calls
        if (chunk.toolCalls.isNotEmpty) {
          accumulatedToolCalls.addAll(chunk.toolCalls);
        }

        // Check if complete
        if (chunk.isComplete) {
          finishReason = chunk.finishReason ?? 'stop';
          break;
        }
      }

      // If we got thinking, emit final thinking delta as complete
      final turnThinking = _accumulatedThinking;
      if (_accumulatedThinking.isNotEmpty) {
        await _emitEvent(ThinkingDelta(
          eventId: _generateEventId(),
          sequenceNumber: _nextSequenceNumber(),
          timestamp: DateTime.now(),
          missionId: _config.missionConfig.missionId,
          content: _accumulatedThinking,
          deltaIndex: thinkingDeltaIndex,
          isComplete: true,
        ));
        _accumulatedThinking = '';
      }

      // Emit the full assistant text as a final, complete TextDelta
      if (accumulatedContent.isNotEmpty) {
        await _emitEvent(TextDelta(
          eventId: _generateEventId(),
          sequenceNumber: _nextSequenceNumber(),
          timestamp: DateTime.now(),
          missionId: _config.missionConfig.missionId,
          content: accumulatedContent,
          deltaIndex: textDeltaIndex,
          isComplete: true,
        ));
        _turnTexts.add(accumulatedContent);
      }

      // Process tool calls if any
      final toolResults = accumulatedToolCalls.isEmpty
          ? const <Map<String, String>>[]
          : await _processToolCalls(accumulatedToolCalls);

      // Record this turn so the next turn can replay it to the provider.
      // Thinking is inlined into this turn's own assistant content rather than
      // sent as a standalone assistant message (see _assembleContext).
      if (accumulatedContent.isNotEmpty || accumulatedToolCalls.isNotEmpty) {
        _turnRecords.add(_TurnRecord(
          content: turnThinking.isEmpty
              ? accumulatedContent
              : '<thinking>$turnThinking</thinking>$accumulatedContent',
          toolCalls: List.unmodifiable(accumulatedToolCalls),
          toolResults: toolResults,
        ));
      }

      // Determine finish reason
      String finalFinishReason;
      if (finishReason == 'stop' || (accumulatedToolCalls.isEmpty && accumulatedContent.isNotEmpty)) {
        finalFinishReason = 'stop';
      } else if (accumulatedToolCalls.isNotEmpty) {
        finalFinishReason = 'tool_calls';
      } else {
        finalFinishReason = 'length';
      }

      // Emit TurnCompleted
      await _emitEvent(TurnCompleted(
        eventId: _generateEventId(),
        sequenceNumber: _nextSequenceNumber(),
        timestamp: DateTime.now(),
        missionId: _config.missionConfig.missionId,
        turnNumber: _currentTurn,
        finishReason: finalFinishReason,
        toolCallCount: accumulatedToolCalls.length,
      ));
      return finalFinishReason;
    } catch (e) {
      // Emit ProviderError
      await _emitEvent(ProviderError(
        eventId: _generateEventId(),
        sequenceNumber: _nextSequenceNumber(),
        timestamp: DateTime.now(),
        missionId: _config.missionConfig.missionId,
        errorType: 'error',
        message: e.toString(),
        isRecoverable: false,
      ));
      rethrow;
    }
  }

  /// Assembles the message context for the LLM call, in OpenAI wire format.
  ///
  /// Emitted in order:
  /// 1. [EngineConfig.messageHistory] verbatim — the prior conversation.
  /// 2. The mission's initial prompt as a `user` message.
  /// 3. Steering messages due for the current turn as `user` messages.
  /// 4. For every completed turn, chronologically: one `assistant` message with
  ///    that turn's `content` plus its `tool_calls` (when it requested tools),
  ///    immediately followed by one `{role: 'tool', tool_call_id, content}`
  ///    message per tool result.
  ///
  /// Step 4's pairing is mandatory: OpenAI-compatible endpoints reject a `tool`
  /// message that is not preceded by the `assistant` message carrying the
  /// matching `tool_calls` entry. For the same reason thinking blocks are no
  /// longer emitted as standalone `assistant` messages — a bare assistant
  /// message wedged between the `tool_calls` message and its `tool` replies
  /// breaks that pairing. Each turn's reasoning is instead inlined as
  /// `<thinking>...</thinking>` at the head of that same turn's content.
  Future<List<Map<String, dynamic>>> _assembleContext() async {
    final messages = <Map<String, dynamic>>[];

    // 1. Prior conversation supplied by the caller, already in wire shape.
    messages.addAll(_config.messageHistory);

    // 2. Add initial prompt as the first user message
    messages.add({
      'role': 'user',
      'content': _config.missionConfig.initialPrompt,
    });

    // 3. Drain and add steering messages due for this turn
    final steeringMessages = _steeringQueue.drainUpTo(_currentTurn);
    for (final steering in steeringMessages) {
      messages.add({
        'role': 'user',
        'content': '[Steering]: ${steering.content}',
      });
    }

    // 4. Replay completed turns: assistant message, then its tool replies.
    for (final turn in _turnRecords) {
      final assistantMessage = <String, dynamic>{
        'role': 'assistant',
        'content': turn.content,
      };
      if (turn.toolCalls.isNotEmpty) {
        assistantMessage['tool_calls'] = [
          for (final call in turn.toolCalls)
            <String, dynamic>{
              'id': call.id,
              'type': 'function',
              'function': <String, dynamic>{
                'name': call.name,
                // The wire format requires a JSON-encoded string here, not a map.
                'arguments': jsonEncode(call.arguments),
              },
            },
        ];
      }
      messages.add(assistantMessage);

      for (final result in turn.toolResults) {
        messages.add({
          'role': 'tool',
          'tool_call_id': result['toolCallId'],
          'content': result['content'],
        });
      }
    }

    return messages;
  }

  /// Processes tool calls and emits events.
  ///
  /// Returns one `{toolCallId, content}` entry per call, in call order, ready to
  /// be replayed as `tool` messages by [_assembleContext].
  Future<List<Map<String, String>>> _processToolCalls(
      List<ToolCall> toolCalls) async {
    final turnResults = <Map<String, String>>[];
    for (int i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];

      // Emit ToolCallStarted
      await _emitEvent(ToolCallStarted(
        eventId: _generateEventId(),
        sequenceNumber: _nextSequenceNumber(),
        timestamp: DateTime.now(),
        missionId: _config.missionConfig.missionId,
        toolCallId: toolCall.id,
        toolName: toolCall.name,
        arguments: toolCall.arguments,
        callIndex: i,
      ));

      // Record tool call signature for repetition detection
      _recordToolCallSignature(toolCall);

      // Execute tool
      final stopwatch = Stopwatch()..start();
      String result;
      String? errorMessage;
      try {
        result = await _config.toolDispatcher.dispatch(toolCall.name, toolCall.arguments);
      } catch (e) {
        result = '';
        errorMessage = e.toString();
      }
      stopwatch.stop();

      // Store result for context assembly in next turn. A failed tool still
      // has to report something back, otherwise the model sees an empty reply.
      turnResults.add({
        'toolCallId': toolCall.id,
        'content': errorMessage == null ? result : 'Error: $errorMessage',
      });

      // Emit ToolCallCompleted
      await _emitEvent(ToolCallCompleted(
        eventId: _generateEventId(),
        sequenceNumber: _nextSequenceNumber(),
        timestamp: DateTime.now(),
        missionId: _config.missionConfig.missionId,
        toolCallId: toolCall.id,
        result: result,
        errorMessage: errorMessage,
        durationMs: stopwatch.elapsedMilliseconds,
      ));
    }
    return turnResults;
  }

  /// Emits an event to the stream.
  Future<void> _emitEvent(EngineEvent event) async {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Generates a unique event ID.
  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_$_sequenceNumber';
  }

  /// Gets the next sequence number.
  int _nextSequenceNumber() {
    return _sequenceNumber++;
  }
}