// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/012-agent-hooks-pipeline/spec.md with this attribution retained.
//
// Hand-curated plain Dart (no @Zorphy codegen) — follows the documented
// conversational-model precedent (agent_message.dart, llm_client.dart):
// these classes embed non-Zorphy engine types (LlmRequest, AgentMessage),
// so the hand-curated precedent applies.

import '../llm/llm_client.dart';
import '../types.dart';

/// The five behaviors a hook result can request (spec 012 US3). Which
/// actions are legal depends on the hook point — each result class encodes
/// its own legal subset.
enum HookAction {
  /// Continue the pipeline unchanged.
  continue_,

  /// Continue with the modified context.
  modify,

  /// Deny the guarded action at this hook point.
  deny,

  /// Abort the run via [HookAbortError].
  abort,

  /// Retry the current step.
  retry,
}

/// The typed abort error (spec 012 FR-004 / SC-003): thrown by the
/// pipeline at the offending hook; the engine stops the run.
class HookAbortError implements Exception {
  /// The hook name.
  final String hookName;

  /// The reason.
  final String reason;

  /// Creates a hook abort error.
  HookAbortError({required this.hookName, required this.reason});

  @override
  String toString() => 'HookAbortError(hook: $hookName, reason: $reason)';
}

// ---------------------------------------------------------------------------
// Contexts — one per lifecycle point (spec 012 FR-003)
// ---------------------------------------------------------------------------

/// The before run hook context.
class BeforeRunHookContext {
  /// The run identifier.
  final String runId;

  /// The messages.
  final List<AgentMessage> messages;

  /// Creates a before run hook context.
  const BeforeRunHookContext({required this.runId, required this.messages});
}

/// The model call hook context.
class ModelCallHookContext {
  /// The request.
  final LlmRequest request;

  /// Creates a model call hook context.
  const ModelCallHookContext({required this.request});
}

/// The model chunk hook context.
class ModelChunkHookContext {
  /// The chunk.
  final LlmResponseChunk chunk;

  /// Creates a model chunk hook context.
  const ModelChunkHookContext({required this.chunk});
}

/// The after model call hook context.
class AfterModelCallHookContext {
  /// The request.
  final LlmRequest request;

  /// The response.
  final LlmResponse response;

  /// Creates an after model call hook context.
  const AfterModelCallHookContext({
    required this.request,
    required this.response,
  });
}

/// The tool call hook context.
class ToolCallHookContext {
  /// The tool call.
  final LlmToolCall toolCall;

  /// Creates a tool call hook context.
  const ToolCallHookContext({required this.toolCall});
}

/// The after tool call hook context.
class AfterToolCallHookContext {
  /// The tool call.
  final LlmToolCall toolCall;

  /// The result.
  final String result;

  /// Whether error.
  final bool isError;

  /// Creates an after tool call hook context.
  const AfterToolCallHookContext({
    required this.toolCall,
    required this.result,
    required this.isError,
  });
}

/// The turn completion hook context.
class TurnCompletionHookContext {
  /// The turn number.
  final int turnNumber;

  /// The messages.
  final List<AgentMessage> messages;

  /// Creates a turn completion hook context.
  const TurnCompletionHookContext({
    required this.turnNumber,
    required this.messages,
  });
}

/// The persist state hook context.
class PersistStateHookContext {
  /// The messages.
  final List<AgentMessage> messages;

  /// Creates a persist state hook context.
  const PersistStateHookContext({required this.messages});
}

/// The after run hook context.
class AfterRunHookContext {
  /// The final messages.
  final List<AgentMessage> finalMessages;

  /// The outcome.
  final String outcome;

  /// Creates an after run hook context.
  const AfterRunHookContext({
    required this.finalMessages,
    required this.outcome,
  });
}

// ---------------------------------------------------------------------------
// Results — one per lifecycle point (spec 012 FR-003, US3)
// ---------------------------------------------------------------------------

/// Result of the before run hook operation.
class BeforeRunHookResult {
  /// The action.
  final HookAction action;

  /// The messages.
  final List<AgentMessage>? messages;

  /// The abort reason.
  final String? abortReason;

  /// Creates a before run hook result (continue variant).
  const BeforeRunHookResult.continue_()
    : action = HookAction.continue_,
      messages = null,
      abortReason = null;

  /// Creates a before run hook result (modify variant).
  const BeforeRunHookResult.modify(List<AgentMessage> this.messages)
    : action = HookAction.modify,
      abortReason = null;

  /// Creates a before run hook result (abort variant).
  const BeforeRunHookResult.abort({String? reason})
    : action = HookAction.abort,
      messages = null,
      abortReason = reason;
}

/// Result of the model call hook operation.
class ModelCallHookResult {
  /// The action.
  final HookAction action;

  /// The request.
  final LlmRequest? request;

  /// The abort reason.
  final String? abortReason;

  /// Creates a model call hook result (continue variant).
  const ModelCallHookResult.continue_()
    : action = HookAction.continue_,
      request = null,
      abortReason = null;

  /// Creates a model call hook result (modify variant).
  const ModelCallHookResult.modify(LlmRequest this.request)
    : action = HookAction.modify,
      abortReason = null;

  /// Creates a model call hook result (abort variant).
  const ModelCallHookResult.abort({String? reason})
    : action = HookAction.abort,
      request = null,
      abortReason = reason;
}

/// Result of the model chunk hook operation.
class ModelChunkHookResult {
  /// The action.
  final HookAction action;

  /// The abort reason.
  final String? abortReason;

  /// Creates a model chunk hook result (continue variant).
  const ModelChunkHookResult.continue_()
    : action = HookAction.continue_,
      abortReason = null;

  /// Creates a model chunk hook result (abort variant).
  const ModelChunkHookResult.abort({String? reason})
    : action = HookAction.abort,
      abortReason = reason;
}

/// Result of the after model call hook operation.
class AfterModelCallHookResult {
  /// The action.
  final HookAction action;

  /// The response.
  final LlmResponse? response;

  /// The abort reason.
  final String? abortReason;

  /// Creates an after model call hook result (continue variant).
  const AfterModelCallHookResult.continue_()
    : action = HookAction.continue_,
      response = null,
      abortReason = null;

  /// Creates an after model call hook result (modify variant).
  const AfterModelCallHookResult.modify(LlmResponse this.response)
    : action = HookAction.modify,
      abortReason = null;

  /// Creates an after model call hook result (retry variant).
  const AfterModelCallHookResult.retry()
    : action = HookAction.retry,
      response = null,
      abortReason = null;

  /// Creates an after model call hook result (abort variant).
  const AfterModelCallHookResult.abort({String? reason})
    : action = HookAction.abort,
      response = null,
      abortReason = reason;
}

/// Result of the tool call hook operation.
class ToolCallHookResult {
  /// The action.
  final HookAction action;

  /// The tool call.
  final LlmToolCall? toolCall;

  /// The deny result.
  final String? denyResult;

  /// Whether deny is error.
  final bool denyIsError;

  /// The abort reason.
  final String? abortReason;

  /// Creates a tool call hook result (continue variant).
  const ToolCallHookResult.continue_()
    : action = HookAction.continue_,
      toolCall = null,
      denyResult = null,
      denyIsError = false,
      abortReason = null;

  /// Creates a tool call hook result (modify variant).
  const ToolCallHookResult.modify(LlmToolCall this.toolCall)
    : action = HookAction.modify,
      denyResult = null,
      denyIsError = false,
      abortReason = null;

  /// Creates a tool call hook result (deny variant).
  const ToolCallHookResult.deny({this.denyResult = '', this.denyIsError = true})
    : action = HookAction.deny,
      toolCall = null,
      abortReason = null;

  /// Creates a tool call hook result (abort variant).
  const ToolCallHookResult.abort({String? reason})
    : action = HookAction.abort,
      toolCall = null,
      denyResult = null,
      denyIsError = false,
      abortReason = reason;
}

/// Result of the after tool call hook operation.
class AfterToolCallHookResult {
  /// The action.
  final HookAction action;

  /// The result.
  final String? result;

  /// The is error.
  final bool? isError;

  /// The abort reason.
  final String? abortReason;

  /// Creates an after tool call hook result (continue variant).
  const AfterToolCallHookResult.continue_()
    : action = HookAction.continue_,
      result = null,
      isError = null,
      abortReason = null;

  /// Creates an after tool call hook result (modify variant).
  const AfterToolCallHookResult.modify({
    required String this.result,
    this.isError = false,
  }) : action = HookAction.modify,
       abortReason = null;

  /// Creates an after tool call hook result (abort variant).
  const AfterToolCallHookResult.abort({String? reason})
    : action = HookAction.abort,
      result = null,
      isError = null,
      abortReason = reason;
}

/// Result of the turn completion hook operation.
class TurnCompletionHookResult {
  /// The action.
  final HookAction action;

  /// The abort reason.
  final String? abortReason;

  /// Creates a turn completion hook result (continue variant).
  const TurnCompletionHookResult.continue_()
    : action = HookAction.continue_,
      abortReason = null;

  /// Creates a turn completion hook result (abort variant).
  const TurnCompletionHookResult.abort({String? reason})
    : action = HookAction.abort,
      abortReason = reason;
}

/// Result of the persist state hook operation.
class PersistStateHookResult {
  /// The action.
  final HookAction action;

  /// The messages.
  final List<AgentMessage>? messages;

  /// The abort reason.
  final String? abortReason;

  /// Creates a persist state hook result (continue variant).
  const PersistStateHookResult.continue_()
    : action = HookAction.continue_,
      messages = null,
      abortReason = null;

  /// Creates a persist state hook result (modify variant).
  const PersistStateHookResult.modify(List<AgentMessage> this.messages)
    : action = HookAction.modify,
      abortReason = null;

  /// Creates a persist state hook result (abort variant).
  const PersistStateHookResult.abort({String? reason})
    : action = HookAction.abort,
      messages = null,
      abortReason = reason;
}

/// Result of the after run hook operation.
class AfterRunHookResult {
  /// The action.
  final HookAction action;

  /// Creates an after run hook result (continue variant).
  const AfterRunHookResult.continue_() : action = HookAction.continue_;
}

// ---------------------------------------------------------------------------
// Decision envelopes — pipeline outputs where the engine must branch
// (spec 012 Key Entities)
// ---------------------------------------------------------------------------

/// The outcome of the beforeToolCall chain: either the (possibly modified)
/// tool call proceeds, or the hook chain denied it and the engine must
/// return [denyResult] without executing the tool.
class ToolCallDecision {
  /// The context.
  final ToolCallHookContext context;

  /// The deny result.
  final String? denyResult;

  /// Whether deny is error.
  final bool denyIsError;

  const ToolCallDecision._(this.context, this.denyResult, this.denyIsError);

  /// Creates a tool call decision (proceed variant).
  const ToolCallDecision.proceed(ToolCallHookContext context)
    : this._(context, null, false);

  /// Creates a tool call decision (denied variant).
  const ToolCallDecision.denied(
    ToolCallHookContext context, {
    required String result,
    bool isError = true,
  }) : this._(context, result, isError);

  /// The denied.
  bool get denied => denyResult != null;
}

/// The outcome of the afterModelCall chain: the (possibly modified)
/// response, plus whether the engine should call the LLM again.
class ModelCallDecision {
  /// The context.
  final AfterModelCallHookContext context;

  /// Whether retry.
  final bool retry;

  /// Creates a model call decision.
  const ModelCallDecision(this.context, {this.retry = false});
}

// ---------------------------------------------------------------------------
// AgentHook — 9 lifecycle points, all defaulting to continue
// (spec 012 FR-001/FR-003; plugins override only what they need)
// ---------------------------------------------------------------------------

/// The agent hook.
abstract class AgentHook {
  /// The name.
  String get name => runtimeType.toString();

  /// Befores run.
  Future<BeforeRunHookResult> beforeRun(BeforeRunHookContext context) async =>
      const BeforeRunHookResult.continue_();

  /// Befores model call.
  Future<ModelCallHookResult> beforeModelCall(
    ModelCallHookContext context,
  ) async => const ModelCallHookResult.continue_();

  /// Handles the model chunk case.
  Future<ModelChunkHookResult> onModelChunk(
    ModelChunkHookContext context,
  ) async => const ModelChunkHookResult.continue_();

  /// Afters model call.
  Future<AfterModelCallHookResult> afterModelCall(
    AfterModelCallHookContext context,
  ) async => const AfterModelCallHookResult.continue_();

  /// Befores tool call.
  Future<ToolCallHookResult> beforeToolCall(
    ToolCallHookContext context,
  ) async => const ToolCallHookResult.continue_();

  /// Afters tool call.
  Future<AfterToolCallHookResult> afterToolCall(
    AfterToolCallHookContext context,
  ) async => const AfterToolCallHookResult.continue_();

  /// Handles the turn completion case.
  Future<TurnCompletionHookResult> onTurnCompletion(
    TurnCompletionHookContext context,
  ) async => const TurnCompletionHookResult.continue_();

  /// Befores persist state.
  Future<PersistStateHookResult> beforePersistState(
    PersistStateHookContext context,
  ) async => const PersistStateHookResult.continue_();

  /// Afters run.
  Future<AfterRunHookResult> afterRun(AfterRunHookContext context) async =>
      const AfterRunHookResult.continue_();
}
