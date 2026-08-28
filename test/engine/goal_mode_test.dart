// Tests for goal mode (spec 071): Goal + GoalEvaluator, the goalAchieved
// terminal status, and the MissionRunner early-stop overlay.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/goal_mode.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient({required this.completions, this.throwOnCall})
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
  final int? throwOnCall;
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    if (throwOnCall == callCount) {
      throw StateError('provider down (call $callCount)');
    }
    return completions[callCount - 1];
  }
}

class FakeToolDispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      ToolDispatchResult(
        success: true,
        result: 'ok:$toolName',
        error: '',
        artifactRefs: const [],
      );

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

/// Rule-based evaluator that counts invocations and remembers the last
/// transcript view it was handed.
class RuleEvaluator implements GoalEvaluator {
  RuleEvaluator(this.rule);

  final bool Function(List<ChatMessage> transcript) rule;
  int invocations = 0;
  List<ChatMessage>? lastTranscript;

  @override
  bool isAchieved(Goal goal, List<ChatMessage> transcript) {
    invocations++;
    lastTranscript = transcript;
    return rule(transcript);
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

const loop10 = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

const defaultPolicy = StopPolicy(
  id: 'test',
  maxTurns: 100,
  wallClockTimeout: Duration.zero,
  repetitionThreshold: 5,
);

const goal = Goal(id: 'g1', description: 'tests written and green');

void main() {
  final fakeNow = DateTime.utc(2026, 1, 1);

  MissionRunner makeRunner({
    required List<EngineEvent> events,
    StopPolicy policy = defaultPolicy,
  }) =>
      MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(completions: const []),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: policy,
        onEvent: events.add,
        clock: () => fakeNow,
      );

  group('spec 071 — goal mode', () {
    test('goal achieved on turn 1 stops the mission early', () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(completions: [completionOf('answer ready')]);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: defaultPolicy,
        onEvent: events.add,
        clock: () => fakeNow,
      );
      final evaluator =
          RuleEvaluator((t) => t.any((m) => m.role == 'assistant'));

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
      );

      expect(result.status, MissionStatus.goalAchieved);
      expect(result.turnsUsed, 1);
      expect(result.summary, 'answer ready');
      expect(result.goalAchieved, isTrue);
      expect(result.goal, goal);
      expect((events.last as MissionCompleted).status, 'goalAchieved');
    });

    test('goal evaluation sees tool results within the same turn', () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(
          completions: [completionOf('need tool', finish: 'tool_calls')]);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: defaultPolicy,
        onEvent: events.add,
        clock: () => fakeNow,
      );
      final evaluator = RuleEvaluator((t) => t.any((m) => m.role == 'tool'));

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
        planner: ScriptedPlanner({
          1: const [
            ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
          ],
        }),
      );

      // Post-tool evaluation: the tool-role message landed THIS turn, so the
      // goal fires on turn 1 — no second LLM turn is needed.
      expect(result.status, MissionStatus.goalAchieved);
      expect(result.turnsUsed, 1);
      expect(llm.callCount, 1);
      expect(result.transcript.map((m) => m.role), ['user', 'assistant', 'tool']);
    });

    test('goal met on the natural-stop turn reports goalAchieved', () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(completions: [completionOf('final answer')]);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: defaultPolicy,
        onEvent: events.add,
        clock: () => fakeNow,
      );
      final evaluator = RuleEvaluator((t) => t.length >= 2);

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
      );

      expect(result.status, MissionStatus.goalAchieved);
      expect(result.goalAchieved, isTrue);
      expect((events.last as MissionCompleted).status, 'goalAchieved');
    });

    test('unmet goal leaves the mission to its natural stop, evaluator consulted every turn',
        () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(completions: [
        completionOf('a', finish: 'tool_calls'),
        completionOf('b', finish: 'tool_calls'),
        completionOf('c'),
      ]);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: defaultPolicy,
        onEvent: events.add,
        clock: () => fakeNow,
      );
      final evaluator = RuleEvaluator((_) => false);

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
      );

      expect(result.status, MissionStatus.completed);
      expect(result.goalAchieved, isFalse);
      expect(result.turnsUsed, 3);
      expect(evaluator.invocations, 3);
    });

    test('budget exhaustion overrides goal mode', () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(completions: [
        completionOf('a', finish: 'tool_calls'),
        completionOf('b', finish: 'tool_calls'),
      ]);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: const StopPolicy(
          id: 'tight',
          maxTurns: 2,
          wallClockTimeout: Duration.zero,
          repetitionThreshold: 5,
        ),
        onEvent: events.add,
        clock: () => fakeNow,
      );
      final evaluator = RuleEvaluator((_) => false);

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
      );

      expect(result.status, MissionStatus.budgetExhausted);
      expect(result.goalAchieved, isFalse);
      expect(result.turnsUsed, 2);
      expect(evaluator.invocations, 2);
    });

    test('goal and goalEvaluator must be supplied together', () async {
      final runner = makeRunner(events: []);
      final evaluator = RuleEvaluator((_) => true);

      await expectLater(
        runner.run(
          missionId: 'm1',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          goal: goal,
        ),
        throwsArgumentError,
      );
      await expectLater(
        runner.run(
          missionId: 'm1',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          goalEvaluator: evaluator,
        ),
        throwsArgumentError,
      );
    });

    test('provider-failed turn is never goal-evaluated', () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(completions: const [], throwOnCall: 1);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: defaultPolicy,
        onEvent: events.add,
        clock: () => fakeNow,
      );
      final evaluator = RuleEvaluator((_) => true);

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
      );

      expect(result.status, MissionStatus.providerFailed);
      expect(result.goalAchieved, isFalse);
      expect(evaluator.invocations, 0);
    });

    test('evaluator receives an unmodifiable transcript view', () async {
      final llm = ScriptedLlmClient(completions: [completionOf('answer ready')]);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: defaultPolicy,
        onEvent: (_) {},
        clock: () => fakeNow,
      );
      final evaluator = RuleEvaluator((t) => t.any((m) => m.role == 'assistant'));

      await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        goal: goal,
        goalEvaluator: evaluator,
      );

      expect(evaluator.lastTranscript, isNotNull);
      expect(
        () => evaluator.lastTranscript!
            .add(const ChatMessage(role: 'user', content: 'nope')),
        throwsUnsupportedError,
      );
    });

    test('Goal value semantics', () {
      const a = Goal(id: 'g1', description: 'tests written and green');
      const b = Goal(id: 'g1', description: 'tests written and green');
      const c = Goal(id: 'g2', description: 'tests written and green');

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.toString(), contains('g1'));
      expect(a.toString(), contains('tests written and green'));
    });
  });
}
