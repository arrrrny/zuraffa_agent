// Tests for lib/src/engine/agent_hooks.dart — Spec 012 value layer.
// Behaviors U1-U3 — see specs/012-agent-hooks-pipeline/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/engine/agent_hooks.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/types.dart';

void main() {
  group('AgentHooks value layer (U1-U3)', () {
    test('U1: a bare AgentHook subclass returns continue at all 9 points', () async {
      final hook = _BareHook();
      final request = LlmRequest(messages: [UserMessage.text('hi')]);
      final toolCall = const LlmToolCall(id: 'c1', name: 'read_file', arguments: {'p': 'a'});

      expect((await hook.beforeRun(BeforeRunHookContext(runId: 'r', messages: const []))).action, HookAction.continue_);
      expect((await hook.beforeModelCall(ModelCallHookContext(request: request))).action, HookAction.continue_);
      expect((await hook.onModelChunk(const ModelChunkHookContext(chunk: LlmResponseChunk(content: 'x')))).action, HookAction.continue_);
      expect(
        (await hook.afterModelCall(AfterModelCallHookContext(request: request, response: const LlmResponse(content: 'ok')))).action,
        HookAction.continue_,
      );
      expect((await hook.beforeToolCall(ToolCallHookContext(toolCall: toolCall))).action, HookAction.continue_);
      expect(
        (await hook.afterToolCall(AfterToolCallHookContext(toolCall: toolCall, result: 'done', isError: false))).action,
        HookAction.continue_,
      );
      expect((await hook.onTurnCompletion(const TurnCompletionHookContext(turnNumber: 1, messages: []))).action, HookAction.continue_);
      expect((await hook.beforePersistState(const PersistStateHookContext(messages: []))).action, HookAction.continue_);
      expect((await hook.afterRun(const AfterRunHookContext(finalMessages: [], outcome: 'completed'))).action, HookAction.continue_);
    });

    test('U2: typed result classes carry actions + payloads', () {
      // modify carries the new value.
      final modify = ModelCallHookResult.modify(
        LlmRequest(messages: const [], temperature: 0.9),
      );
      expect(modify.action, HookAction.modify);
      expect(modify.request!.temperature, 0.9);

      // deny carries the synthetic tool result.
      const deny = ToolCallHookResult.deny(result: 'denied by policy', isError: true);
      expect(deny.action, HookAction.deny);
      expect(deny.denyResult, 'denied by policy');
      expect(deny.denyIsError, isTrue);

      // retry flags afterModelCall.
      const retry = AfterModelCallHookResult.retry();
      expect(retry.action, HookAction.retry);

      // abort carries the reason.
      const abort = BeforeRunHookResult.abort(reason: 'nope');
      expect(abort.action, HookAction.abort);
      expect(abort.abortReason, 'nope');
    });

    test('U3: HookAbortError is a typed error carrying hookName + reason', () {
      final error = HookAbortError(hookName: 'policy_hook', reason: 'budget exhausted');
      expect(error, isA<Exception>());
      expect(error.hookName, 'policy_hook');
      expect(error.reason, 'budget exhausted');
      expect(error.toString(), contains('policy_hook'));
      expect(error.toString(), contains('budget exhausted'));
    });
  });
}

class _BareHook extends AgentHook {}
