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

import 'dart:async';
import 'dart:math' as math;

import '../data/datasources/repetition_tracker/repetition_tracker_datasource.dart';
import '../data/providers/engine_loop/engine_loop_executor.dart';
import '../domain/entities/llm_client/chat_completion.dart';
import '../domain/entities/llm_client/chat_message.dart';
import '../domain/entities/stop_policy/stop_policy.dart';
import '../domain/entities/steering_message/steering_message.dart';
import '../domain/entities/steering_queue/steering_queue.dart';
import '../logging/agent_log.dart';
import '../observability/crash_reporter.dart';
import '../observability/metrics.dart';
import '../observability/traced_adapters.dart';
import '../observability/tracing.dart';
import 'events/engine_event.dart';
import 'goal_mode.dart';
import 'tool_dispatcher.dart';
import '../config/zuraffa_config.dart';
import '../security/tool_result_sanitizer.dart';

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

  /// The same tool call repeated up to the repetition threshold — a typed
  /// LoopDetected outcome distinct from the turn cap (spec 002 A9).
  loopDetected,

  /// Goal mode (spec 071): the GoalEvaluator judged the goal achieved
  /// from the transcript; the mission stopped early.
  goalAchieved,
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
  final Goal? goal;
  final bool goalAchieved;

  MissionResult({
    required this.missionId,
    required this.status,
    required this.turnsUsed,
    required List<ChatMessage> transcript,
    this.summary,
    this.goal,
    this.goalAchieved = false,
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
          summary == other.summary &&
          goal == other.goal &&
          goalAchieved == other.goalAchieved);

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
    goal,
    goalAchieved,
  );

  @override
  String toString() =>
      'MissionResult(missionId: $missionId, status: ${status.name}, '
      'turnsUsed: $turnsUsed, messages: ${transcript.length}, summary: $summary'
      '${goal != null ? ', goal: $goal' : ''}, goalAchieved: $goalAchieved)';
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
    RepetitionTrackerDatasource? repetitionTracker,
    required void Function(EngineEvent) onEvent,
    DateTime Function()? clock,
    ZuraffaConfig? config,
    ToolResultSanitizer? toolResultSanitizer,
    this.tracer,
    this.metrics,
    this.crashReporter,
  }) : _executor = executor,
       _toolDispatcher = toolDispatcher,
       _stopPolicy = stopPolicy,
       _queue = steeringQueue,
       _repetition = repetitionTracker,
       _onEvent = onEvent,
       _clock = clock ?? DateTime.now,
       _config = config,
       _toolResultSanitizer = toolResultSanitizer;

  final EngineLoopExecutor _executor;
  final ToolDispatcher _toolDispatcher;
  final StopPolicy _stopPolicy;
  SteeringQueue? _queue;
  final RepetitionTrackerDatasource? _repetition;
  final void Function(EngineEvent) _onEvent;
  final DateTime Function() _clock;

  /// Optional runtime configuration (spec 107, issue #121). When supplied,
  /// [run] validates it first and refuses to start on any issue — fail fast
  /// at startup instead of at first turn.
  final ZuraffaConfig? _config;

  /// Optional tool-output sanitizer (spec 109, issue #118). When supplied,
  /// every dispatched tool's output (success content and error text) is
  /// redacted BEFORE it joins the transcript — the LLM egress boundary.
  final ToolResultSanitizer? _toolResultSanitizer;

  /// Optional tracer (issue #133, O-1). When null, [run] emits spans
  /// through the no-op tracer — structurally present, cost-free. One
  /// `mission.run` span per [run]; child `engine.turn` / `tool.dispatch`
  /// spans per turn and per dispatch; W3C `traceparent` propagation via
  /// `Spans.propagationHeaders()`.
  final Tracer? tracer;

  /// Optional metrics seam (issue #133, O-2). When null, nothing is
  /// recorded. Wired series: `agent_llm_tokens_total{type=...}`,
  /// `agent_mission_duration_ms{status=...}`,
  /// `agent_tool_calls_failed_total` (via the wrapped dispatcher).
  final Metrics? metrics;

  /// Optional default crash reporter for [runGuarded] (issue #133, O-4);
  /// overridable per call. See `lib/src/observability/crash_reporter.dart`
  /// for the Sentry / OTLP integration contract.
  final CrashReporter? crashReporter;

  /// Appends [message] to this mission's steering / follow-up queue.
  ///
  /// The queue is a value object, so enqueueing swaps in a new snapshot. Safe
  /// to call while the mission is running — including from an event handler as
  /// a turn completes, which is how a follow-up "queued at mission end" keeps
  /// the loop going instead of letting it exit (spec 002 FR-003).
  ///
  /// Throws [StateError] when the runner was constructed without a queue.
  void enqueue(SteeringMessage message) {
    final queue = _queue;
    if (queue == null) {
      throw StateError('MissionRunner has no steering queue to enqueue into');
    }
    _queue = queue.enqueue(message);
  }

  /// Runs the mission identified by [missionId], starting from [messages].
  ///
  /// [planner] decides which tools to dispatch after each non-natural
  /// completion; when null, the mission can only end naturally
  /// (`finishReason == 'stop'`) or by budget.
  ///
  /// Goal mode (spec 071): [goal] and [goalEvaluator] must be supplied
  /// together (both or neither); with them active the runner consults the
  /// evaluator after each turn's tool dispatch and before the natural-stop
  /// check, stopping early with [MissionStatus.goalAchieved] on a true
  /// verdict. Goal mode never overrides budgets or the natural stop.
  Future<MissionResult> run({
    required String missionId,
    required List<ChatMessage> messages,
    ToolCallPlanner? planner,
    Goal? goal,
    GoalEvaluator? goalEvaluator,
  }) async {
    final config = _config;
    if (config != null) {
      final issues = config.validate();
      if (issues.isNotEmpty) {
        throw StateError(
          'MissionRunner: configuration failed startup validation '
          '(spec 107 / issue #121):\n'
          '${issues.map((i) => '  - ${i.message}').join('\n')}',
        );
      }
    }
    if ((goal == null) != (goalEvaluator == null)) {
      throw ArgumentError.value(
        goal == null ? 'goalEvaluator' : 'goal',
        'goal/goalEvaluator',
        'goal mode requires goal and goalEvaluator together (both or neither)',
      );
    }
    // Observability (issue #133): one mission.run span around the whole
    // loop, ambient so every nested startSpan resolves it as parent. The
    // span ends on every exit path; a rethrown error is recorded first.
    final tracer = this.tracer ?? const NoopTracer();
    final metrics = this.metrics ?? const NoopMetrics();
    final span = tracer.startSpan(
      'mission.run',
      attributes: {'mission.id': missionId},
    );
    final missionStart = _clock();
    try {
      return await Spans.withScope(
        span,
        () => _runLoop(
          missionId: missionId,
          messages: messages,
          planner: planner,
          goal: goal,
          goalEvaluator: goalEvaluator,
          tracer: tracer,
          metrics: metrics,
          missionSpan: span,
          missionStart: missionStart,
        ),
      );
    } catch (e, st) {
      span.recordError(e, st);
      rethrow;
    } finally {
      span.end(timestamp: _clock());
    }
  }

  /// Runs [run] inside [runZonedGuarded]: any uncaught zone error — a
  /// throwing event sink, a misbehaving planner, an error escaping the
  /// loop — is logged SEVERE on the `engine` subsystem, routed to the
  /// optional [CrashReporter] (per-call [crashReporter], else the one the
  /// runner was constructed with), and then rethrown to the caller.
  /// Observation, not suppression: the awaiting caller still sees the
  /// original error.
  ///
  /// Sentry / OTLP integration: implement [CrashReporter.record] and pass
  /// the instance here or into the constructor — see
  /// `lib/src/observability/crash_reporter.dart` for the contract.
  Future<MissionResult> runGuarded({
    required String missionId,
    required List<ChatMessage> messages,
    ToolCallPlanner? planner,
    Goal? goal,
    GoalEvaluator? goalEvaluator,
    CrashReporter? crashReporter,
  }) {
    final reporter = crashReporter ?? this.crashReporter;
    final done = Completer<MissionResult>();
    runZonedGuarded(
      () {
        run(
          missionId: missionId,
          messages: messages,
          planner: planner,
          goal: goal,
          goalEvaluator: goalEvaluator,
        ).then((result) {
          if (!done.isCompleted) done.complete(result);
        });
        // Errors from that future surface as uncaught zone errors below.
      },
      (error, stackTrace) {
        AgentLog.logger('engine').severe(
          'uncaught zone error in mission $missionId',
          error,
          stackTrace,
        );
        reporter?.record(error, stackTrace, context: {'mission.id': missionId});
        if (!done.isCompleted) done.completeError(error, stackTrace);
      },
    );
    return done.future;
  }

  Future<MissionResult> _runLoop({
    required String missionId,
    required List<ChatMessage> messages,
    ToolCallPlanner? planner,
    Goal? goal,
    GoalEvaluator? goalEvaluator,
    required Tracer tracer,
    required Metrics metrics,
    required Span missionSpan,
    required DateTime missionStart,
  }) async {
    final deadline =
        (_stopPolicy.enabled && _stopPolicy.wallClockTimeout != Duration.zero)
        ? missionStart.add(_stopPolicy.wallClockTimeout)
        : null;
    final effectiveMaxTurns = _stopPolicy.enabled
        ? math.min(_executor.loop.maxTurns, _stopPolicy.maxTurns)
        : _executor.loop.maxTurns;

    // One tool.dispatch span per dispatch + the failure counter: wrap the
    // injected dispatcher when observability is wired (issue #133).
    final ToolDispatcher dispatcher =
        (this.tracer != null || this.metrics != null)
        ? TracedToolDispatcher(_toolDispatcher, tracer, metrics: metrics)
        : _toolDispatcher;

    _onEvent(
      MissionStarted(
        emittedAt: missionStart,
        missionId: missionId,
        startedAt: missionStart,
      ),
    );
    // Spec 112 FR-005: mission lifecycle INFO — id + outcome only.
    AgentLog.missionInfo(missionId: missionId, outcome: 'started');

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
        transcript.add(
          ChatMessage(role: 'user', content: popped.message.content),
        );
        _onEvent(
          SteeringInjected(
            emittedAt: _clock(),
            content: popped.message.content,
            injectedAt: popped.message.injectedAt,
          ),
        );
      }

      _onEvent(
        TurnStarted(emittedAt: _clock(), turnId: '$missionId-turn-$turnsUsed'),
      );

      final ChatCompletion completion;
      // One engine.turn span per runTurn (issue #133, O-1); token counters
      // come off the completion's usage (O-2). The span ends on both paths.
      final turnSpan = tracer.startSpan(
        'engine.turn',
        attributes: {'turn.number': turnsUsed},
      );
      try {
        completion = await _executor.runTurn(transcript, turnNumber: turnsUsed);
      } catch (e) {
        // The turn never finished: no assistant message, no TurnCompleted.
        // The mission still gets its terminal event.
        turnSpan.recordError(e);
        missionSpan.recordError(e);
        turnSpan.end();
        _onEvent(
          ProviderError(
            emittedAt: _clock(),
            providerName: _executor.llmClient.config.id,
            error: e.toString(),
          ),
        );
        status = MissionStatus.providerFailed;
        break;
      }
      metrics
          .counter('agent_llm_tokens_total', labels: {'type': 'input'})
          .inc(completion.usage.promptTokens);
      metrics
          .counter('agent_llm_tokens_total', labels: {'type': 'output'})
          .inc(completion.usage.completionTokens);
      turnSpan.end();

      // The assistant message carries this turn's thinking block alongside the
      // tool-role results that follow it, so a thinking model's reasoning is
      // still in context when turn N+1 is assembled (spec 002 FR-002).
      transcript.add(
        ChatMessage(
          role: 'assistant',
          content: completion.content,
          thinking: completion.reasoning,
        ),
      );

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
      var looping = false;
      for (var i = 0; i < calls.length; i++) {
        final call = calls[i];
        final callId = '$missionId-call-$turnsUsed-$i';
        _onEvent(
          ToolCallStarted(
            emittedAt: _clock(),
            toolName: call.toolName,
            callId: callId,
          ),
        );
        final result = await dispatcher.dispatch(
          toolName: call.toolName,
          arguments: call.arguments,
          isInternalMission: false,
        );
        // Sanitize at the egress boundary (spec 109, issue #118): the
        // transcript is what the next request relays to the model vendor.
        final rawContent = result.success ? result.result : result.error;
        final sanitizer = _toolResultSanitizer;
        final toolContent = sanitizer == null
            ? rawContent
            : sanitizer.sanitize(rawContent).content;
        transcript.add(ChatMessage(role: 'tool', content: toolContent));
        _onEvent(
          ToolCallCompleted(
            emittedAt: _clock(),
            toolName: call.toolName,
            callId: callId,
            ok: result.success,
          ),
        );

        // Repetition guard: the dispatched call's signature is recorded and
        // re-evaluated against the tracker's threshold. Hitting it ends the
        // mission with the typed loopDetected outcome rather than burning the
        // remaining turn budget on the same call (spec 002 A9).
        final tracker = _repetition;
        if (tracker != null) {
          final signature = '${call.toolName}|${call.arguments}';
          await tracker.record(signature, at: _clock());
          if (await tracker.isLooping(signature, now: _clock())) {
            looping = true;
            break;
          }
        }
      }

      if (looping) {
        status = MissionStatus.loopDetected;
        _onEvent(TurnCompleted(emittedAt: _clock()));
        break;
      }

      _onEvent(TurnCompleted(emittedAt: _clock()));

      // Goal mode (spec 071): consult the evaluator AFTER this turn's tool
      // dispatch (tool results are visible) and BEFORE the natural-stop
      // check (a goal met on the model's stop turn still reports
      // goalAchieved). A true verdict stops the mission early.
      if (goal != null &&
          goalEvaluator!.isAchieved(
            goal,
            List<ChatMessage>.unmodifiable(transcript),
          )) {
        status = MissionStatus.goalAchieved;
        summary = completion.content;
        break;
      }

      // Natural stop: the model finished and nothing was dispatched. A
      // follow-up queued while this turn was running (including from the
      // TurnCompleted handler above) is not a finished mission: the loop
      // continues and the next turn drains it (spec 002 FR-003).
      if (calls.isEmpty && completion.finishReason == 'stop') {
        if (_queue != null && !_queue!.isEmpty) continue;
        status = MissionStatus.completed;
        summary = completion.content;
        break;
      }
    }

    _onEvent(
      MissionCompleted(
        emittedAt: _clock(),
        missionId: missionId,
        status: status.name,
        summary: summary,
      ),
    );
    AgentLog.missionInfo(missionId: missionId, outcome: status.name);

    missionSpan.setAttribute('mission.status', status.name);
    metrics.histogram(
      'agent_mission_duration_ms',
      _clock().difference(missionStart).inMilliseconds.toDouble(),
      labels: {'status': status.name},
    );

    return MissionResult(
      missionId: missionId,
      status: status,
      turnsUsed: turnsUsed,
      transcript: transcript,
      summary: summary,
      goal: goal,
      goalAchieved: status == MissionStatus.goalAchieved,
    );
  }
}
