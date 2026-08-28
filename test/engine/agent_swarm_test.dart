// Tests for the agent swarm (spec 072): concurrent fan-out over the
// sub-agent dispatch service with allCompleted / firstCompleted / quorum
// aggregation strategies.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_instance/sub_agent_instance.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_spec/sub_agent_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_context/sub_agent_context.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/agent_swarm.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/sub_agent_dispatch.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

/// Per-member script: how long the dispatch "runs" and how it ends.
typedef MemberScript = ({Duration delay, SubAgentDispatchStatus status, String? summary});

/// Dispatch-service fake: scripts latency + outcome by instance id (the
/// swarm synthesizes instance.id == task.id) and probes concurrency.
class ScriptedDispatchService extends SubAgentDispatchService {
  ScriptedDispatchService(this.behavior)
      : super(toolDispatcher: _InertDispatcher(), llmClient: _InertLlmClient());

  final Map<String, MemberScript> behavior;
  int active = 0;
  int maxActive = 0;
  final List<SubAgentInstance> seenInstances = [];
  final List<bool> seenAdminGranted = [];

  @override
  Future<SubAgentDispatchResult> dispatch({
    required SubAgentSpec spec,
    required String mission,
    required SubAgentInstance instance,
    ToolCallPlanner? planner,
    void Function(EngineEvent)? onEvent,
    DateTime Function()? clock,
    bool adminGranted = false,
  }) async {
    seenInstances.add(instance);
    seenAdminGranted.add(adminGranted);
    active++;
    if (active > maxActive) maxActive = active;
    final script = behavior[instance.id]!;
    if (script.delay > Duration.zero) {
      await Future<void>.delayed(script.delay);
    }
    active--;
    return SubAgentDispatchResult(
      instanceId: instance.id,
      specName: spec.name,
      status: script.status,
      resultSummary: script.summary,
      instance: instance,
      context: SubAgentContext(
        id: 'ctx-${instance.id}',
        subAgentSpecId: spec.name,
        sessionId: instance.id,
        toolAllowlist: spec.tools,
        budgetTurns: 1,
      ),
    );
  }
}

class _InertDispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      throw StateError('inert inner dispatcher — never reached');

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async =>
      throw StateError('inert inner dispatcher — never reached');

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) =>
      const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

class _InertLlmClient extends LlmClientProvider {
  _InertLlmClient()
      : super(
          config: const ProviderConfig(
            id: 'kilo',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['m'],
            timeoutMs: 1,
          ),
          apiKey: 'test-key',
        );

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async =>
      throw StateError('inert llm client — never reached');
}

/// Real LLM client for the end-to-end integration test.
class SingleAnswerLlmClient extends LlmClientProvider {
  SingleAnswerLlmClient()
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

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async =>
      ChatCompletion(
        content: 'swarm answer',
        finishReason: 'stop',
        usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
      );
}

class PassThroughDispatcher implements ToolDispatcher {
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

SubAgentSpec memberSpec(String name) => SubAgentSpec(
      name: name,
      description: 'swarm member $name',
      systemPrompt: 'You are $name.',
    );

SwarmTask taskOf(String id, {Duration delay = Duration.zero}) => SwarmTask(
      id: id,
      spec: memberSpec(id),
      mission: 'do $id',
    );

const ok = SubAgentDispatchStatus.completed;
const failed = SubAgentDispatchStatus.providerFailed;

void main() {
  group('spec 072 — AgentSwarm', () {
    test('members dispatch concurrently (overlap provable)', () async {
      final service = ScriptedDispatchService({
        for (final id in ['a', 'b', 'c'])
          id: (delay: const Duration(milliseconds: 20), status: ok, summary: 's-$id'),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(tasks: [taskOf('a'), taskOf('b'), taskOf('c')]);

      expect(service.maxActive, 3);
      expect(result.status, SwarmStatus.completed);
      expect(result.completedCount, 3);

      // Member instance synthesis (FR-002): id == task id, parent 'swarm',
      // fresh counters, spec id carried.
      for (final instance in service.seenInstances) {
        expect(instance.parentSessionId, 'swarm');
        expect(instance.totalRuns, 0);
        expect(instance.subAgentSpecId, instance.id);
      }
    });

    test('allCompleted returns a barrier over task-ordered results', () async {
      final service = ScriptedDispatchService({
        'a': (delay: const Duration(milliseconds: 30), status: ok, summary: 'slow-a'),
        'b': (delay: const Duration(milliseconds: 5), status: ok, summary: 'fast-b'),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(tasks: [taskOf('a'), taskOf('b')]);

      expect(result.status, SwarmStatus.completed);
      expect(result.strategy, SwarmStrategy.allCompleted);
      expect(result.completedCount, 2);
      expect(result.winner, isNull);
      // TASK order (a, b), not completion order (b, a).
      expect(result.results.map((r) => r.taskId), ['a', 'b']);
      expect(result.results.map((r) => r.summary), ['slow-a', 'fast-b']);
    });

    test('allCompleted reports partialFailure when a member fails', () async {
      final service = ScriptedDispatchService({
        'a': (delay: const Duration(milliseconds: 5), status: ok, summary: 'fine'),
        'b': (delay: const Duration(milliseconds: 5), status: failed, summary: null),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(tasks: [taskOf('a'), taskOf('b')]);

      expect(result.status, SwarmStatus.partialFailure);
      expect(result.completedCount, 1);
      expect(result.results.map((r) => r.status), [ok, failed]);
    });

    test('firstCompleted wins on completion order, not submission order', () async {
      final service = ScriptedDispatchService({
        'a': (delay: const Duration(milliseconds: 30), status: ok, summary: 'slow-a'),
        'b': (delay: const Duration(milliseconds: 5), status: ok, summary: 'fast-b'),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(
        tasks: [taskOf('a'), taskOf('b')],
        strategy: SwarmStrategy.firstCompleted,
      );

      expect(result.status, SwarmStatus.firstCompleted);
      expect(result.winner, isNotNull);
      expect(result.winner!.taskId, 'b');
      expect(result.winner!.summary, 'fast-b');
      expect(result.results, hasLength(1));
      expect(result.results.single.taskId, 'b');
      expect(result.completedCount, 1);
    });

    test('firstCompleted without any success degrades to partialFailure', () async {
      final service = ScriptedDispatchService({
        'a': (delay: const Duration(milliseconds: 5), status: failed, summary: null),
        'b': (delay: const Duration(milliseconds: 5), status: failed, summary: null),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(
        tasks: [taskOf('a'), taskOf('b')],
        strategy: SwarmStrategy.firstCompleted,
      );

      expect(result.status, SwarmStatus.partialFailure);
      expect(result.winner, isNull);
      expect(result.results, hasLength(2));
      expect(result.completedCount, 0);
    });

    test('quorum reached on the k-th success', () async {
      final service = ScriptedDispatchService({
        'fast': (delay: const Duration(milliseconds: 5), status: ok, summary: 's-fast'),
        'mid': (delay: const Duration(milliseconds: 10), status: ok, summary: 's-mid'),
        'slow': (delay: const Duration(milliseconds: 25), status: failed, summary: null),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(
        tasks: [taskOf('fast'), taskOf('mid'), taskOf('slow')],
        strategy: SwarmStrategy.quorum,
        quorum: 2,
      );

      expect(result.status, SwarmStatus.quorumReached);
      expect(result.completedCount, 2);
      expect(result.results, hasLength(2));
      expect(result.results.every((r) => r.status == ok), isTrue);
      // Completion order: fast before mid.
      expect(result.results.map((r) => r.taskId), ['fast', 'mid']);
    });

    test('quorum unmet fails with the true success count', () async {
      final service = ScriptedDispatchService({
        'a': (delay: const Duration(milliseconds: 5), status: failed, summary: null),
        'b': (delay: const Duration(milliseconds: 10), status: failed, summary: null),
        'c': (delay: const Duration(milliseconds: 15), status: failed, summary: null),
      });
      final swarm = AgentSwarm(dispatchService: service);

      final result = await swarm.run(
        tasks: [taskOf('a'), taskOf('b'), taskOf('c')],
        strategy: SwarmStrategy.quorum,
        quorum: 2,
      );

      expect(result.status, SwarmStatus.quorumFailed);
      expect(result.completedCount, 0);
      expect(result.results, hasLength(3));
    });

    test('validation rejects empty, duplicate-id, and bad-quorum runs', () async {
      final service = ScriptedDispatchService({
        'a': (delay: Duration.zero, status: ok, summary: 's'),
        'b': (delay: Duration.zero, status: ok, summary: 's'),
      });
      final swarm = AgentSwarm(dispatchService: service);

      await expectLater(
        swarm.run(tasks: []),
        throwsArgumentError,
      );
      await expectLater(
        swarm.run(tasks: [taskOf('a'), taskOf('a')]),
        throwsArgumentError,
      );
      await expectLater(
        swarm.run(tasks: [taskOf('a')], strategy: SwarmStrategy.quorum),
        throwsArgumentError,
      );
      await expectLater(
        swarm.run(tasks: [taskOf('a')], strategy: SwarmStrategy.quorum, quorum: 0),
        throwsArgumentError,
      );
      await expectLater(
        swarm.run(
          tasks: [taskOf('a'), taskOf('b')],
          strategy: SwarmStrategy.quorum,
          quorum: 3,
        ),
        throwsArgumentError,
      );
    });

    test('single-task swarm runs a real child mission end-to-end', () async {
      final service = SubAgentDispatchService(
        toolDispatcher: PassThroughDispatcher(),
        llmClient: SingleAnswerLlmClient(),
      );
      final swarm = AgentSwarm(dispatchService: service);
      final events = <EngineEvent>[];

      final result = await swarm.run(
        tasks: [SwarmTask(id: 't1', spec: memberSpec('explore'), mission: 'find it')],
        onEvent: events.add,
      );

      expect(result.status, SwarmStatus.completed);
      expect(result.completedCount, 1);
      expect(result.results.single.summary, 'swarm answer');
      expect(result.results.single.specName, 'explore');

      // Attribution: the member's events carry the task id as mission id.
      final started = events.whereType<MissionStarted>().single;
      expect(started.missionId, 't1');
    });

    test('value objects carry house semantics', () {
      final specA = memberSpec('a');
      final t1 = SwarmTask(id: 'x', spec: specA, mission: 'go');
      final t2 = SwarmTask(id: 'x', spec: specA, mission: 'go');
      final t3 = SwarmTask(id: 'y', spec: specA, mission: 'go');
      expect(t1 == t2, isTrue);
      expect(t1.hashCode, t2.hashCode);
      expect(t1 == t3, isFalse);
      expect(t1.toString(), contains('x'));

      final r1 = const SwarmTaskResult(taskId: 'x', specName: 'a', status: ok, summary: 's');
      final r2 = const SwarmTaskResult(taskId: 'x', specName: 'a', status: ok, summary: 's');
      final r3 = const SwarmTaskResult(taskId: 'x', specName: 'a', status: failed, summary: 's');
      expect(r1 == r2, isTrue);
      expect(r1.hashCode, r2.hashCode);
      expect(r1 == r3, isFalse);
      expect(r1.toString(), contains('x'));

      final s1 = SwarmResult(
        strategy: SwarmStrategy.allCompleted,
        status: SwarmStatus.completed,
        results: [r1],
        winner: null,
        completedCount: 1,
      );
      final s2 = SwarmResult(
        strategy: SwarmStrategy.allCompleted,
        status: SwarmStatus.completed,
        results: [r2],
        winner: null,
        completedCount: 1,
      );
      final s3 = SwarmResult(
        strategy: SwarmStrategy.allCompleted,
        status: SwarmStatus.partialFailure,
        results: [r1],
        winner: null,
        completedCount: 1,
      );
      expect(s1 == s2, isTrue);
      expect(s1.hashCode, s2.hashCode);
      expect(s1 == s3, isFalse);
      expect(s1.toString(), contains('allCompleted'));
      expect(s1.toString(), contains('completed'));
    });
  });
}
