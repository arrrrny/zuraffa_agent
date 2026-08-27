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
enum HookAction { continue_, modify, deny, abort, retry }

/// The typed abort error (spec 012 FR-004 / SC-003): thrown by the
/// pipeline at the offending hook; the engine stops the run.
class HookAbortError implements Exception {
  final String hookName;
  final String reason;

  HookAbortError({required this.hookName, required this.reason});

  @override
  String toString() => 'HookAbortError(hook: $hookName, reason: $reason)';
}

// ---------------------------------------------------------------------------
// Contexts — one per lifecycle point (spec 012 FR-003)
// ---------------------------------------------------------------------------

class BeforeRunHookContext {
  final String runId;
  final List<AgentMessage> messages;
  const BeforeRunHookContext({required this.runId, required this.messages});
}

class ModelCallHookContext {
  final LlmRequest request;
  const ModelCallHookContext({required this.request});
}

class ModelChunkHookContext {
  final LlmResponseChunk chunk;
  const ModelChunkHookContext({required this.chunk});
}

class AfterModelCallHookContext {
  final LlmRequest request;
  final LlmResponse response;
  const AfterModelCallHookContext({required this.request, required this.response});
}

class ToolCallHookContext {
  final LlmToolCall toolCall;
  const ToolCallHookContext({required this.toolCall});
}

class AfterToolCallHookContext {
  final LlmToolCall toolCall;
  final String result;
  final bool isError;
  const AfterToolCallHookContext({
    required this.toolCall,
    required this.result,
    required this.isError,
  });
}

class TurnCompletionHookContext {
  final int turnNumber;
  final List<AgentMessage> messages;
  const TurnCompletionHookContext({required this.turnNumber, required this.messages});
}

class PersistStateHookContext {
  final List<AgentMessage> messages;
  const PersistStateHookContext({required this.messages});
}

class AfterRunHookContext {
  final List<AgentMessage> finalMessages;
  final String outcome;
  const AfterRunHookContext({required this.finalMessages, required this.outcome});
}

// ---------------------------------------------------------------------------
// Results — one per lifecycle point (spec 012 FR-003, US3)
// ---------------------------------------------------------------------------

class BeforeRunHookResult {
  final HookAction action;
  final List<AgentMessage>? messages;
  final String? abortReason;
  const BeforeRunHookResult.continue_()
      : action = HookAction.continue_,
        messages = null,
        abortReason = null;
  const BeforeRunHookResult.modify(List<AgentMessage> this.messages)
      : action = HookAction.modify,
        abortReason = null;
  const BeforeRunHookResult.abort({String? reason})
      : action = HookAction.abort,
        messages = null,
        abortReason = reason;
}

class ModelCallHookResult {
  final HookAction action;
  final LlmRequest? request;
  final String? abortReason;
  const ModelCallHookResult.continue_()
      : action = HookAction.continue_,
        request = null,
        abortReason = null;
  const ModelCallHookResult.modify(LlmRequest this.request)
      : action = HookAction.modify,
        abortReason = null;
  const ModelCallHookResult.abort({String? reason})
      : action = HookAction.abort,
        request = null,
        abortReason = reason;
}

class ModelChunkHookResult {
  final HookAction action;
  final String? abortReason;
  const ModelChunkHookResult.continue_()
      : action = HookAction.continue_,
        abortReason = null;
  const ModelChunkHookResult.abort({String? reason})
      : action = HookAction.abort,
        abortReason = reason;
}

class AfterModelCallHookResult {
  final HookAction action;
  final LlmResponse? response;
  final String? abortReason;
  const AfterModelCallHookResult.continue_()
      : action = HookAction.continue_,
        response = null,
        abortReason = null;
  const AfterModelCallHookResult.modify(LlmResponse this.response)
      : action = HookAction.modify,
        abortReason = null;
  const AfterModelCallHookResult.retry()
      : action = HookAction.retry,
        response = null,
        abortReason = null;
  const AfterModelCallHookResult.abort({String? reason})
      : action = HookAction.abort,
        response = null,
        abortReason = reason;
}

class ToolCallHookResult {
  final HookAction action;
  final LlmToolCall? toolCall;
  final String? denyResult;
  final bool denyIsError;
  final String? abortReason;
  const ToolCallHookResult.continue_()
      : action = HookAction.continue_,
        toolCall = null,
        denyResult = null,
        denyIsError = false,
        abortReason = null;
  const ToolCallHookResult.modify(LlmToolCall this.toolCall)
      : action = HookAction.modify,
        denyResult = null,
        denyIsError = false,
        abortReason = null;
  const ToolCallHookResult.deny(
      {this.denyResult = '', this.denyIsError = true})
      : action = HookAction.deny,
        toolCall = null,
        abortReason = null;
  const ToolCallHookResult.abort({String? reason})
      : action = HookAction.abort,
        toolCall = null,
        denyResult = null,
        denyIsError = false,
        abortReason = reason;
}

class AfterToolCallHookResult {
  final HookAction action;
  final String? result;
  final bool? isError;
  final String? abortReason;
  const AfterToolCallHookResult.continue_()
      : action = HookAction.continue_,
        result = null,
        isError = null,
        abortReason = null;
  const AfterToolCallHookResult.modify({required String this.result, this.isError = false})
      : action = HookAction.modify,
        abortReason = null;
  const AfterToolCallHookResult.abort({String? reason})
      : action = HookAction.abort,
        result = null,
        isError = null,
        abortReason = reason;
}

class TurnCompletionHookResult {
  final HookAction action;
  final String? abortReason;
  const TurnCompletionHookResult.continue_()
      : action = HookAction.continue_,
        abortReason = null;
  const TurnCompletionHookResult.abort({String? reason})
      : action = HookAction.abort,
        abortReason = reason;
}

class PersistStateHookResult {
  final HookAction action;
  final List<AgentMessage>? messages;
  final String? abortReason;
  const PersistStateHookResult.continue_()
      : action = HookAction.continue_,
        messages = null,
        abortReason = null;
  const PersistStateHookResult.modify(List<AgentMessage> this.messages)
      : action = HookAction.modify,
        abortReason = null;
  const PersistStateHookResult.abort({String? reason})
      : action = HookAction.abort,
        messages = null,
        abortReason = reason;
}

class AfterRunHookResult {
  final HookAction action;
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
  final ToolCallHookContext context;
  final String? denyResult;
  final bool denyIsError;

  const ToolCallDecision._(this.context, this.denyResult, this.denyIsError);

  const ToolCallDecision.proceed(ToolCallHookContext context)
      : this._(context, null, false);

  const ToolCallDecision.denied(ToolCallHookContext context,
      {required String result, bool isError = true})
      : this._(context, result, isError);

  bool get denied => denyResult != null;
}

/// The outcome of the afterModelCall chain: the (possibly modified)
/// response, plus whether the engine should call the LLM again.
class ModelCallDecision {
  final AfterModelCallHookContext context;
  final bool retry;

  const ModelCallDecision(this.context, {this.retry = false});
}

// ---------------------------------------------------------------------------
// AgentHook — 9 lifecycle points, all defaulting to continue
// (spec 012 FR-001/FR-003; plugins override only what they need)
// ---------------------------------------------------------------------------

abstract class AgentHook {
  String get name => runtimeType.toString();

  Future<BeforeRunHookResult> beforeRun(BeforeRunHookContext context) async =>
      const BeforeRunHookResult.continue_();

  Future<ModelCallHookResult> beforeModelCall(ModelCallHookContext context) async =>
      const ModelCallHookResult.continue_();

  Future<ModelChunkHookResult> onModelChunk(ModelChunkHookContext context) async =>
      const ModelChunkHookResult.continue_();

  Future<AfterModelCallHookResult> afterModelCall(
          AfterModelCallHookContext context) async =>
      const AfterModelCallHookResult.continue_();

  Future<ToolCallHookResult> beforeToolCall(ToolCallHookContext context) async =>
      const ToolCallHookResult.continue_();

  Future<AfterToolCallHookResult> afterToolCall(
          AfterToolCallHookContext context) async =>
      const AfterToolCallHookResult.continue_();

  Future<TurnCompletionHookResult> onTurnCompletion(
          TurnCompletionHookContext context) async =>
      const TurnCompletionHookResult.continue_();

  Future<PersistStateHookResult> beforePersistState(
          PersistStateHookContext context) async =>
      const PersistStateHookResult.continue_();

  Future<AfterRunHookResult> afterRun(AfterRunHookContext context) async =>
      const AfterRunHookResult.continue_();
}
