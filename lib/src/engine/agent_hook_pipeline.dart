// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/012-agent-hooks-pipeline/spec.md with this attribution retained.

import 'agent_hooks.dart';

/// Chains [AgentHook]s through the 9 lifecycle points (spec 012).
///
/// Semantics (spec FR-002 / AC-4..AC-6):
/// - hooks run in **registration order** at every point;
/// - a **modify** result folds: the next hook observes the modification
///   (sequential fold), and the pipeline returns the final context to the
///   engine;
/// - an **abort** result throws [HookAbortError] at the offending hook —
///   later hooks are not called;
/// - **deny** (beforeToolCall) short-circuits into a [ToolCallDecision]
///   whose synthetic result replaces tool execution;
/// - **retry** (afterModelCall) surfaces as [ModelCallDecision.retry] —
///   the engine calls the LLM again.
class AgentHookPipeline {
  final List<AgentHook> _hooks = [];

  /// Registers a hook; insertion order governs call order at each point.
  void register(AgentHook hook) => _hooks.add(hook);

  /// All registered hooks, in registration order.
  List<AgentHook> get hooks => List.unmodifiable(_hooks);

  Never _abort(AgentHook hook, String? reason) =>
      throw HookAbortError(hookName: hook.name, reason: reason ?? 'aborted');

  // -------------------------------------------------------------------
  // beforeRun
  // -------------------------------------------------------------------

  Future<BeforeRunHookContext> beforeRun(BeforeRunHookContext context) async {
    var current = context;
    for (final hook in _hooks) {
      final result = await hook.beforeRun(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.modify:
          current = BeforeRunHookContext(
            runId: current.runId,
            messages: result.messages ?? current.messages,
          );
        case HookAction.abort:
          _abort(hook, result.abortReason);
        case HookAction.deny:
        case HookAction.retry:
          break; // not legal at this point — treated as continue
      }
    }
    return current;
  }

  // -------------------------------------------------------------------
  // beforeModelCall
  // -------------------------------------------------------------------

  Future<ModelCallHookContext> beforeModelCall(ModelCallHookContext context) async {
    var current = context;
    for (final hook in _hooks) {
      final result = await hook.beforeModelCall(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.modify:
          current = ModelCallHookContext(request: result.request ?? current.request);
        case HookAction.abort:
          _abort(hook, result.abortReason);
        case HookAction.deny:
        case HookAction.retry:
          break;
      }
    }
    return current;
  }

  // -------------------------------------------------------------------
  // onModelChunk (streaming observation)
  // -------------------------------------------------------------------

  Future<ModelChunkHookContext> onModelChunk(ModelChunkHookContext context) async {
    final current = context;
    for (final hook in _hooks) {
      final result = await hook.onModelChunk(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.abort:
          _abort(hook, result.abortReason);
        default:
          break;
      }
    }
    return current;
  }

  // -------------------------------------------------------------------
  // afterModelCall — may modify the response or request a retry
  // -------------------------------------------------------------------

  Future<ModelCallDecision> afterModelCall(AfterModelCallHookContext context) async {
    var current = context;
    var retry = false;
    for (final hook in _hooks) {
      final result = await hook.afterModelCall(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.modify:
          current = AfterModelCallHookContext(
            request: current.request,
            response: result.response ?? current.response,
          );
        case HookAction.retry:
          retry = true;
        case HookAction.abort:
          _abort(hook, result.abortReason);
        case HookAction.deny:
          break;
      }
    }
    return ModelCallDecision(current, retry: retry);
  }

  // -------------------------------------------------------------------
  // beforeToolCall — may modify the call or deny it (synthetic result)
  // -------------------------------------------------------------------

  Future<ToolCallDecision> beforeToolCall(ToolCallHookContext context) async {
    var current = context;
    for (final hook in _hooks) {
      final result = await hook.beforeToolCall(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.modify:
          current = ToolCallHookContext(
              toolCall: result.toolCall ?? current.toolCall);
        case HookAction.deny:
          return ToolCallDecision.denied(
            current,
            result: result.denyResult ?? '',
            isError: result.denyIsError,
          );
        case HookAction.abort:
          _abort(hook, result.abortReason);
        case HookAction.retry:
          break;
      }
    }
    return ToolCallDecision.proceed(current);
  }

  // -------------------------------------------------------------------
  // afterToolCall — may modify the result content / error flag
  // -------------------------------------------------------------------

  Future<AfterToolCallHookContext> afterToolCall(
      AfterToolCallHookContext context) async {
    var current = context;
    for (final hook in _hooks) {
      final result = await hook.afterToolCall(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.modify:
          current = AfterToolCallHookContext(
            toolCall: current.toolCall,
            result: result.result ?? current.result,
            isError: result.isError ?? current.isError,
          );
        case HookAction.abort:
          _abort(hook, result.abortReason);
        case HookAction.deny:
        case HookAction.retry:
          break;
      }
    }
    return current;
  }

  // -------------------------------------------------------------------
  // onTurnCompletion
  // -------------------------------------------------------------------

  Future<TurnCompletionHookContext> onTurnCompletion(
      TurnCompletionHookContext context) async {
    final current = context;
    for (final hook in _hooks) {
      final result = await hook.onTurnCompletion(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.abort:
          _abort(hook, result.abortReason);
        default:
          break;
      }
    }
    return current;
  }

  // -------------------------------------------------------------------
  // beforePersistState
  // -------------------------------------------------------------------

  Future<PersistStateHookContext> beforePersistState(
      PersistStateHookContext context) async {
    var current = context;
    for (final hook in _hooks) {
      final result = await hook.beforePersistState(current);
      switch (result.action) {
        case HookAction.continue_:
          break;
        case HookAction.modify:
          current = PersistStateHookContext(
              messages: result.messages ?? current.messages);
        case HookAction.abort:
          _abort(hook, result.abortReason);
        case HookAction.deny:
        case HookAction.retry:
          break;
      }
    }
    return current;
  }

  // -------------------------------------------------------------------
  // afterRun — terminal observation (continue only)
  // -------------------------------------------------------------------

  Future<AfterRunHookContext> afterRun(AfterRunHookContext context) async {
    final current = context;
    for (final hook in _hooks) {
      await hook.afterRun(current); // result is continue-only by contract
    }
    return current;
  }
}
