// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 070 — sub-agent dispatch runtime.
//
// The Kimi LaborMarket pattern from spec 005 US1, composed on the spec 069
// MissionRunner: a dispatched sub-agent runs as a full child mission in an
// ISOLATED context (system prompt + mission only), with its own tool
// allowlist enforced at the dispatch boundary, its own budgets, and its own
// instance bookkeeping. The parent receives the child's result summary and
// NOTHING else — the child transcript never crosses the boundary.
//
// Until this spec the sub-agent layer was data-only (GAP-ANALYSIS row 5:
// "Entity stubs only — Runtime missing"): SubAgentSpec (036),
// SubAgentInstance (056), SubAgentContext (055), and DispatchTool (058)
// existed with no runtime that ever spawned a sub-agent.
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes (mission_runner.dart, tool_dispatcher.dart).

import '../data/providers/engine_loop/engine_loop_executor.dart';
import '../data/providers/llm_client/llm_client_provider.dart';
import '../domain/entities/agent_tool/agent_tool.dart' show RiskTier;
import '../domain/entities/engine_loop/engine_loop.dart';
import '../domain/entities/llm_client/chat_message.dart';
import '../domain/entities/stop_policy/stop_policy.dart';
import '../domain/entities/sub_agent_context/sub_agent_context.dart';
import '../domain/entities/sub_agent_instance/sub_agent_instance.dart';
import '../domain/entities/sub_agent_spec/sub_agent_spec.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'events/engine_event.dart';
import 'mission_runner.dart';
import 'tool_dispatcher.dart';

/// Decorator enforcing a tool allowlist at the dispatch boundary.
///
/// Wraps any [ToolDispatcher]; a call whose tool name is NOT in the
/// [allowlist] is refused HERE — the inner dispatcher never sees it — and
/// yields a typed failure result (`error: 'tool not allowed: <name>'`) so
/// the child mission records the refusal as a failed tool call and continues.
/// Allowlisted calls delegate with arguments and mission context preserved.
class AllowlistToolDispatcher implements ToolDispatcher {
  AllowlistToolDispatcher({
    required ToolDispatcher inner,
    required Set<String> allowlist,
  })  : _inner = inner,
        _allowlist = allowlist;

  final ToolDispatcher _inner;
  final Set<String> _allowlist;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    if (!_allowlist.contains(toolName)) {
      return ToolDispatchResult(
        success: false,
        result: '',
        error: 'tool not allowed: $toolName',
        artifactRefs: const [],
      );
    }
    return _inner.dispatch(
      toolName: toolName,
      arguments: arguments,
      isInternalMission: isInternalMission,
    );
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => [
        for (final call in calls)
          await dispatch(
            toolName: call.toolName,
            arguments: call.arguments,
            isInternalMission: isInternalMission,
          ),
      ];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) =>
      _inner.validateSchema(schema: schema, arguments: arguments);

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) =>
      _inner.checkRiskTier(riskTier: riskTier, isInternalMission: isInternalMission);
}

/// Terminal status of a sub-agent dispatch.
enum SubAgentDispatchStatus {
  /// The child mission finished naturally.
  completed,

  /// The child mission hit its turn or wall-clock budget.
  budgetExhausted,

  /// The child mission's provider failed terminally.
  providerFailed,

  /// The child mission hit its turn cap (loop.maxTurns / policy.maxTurns).
  maxTurnsExceeded,

  /// The child mission repeated the same tool call up to the threshold.
  loopDetected,

  /// The child mission's goal was achieved before the natural stop.
  goalAchieved,

  /// The dispatch was refused before any run: admin risk tier without an
  /// explicit grant (spec 036: "the engine refuses to dispatch admin-risk
  /// sub-agents without an admin grant")
  refusedRiskTier,
}

/// Outcome of one sub-agent dispatch: ids, terminal status, the child's
/// result summary (NEVER its transcript), the updated [instance], and the
/// [context] snapshot documenting the isolation envelope.
///
/// House-pattern value semantics (spec 066).
class SubAgentDispatchResult {
  final String instanceId;
  final String specName;
  final SubAgentDispatchStatus status;
  final String? resultSummary;
  final SubAgentInstance instance;
  final SubAgentContext context;

  const SubAgentDispatchResult({
    required this.instanceId,
    required this.specName,
    required this.status,
    required this.resultSummary,
    required this.instance,
    required this.context,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubAgentDispatchResult &&
          runtimeType == other.runtimeType &&
          instanceId == other.instanceId &&
          specName == other.specName &&
          status == other.status &&
          resultSummary == other.resultSummary &&
          instance == other.instance &&
          context == other.context);

  @override
  int get hashCode => Object.hash(
        instanceId,
        specName,
        status,
        resultSummary,
        instance,
        context,
      );

  @override
  String toString() =>
      'SubAgentDispatchResult(instanceId: $instanceId, specName: $specName, '
      'status: ${status.name}, resultSummary: $resultSummary, '
      'instance: $instance, context: $context)';
}

/// Runs dispatched sub-agents: isolated child missions with allowlisted
/// tools, spec budgets, and instance bookkeeping (spec 070).
class SubAgentDispatchService {
  SubAgentDispatchService({
    required ToolDispatcher toolDispatcher,
    required LlmClientProvider llmClient,
    int fallbackMaxTurns = 10,
  })  : _toolDispatcher = toolDispatcher,
        _llmClient = llmClient,
        _fallbackMaxTurns = fallbackMaxTurns;

  final ToolDispatcher _toolDispatcher;
  final LlmClientProvider _llmClient;
  final int _fallbackMaxTurns;

  /// Dispatches [instance] (of [spec]) with [mission] and returns the
  /// result-only summary of the child run.
  ///
  /// The child context is exactly `[system: spec.systemPrompt,
  /// user: mission]`. The child's tool dispatch is allowlisted to
  /// `spec.tools`; its budgets come from the spec (`maxTurns` falling back
  /// to the service's `fallbackMaxTurns`, `wallClockTimeout` falling back
  /// to none). Child events flow to [onEvent] when supplied, keyed by
  /// `instance.id`.
  ///
  /// Admin-tier specs require [adminGranted]; otherwise the dispatch is
  /// refused before any LLM call and the instance is returned unchanged.
  Future<SubAgentDispatchResult> dispatch({
    required SubAgentSpec spec,
    required String mission,
    required SubAgentInstance instance,
    ToolCallPlanner? planner,
    void Function(EngineEvent)? onEvent,
    DateTime Function()? clock,
    bool adminGranted = false,
  }) async {
    final effectiveMaxTurns = spec.maxTurns ?? _fallbackMaxTurns;
    final context = SubAgentContext(
      id: 'ctx-${instance.id}',
      subAgentSpecId: spec.name,
      sessionId: instance.id,
      toolAllowlist: spec.tools,
      budgetTurns: effectiveMaxTurns,
    );

    // Risk-tier gate: admin sub-agents never run without an explicit grant.
    if (spec.riskTier == RiskTier.admin && !adminGranted) {
      return SubAgentDispatchResult(
        instanceId: instance.id,
        specName: spec.name,
        status: SubAgentDispatchStatus.refusedRiskTier,
        resultSummary: null,
        instance: instance,
        context: context,
      );
    }

    // Wall-clock limiting is owned by childPolicy (StopPolicy.wallClockTimeout);
    // EngineLoop.wallClockTimeoutMs is never enforced, so it stays 0 here.
    final childLoop = EngineLoop(
      id: 'sub-${instance.id}',
      sessionId: instance.id,
      maxTurns: effectiveMaxTurns,
      wallClockTimeoutMs: 0,
      repetitionThreshold: 0,
    );
    final childPolicy = StopPolicy(
      id: 'subagent-${spec.name}',
      maxTurns: effectiveMaxTurns,
      wallClockTimeout: spec.wallClockTimeout ?? Duration.zero,
      repetitionThreshold: 5,
    );
    final runner = MissionRunner(
      executor: EngineLoopExecutor(childLoop, _llmClient),
      toolDispatcher: AllowlistToolDispatcher(
        inner: _toolDispatcher,
        allowlist: spec.tools.toSet(),
      ),
      stopPolicy: childPolicy,
      onEvent: onEvent ?? (_) {},
      clock: clock,
    );

    final child = await runner.run(
      missionId: instance.id,
      messages: [
        ChatMessage(role: 'system', content: spec.systemPrompt),
        ChatMessage(role: 'user', content: mission),
      ],
      planner: planner,
    );

    final status = switch (child.status) {
      MissionStatus.completed => SubAgentDispatchStatus.completed,
      MissionStatus.budgetExhausted => SubAgentDispatchStatus.budgetExhausted,
      MissionStatus.providerFailed => SubAgentDispatchStatus.providerFailed,
      MissionStatus.maxTurnsExceeded => SubAgentDispatchStatus.maxTurnsExceeded,
      MissionStatus.loopDetected => SubAgentDispatchStatus.loopDetected,
      MissionStatus.goalAchieved => SubAgentDispatchStatus.goalAchieved,
    };

    // Bookkeeping: a run happened — totalRuns + 1, outcome recorded. The
    // input instance is immutable; the update is a new object.
    final updatedInstance = SubAgentInstance(
      id: instance.id,
      subAgentSpecId: instance.subAgentSpecId,
      parentSessionId: instance.parentSessionId,
      totalRuns: instance.totalRuns + 1,
      lastRunOutcome: status.name,
    );

    return SubAgentDispatchResult(
      instanceId: instance.id,
      specName: spec.name,
      status: status,
      resultSummary: child.summary,
      instance: updatedInstance,
      context: context,
    );
  }
}
