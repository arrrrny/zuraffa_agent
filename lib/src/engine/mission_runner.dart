// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 069 — mission-runner: the multi-turn mission loop.
//
// The keystone runtime the repo's own headers call for. EngineLoopExecutor
// (spec 045) is the atomic "agent talks to the model" step and its header
// states: "multi-turn looping (tool dispatch, stop policies, steering
// drain) is composed by the caller on top of runTurn." This file IS that
// caller — the first code in the repo that composes a full mission:
//
//   MissionStarted -> per turn [SteeringInjected* -> TurnStarted ->
//   ToolCallStarted/ToolCallCompleted* -> TurnCompleted] -> MissionCompleted
//
// Composition (all injected, no ambient dependencies):
//   - LLM turns ........ EngineLoopExecutor (spec 045; enforces loop.maxTurns)
//   - tool dispatch .... ToolDispatcher interface (spec 003/047; no production
//                        impl exists yet — tests inject fakes, future specs
//                        inject the real registry/dispatcher)
//   - stop conditions .. StopPolicy (spec 002/027): effective turn cap
//                        min(loop.maxTurns, policy.maxTurns) + wall-clock
//                        deadline, when the policy is enabled
//   - steering ......... SteeringQueue snapshot (spec 033), drained FIFO at
//                        the start of each turn, never mutated in place
//   - events ........... the sealed EngineEvent union (issues #16-#24) via an
//                        injected sink — until this spec those types were
//                        orphaned (nothing in lib/ constructed them at runtime)
//   - time ............. injectable clock (default DateTime.now)
//
// ChatCompletion (spec 051) carries no structured tool-call payload, so the
// "which tools does the model want" decision is injected as a ToolCallPlanner
// strategy over the existing ToolCall currency type (tool_dispatcher.dart).
// The loop's continuation signal is finishReason: 'stop' + no planned calls
// ends the mission naturally; anything else continues (the model drives).
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes (tool_dispatcher.dart, agent_hooks.dart).

import 'dart:math' as math;

import '../data/providers/engine_loop/engine_loop_executor.dart';
import '../domain/entities/llm_client/chat_completion.dart';
import '../domain/entities/llm_client/chat_message.dart';
import '../domain/entities/stop_policy/stop_policy.dart';
import '../domain/entities/steering_queue/steering_queue.dart';
import 'events/engine_event.dart';
import 'tool_dispatcher.dart';

/// Terminal status of a mission run.
enum MissionStatus {
  /// The model finished naturally (`finishReason == 'stop'`, no tool calls).
  completed,

  /// The wall-clock deadline stopped the mission (distinct from the turn cap).
  budgetExhausted,

  /// The turn cap (loop.maxTurns / stopPolicy.maxTurns) was hit — a typed
  /// MaxTurnsExceeded outcome distinct from wall-clock budget exhaustion.
  maxTurnsExceeded,

  /// The provider failed terminally mid-mission.
  providerFailed,
}

/// Outcome of one mission run: id, terminal [status], turns consumed, the
/// full [transcript] (user / assistant / tool / steering messages, in order),
/// and the final assistant content as [summary] on natural completion
/// (null when the mission ended any other way).
///
/// House-pattern value semantics (spec 066): `==`/`hashCode` compare all
/// fields with element-wise transcript equality; `toString` renders id,
/// status, turns, and message count.
class MissionResult {
  final String missionId;
  final MissionStatus status;
  final int turnsUsed;
  final List<ChatMessage> transcript;
  final String? summary;

  MissionResult({
    required this.missionId,
    required this.status,
    required this.turnsUsed,
    required List<ChatMessage> transcript,
    this.summary,
  }) : transcript = List.unmodifiable(transcript);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionResult &&
          runtimeType == other.runtimeType &&
          missionId == other.missionId &&
          status == other.status &&
          turnsUsed == other.turnsUsed &&
          _listEq(transcript, other.transcript) &&
          summary == other.summary);

  static bool _listEq(List<ChatMessage> a, List<ChatMessage> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        missionId,
        status,
        turnsUsed,
        Object.hashAll(transcript),
        summary,
      );

  @override
  String toString() =>
      'MissionResult(missionId: $missionId, status: ${status.name}, '
      'turnsUsed: $turnsUsed, messages: ${transcript.length}, summary: $summary)';
}

/// Strategy mapping a completed LLM turn to the tool calls the model wants.
///
/// `ChatCompletion` carries no structured tool-call payload yet (spec 051
/// surface), so this seam is where a real LLM tool-call parser plugs in when
/// the completion value object grows tool-call fields. Until then, tests and
/// callers inject deterministic planners. The [transcript] handed to
/// [plan] is an unmodifiable view of the mission transcript so far.
abstract interface class ToolCallPlanner {
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  );
}

/// Runs a mission: the multi-turn loop composing LLM turns, tool dispatch,
/// stop policies, and steering drain, emitting the EngineEvent union along
/// the way.
///
/// A runner is single-mission: construct one per [run] call site with the
/// mission's queue/policy wired in. Every exit path emits exactly one
/// terminal [MissionCompleted] — a mission never ends without it.
class MissionRunner {
  MissionRunner({
    required EngineLoopExecutor executor,
    required ToolDispatcher toolDispatcher,
    required StopPolicy stopPolicy,
    SteeringQueue? steeringQueue,
    required void Function(EngineEvent) onEvent,
    DateTime Function()? clock,
  })  : _executor = executor,
        _toolDispatcher = toolDispatcher,
        _stopPolicy = stopPolicy,
        _queue = steeringQueue,
        _onEvent = onEvent,
        _clock = clock ?? DateTime.now;

  final EngineLoopExecutor _executor;
  final ToolDispatcher _toolDispatcher;
  final StopPolicy _stopPolicy;
  SteeringQueue? _queue;
  final void Function(EngineEvent) _onEvent;
  final DateTime Function() _clock;

  /// Runs the mission identified by [missionId], starting from [messages].
  ///
  /// [planner] decides which tools to dispatch after each non-natural
  /// completion; when null, the mission can only end naturally
  /// (`finishReason == 'stop'`) or by budget.
  Future<MissionResult> run({
    required String missionId,
    required List<ChatMessage> messages,
    ToolCallPlanner? planner,
  }) async {
    final start = _clock();
    final deadline =
        (_stopPolicy.enabled && _stopPolicy.wallClockTimeout != Duration.zero)
            ? start.add(_stopPolicy.wallClockTimeout)
            : null;
    final effectiveMaxTurns = _stopPolicy.enabled
        ? math.min(_executor.loop.maxTurns, _stopPolicy.maxTurns)
        : _executor.loop.maxTurns;

    _onEvent(MissionStarted(
      emittedAt: start,
      missionId: missionId,
      startedAt: start,
    ));

    final transcript = List<ChatMessage>.of(messages);
    var turnsUsed = 0;
    var status = MissionStatus.completed;
    String? summary;

    while (true) {
      if (turnsUsed >= effectiveMaxTurns) {
        status = MissionStatus.maxTurnsExceeded;
        break;
      }
      if (deadline != null && _clock().isAfter(deadline)) {
        status = MissionStatus.budgetExhausted;
        break;
      }

      turnsUsed++;

      // Drain the steering queue at the start of the turn: each pending
      // message becomes a user message in this turn's context and is
      // announced with a SteeringInjected event. pop() returns the drained
      // snapshot; the queue is never mutated in place (spec 033).
      while (_queue != null && !_queue!.isEmpty) {
        final popped = _queue!.pop();
        _queue = popped.queue;
        transcript.add(ChatMessage(role: 'user', content: popped.message.content));
        _onEvent(SteeringInjected(
          emittedAt: _clock(),
          content: popped.message.content,
          injectedAt: popped.message.injectedAt,
        ));
      }

      _onEvent(TurnStarted(
        emittedAt: _clock(),
        turnId: '$missionId-turn-$turnsUsed',
      ));

      final ChatCompletion completion;
      try {
        completion = await _executor.runTurn(transcript, turnNumber: turnsUsed);
      } catch (e) {
        // The turn never finished: no assistant message, no TurnCompleted.
        // The mission still gets its terminal event.
        _onEvent(ProviderError(
          emittedAt: _clock(),
          providerName: _executor.llmClient.config.id,
          error: e.toString(),
        ));
        status = MissionStatus.providerFailed;
        break;
      }

      transcript.add(ChatMessage(role: 'assistant', content: completion.content));

      final calls = (planner == null)
          ? const <ToolCall>[]
          : await planner.plan(
              completion,
              List<ChatMessage>.unmodifiable(transcript),
            );

      // Tool dispatch happens inside the turn: each planned call is
      // dispatched sequentially, its result (or error) joins the transcript
      // as a tool-role message, and the Started/Completed pair correlates
      // via callId. A failed tool does NOT abort the mission.
      for (var i = 0; i < calls.length; i++) {
        final call = calls[i];
        final callId = '$missionId-call-$turnsUsed-$i';
        _onEvent(ToolCallStarted(
          emittedAt: _clock(),
          toolName: call.toolName,
          callId: callId,
        ));
        final result = await _toolDispatcher.dispatch(
          toolName: call.toolName,
          arguments: call.arguments,
          isInternalMission: false,
        );
        transcript.add(ChatMessage(
          role: 'tool',
          content: result.success ? result.result : result.error,
        ));
        _onEvent(ToolCallCompleted(
          emittedAt: _clock(),
          toolName: call.toolName,
          callId: callId,
          ok: result.success,
        ));
      }

      _onEvent(TurnCompleted(emittedAt: _clock()));

      // Natural stop: the model finished and nothing was dispatched.
      if (calls.isEmpty && completion.finishReason == 'stop') {
        status = MissionStatus.completed;
        summary = completion.content;
        break;
      }
    }

    _onEvent(MissionCompleted(
      emittedAt: _clock(),
      missionId: missionId,
      status: status.name,
      summary: summary,
    ));

    return MissionResult(
      missionId: missionId,
      status: status,
      turnsUsed: turnsUsed,
      transcript: transcript,
      summary: summary,
    );
  }
}
