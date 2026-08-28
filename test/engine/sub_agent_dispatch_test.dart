// Tests for the sub-agent dispatch runtime (spec 070): isolated child
// missions on top of the MissionRunner, tool-allowlist enforcement at the
// dispatch boundary, spec budgets, instance bookkeeping, result-only return.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart'
    show RiskTier;
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_context/sub_agent_context.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_instance/sub_agent_instance.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_spec/sub_agent_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/sub_agent_dispatch.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

/// LLM client that records EVERY messages list it is handed (the isolation
/// witness) and returns a FIFO script of completions.
class CapturingLlmClient extends LlmClientProvider {
  CapturingLlmClient({required this.completions})
      : super(
          config: const ProviderConfig(
            id: 'kilo',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['tencent/hy3:free'],
            timeoutMs: 1,
          ),
          apiKey: 'test-key',
        );

  final List<ChatCompletion> completions;
  final List<List<ChatMessage>> seenMessages = [];
  int callCount = 0;
  void Function(int call)? afterCall;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    seenMessages.add(List.of(messages));
    callCount++;
    final completion = completions[callCount - 1];
    afterCall?.call(callCount);
    return completion;
  }
}

/// Records every dispatch; returns scripted results by tool name.
class RecordingDispatcher implements ToolDispatcher {
  RecordingDispatcher([this.resultsByTool = const {}]);

  final Map<String, ToolDispatchResult> resultsByTool;
  final List<({String toolName, bool isInternalMission})> calls = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    calls.add((toolName: toolName, isInternalMission: isInternalMission));
    return resultsByTool[toolName] ??
        ToolDispatchResult(
          success: true,
          result: 'ok:$toolName',
          error: '',
          artifactRefs: const [],
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
      const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

/// LLM client that throws on its first completion — drives a provider error.
class ThrowingLlmClient extends LlmClientProvider {
  ThrowingLlmClient({this.error = 'boom'})
      : super(
          config: const ProviderConfig(
            id: 'kilo',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['tencent/hy3:free'],
            timeoutMs: 1,
          ),
          apiKey: 'test-key',
        );

  final String error;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async =>
      throw Exception(error);
}

/// Plans tool calls by 1-based completion index.
class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.planByCall);

  final Map<int, List<ToolCall>> planByCall;
  int _count = 0;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    _count++;
    return planByCall[_count] ?? const [];
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

SubAgentSpec spec({
  RiskTier riskTier = RiskTier.safe,
  int? maxTurns,
  Duration? wallClockTimeout,
  List<String> tools = const ['search'],
}) =>
    SubAgentSpec(
      name: 'explore',
      description: 'explores the repo',
      systemPrompt: 'You are the explorer.',
      tools: tools,
      riskTier: riskTier,
      maxTurns: maxTurns,
      wallClockTimeout: wallClockTimeout,
    );

const instance = SubAgentInstance(
  id: 'inst-1',
  subAgentSpecId: 'explore',
  parentSessionId: 'parent-1',
  totalRuns: 2,
);

void main() {
  group('spec 070 — AllowlistToolDispatcher standalone', () {
    test('delegates allowlisted calls', () async {
      final inner = RecordingDispatcher();
      final allow = AllowlistToolDispatcher(inner: inner, allowlist: {'search'});

      final result = await allow.dispatch(
        toolName: 'search',
        arguments: const {'q': 'x'},
        isInternalMission: true,
      );

      expect(result.success, isTrue);
      expect(result.result, 'ok:search');
      expect(inner.calls, hasLength(1));
      expect(inner.calls.single.toolName, 'search');
      expect(inner.calls.single.isInternalMission, isTrue);
    });

    test('refuses non-allowlisted calls without touching the inner dispatcher',
        () async {
      final inner = RecordingDispatcher();
      final allow = AllowlistToolDispatcher(inner: inner, allowlist: {'search'});

      final result = await allow.dispatch(
        toolName: 'shell',
        arguments: const {},
        isInternalMission: false,
      );

      expect(result.success, isFalse);
      expect(result.error, 'tool not allowed: shell');
      expect(inner.calls, isEmpty);
    });

    test('batch enforces the allowlist per call', () async {
      final inner = RecordingDispatcher();
      final allow = AllowlistToolDispatcher(inner: inner, allowlist: {'search'});

      final results = await allow.dispatchBatch(
        calls: const [
          ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
          ToolCall(toolName: 'shell', arguments: {}, executionMode: 'sequential'),
        ],
        isInternalMission: false,
      );

      expect(results, hasLength(2));
      expect(results[0].success, isTrue);
      expect(results[1].success, isFalse);
      expect(results[1].error, 'tool not allowed: shell');
      expect(inner.calls, hasLength(1));
      expect(inner.calls.single.toolName, 'search');
    });
  });

  group('spec 070 — SubAgentDispatchService', () {
    var fakeNow = DateTime.utc(2026, 1, 1);
    DateTime fakeClock() => fakeNow;

    setUp(() {
      fakeNow = DateTime.utc(2026, 1, 1);
    });

    test('child runs in an isolated context and returns only a summary', () async {
      final llm = CapturingLlmClient(completions: [completionOf('found 3 files')]);
      final dispatcher = RecordingDispatcher();
      final service = SubAgentDispatchService(
        toolDispatcher: dispatcher,
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(),
        mission: 'find the tests',
        instance: instance,
      );

      // Isolation witness: the child saw EXACTLY system + mission.
      expect(llm.seenMessages, hasLength(1));
      expect(
        llm.seenMessages.single,
        const [
          ChatMessage(role: 'system', content: 'You are the explorer.'),
          ChatMessage(role: 'user', content: 'find the tests'),
        ],
      );

      // Result-only return: summary present, no transcript anywhere on the
      // result type (static shape — enforced by what compiles below).
      expect(result.status, SubAgentDispatchStatus.completed);
      expect(result.resultSummary, 'found 3 files');
      expect(result.instanceId, 'inst-1');
      expect(result.specName, 'explore');
    });

    test('tool allowlist is enforced at the dispatch boundary', () async {
      final llm = CapturingLlmClient(completions: [
        completionOf('need tools', finish: 'tool_calls'),
        completionOf('done'),
      ]);
      final dispatcher = RecordingDispatcher();
      final events = <EngineEvent>[];
      final service = SubAgentDispatchService(
        toolDispatcher: dispatcher,
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(tools: const ['search']),
        mission: 'go',
        instance: instance,
        planner: ScriptedPlanner({
          1: const [
            ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
            ToolCall(toolName: 'shell', arguments: {}, executionMode: 'sequential'),
          ],
        }),
        onEvent: events.add,
      );

      // Only the allowlisted call reached the inner dispatcher.
      expect(dispatcher.calls, hasLength(1));
      expect(dispatcher.calls.single.toolName, 'search');

      // The child saw the refusal as a failed tool call, and continued.
      final completed = events.whereType<ToolCallCompleted>().toList();
      expect(completed, hasLength(2));
      expect(completed[0].toolName, 'search');
      expect(completed[0].ok, isTrue);
      expect(completed[1].toolName, 'shell');
      expect(completed[1].ok, isFalse);

      expect(result.status, SubAgentDispatchStatus.completed);
      expect(result.resultSummary, 'done');
    });

    test('spec maxTurns budget caps the child mission', () async {
      final llm = CapturingLlmClient(
          completions: [completionOf('t1', finish: 'tool_calls')]);
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(maxTurns: 1),
        mission: 'go',
        instance: instance,
        planner: ScriptedPlanner({
          1: const [
            ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
          ],
        }),
      );

      expect(result.status, SubAgentDispatchStatus.budgetExhausted);
      expect(result.resultSummary, isNull);
      expect(llm.callCount, 1);
      expect(result.instance.totalRuns, 3);
      expect(result.instance.lastRunOutcome, 'budgetExhausted');
    });

    test('completed dispatch updates the instance bookkeeping', () async {
      final llm = CapturingLlmClient(completions: [completionOf('done')]);
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(),
        mission: 'go',
        instance: instance,
      );

      expect(result.instance.totalRuns, 3);
      expect(result.instance.lastRunOutcome, 'completed');
      expect(result.instance.id, 'inst-1');
      expect(result.instance.parentSessionId, 'parent-1');
      // Input instance untouched (immutable — the update is a new object).
      expect(instance.totalRuns, 2);
    });

    test('admin-risk spec is refused without a grant', () async {
      final llm = CapturingLlmClient(completions: [completionOf('should not run')]);
      final dispatcher = RecordingDispatcher();
      final service = SubAgentDispatchService(
        toolDispatcher: dispatcher,
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(riskTier: RiskTier.admin),
        mission: 'go',
        instance: instance,
      );

      expect(result.status, SubAgentDispatchStatus.refusedRiskTier);
      expect(result.resultSummary, isNull);
      expect(llm.callCount, 0);
      expect(dispatcher.calls, isEmpty);
      expect(result.instance.totalRuns, 2); // unchanged
      expect(result.instance.lastRunOutcome, isNull);
    });

    test('admin-risk spec runs with an explicit grant', () async {
      final llm = CapturingLlmClient(completions: [completionOf('admin done')]);
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(riskTier: RiskTier.admin),
        mission: 'go',
        instance: instance,
        adminGranted: true,
      );

      expect(result.status, SubAgentDispatchStatus.completed);
      expect(llm.callCount, 1);
      expect(result.instance.totalRuns, 3);
    });

    test('child events forward with the instance id as mission id', () async {
      final llm = CapturingLlmClient(completions: [completionOf('done')]);
      final events = <EngineEvent>[];
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      await service.dispatch(
        spec: spec(),
        mission: 'go',
        instance: instance,
        onEvent: events.add,
      );

      final started = events.whereType<MissionStarted>().single;
      expect(started.missionId, 'inst-1');
      final completed = events.whereType<MissionCompleted>().single;
      expect(completed.missionId, 'inst-1');
      expect(completed.status, 'completed');
    });

    test('spec wallClockTimeout caps the child mission', () async {
      final llm =
          CapturingLlmClient(completions: [completionOf('working', finish: 'tool_calls')]);
      llm.afterCall = (_) => fakeNow = fakeNow.add(const Duration(seconds: 10));
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(wallClockTimeout: const Duration(seconds: 5)),
        mission: 'go',
        instance: instance,
        planner: ScriptedPlanner({
          1: const [
            ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
          ],
        }),
        clock: fakeClock,
      );

      expect(result.status, SubAgentDispatchStatus.budgetExhausted);
      expect(result.instance.lastRunOutcome, 'budgetExhausted');
    });

    test('provider failure maps MissionStatus.providerFailed to providerFailed',
        () async {
      final llm = ThrowingLlmClient();
      final events = <EngineEvent>[];
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(),
        mission: 'go',
        instance: instance,
        onEvent: events.add,
      );

      expect(result.status, SubAgentDispatchStatus.providerFailed);
      expect(result.resultSummary, isNull);
      expect(events.whereType<ProviderError>(), isNotEmpty);
      expect(result.instance.totalRuns, 3);
      expect(result.instance.lastRunOutcome, 'providerFailed');
    });

    test('SubAgentDispatchResult value semantics and context snapshot', () async {
      final llm = CapturingLlmClient(completions: [completionOf('done')]);
      final service = SubAgentDispatchService(
        toolDispatcher: RecordingDispatcher(),
        llmClient: llm,
      );

      final result = await service.dispatch(
        spec: spec(maxTurns: 4),
        mission: 'go',
        instance: instance,
      );

      // Context snapshot documents the isolation envelope.
      expect(result.context.subAgentSpecId, 'explore');
      expect(result.context.sessionId, 'inst-1');
      expect(result.context.toolAllowlist, ['search']);
      expect(result.context.budgetTurns, 4);

      // Null maxTurns falls back to the service default.
      final result2 = await service.dispatch(
        spec: spec(),
        mission: 'go',
        instance: instance,
      );
      expect(result2.context.budgetTurns, 10);

      // Value semantics: identical fields => ==, equal hashCode.
      final a = SubAgentDispatchResult(
        instanceId: 'i',
        specName: 's',
        status: SubAgentDispatchStatus.completed,
        resultSummary: 'x',
        instance: instance,
        context: result.context,
      );
      final b = SubAgentDispatchResult(
        instanceId: 'i',
        specName: 's',
        status: SubAgentDispatchStatus.completed,
        resultSummary: 'x',
        instance: instance,
        context: result.context,
      );
      final c = SubAgentDispatchResult(
        instanceId: 'i',
        specName: 's',
        status: SubAgentDispatchStatus.refusedRiskTier,
        resultSummary: 'x',
        instance: instance,
        context: result.context,
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.toString(), contains('i'));
      expect(a.toString(), contains('completed'));
    });
  });
}
