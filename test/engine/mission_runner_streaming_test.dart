// Tests for MissionRunner.runStream (issue #123): the streaming mission loop.
//
// The streaming contract under test:
//   * turn chunks propagate to the event sink INCREMENTALLY as
//     ThinkingDelta / ContentDelta (the sink must see a delta while the
//     provider stream is still open — enforced by a gate the fake stream
//     waits on),
//   * the multi-turn loop still works end-to-end on top of assembled chunks
//     (planner, tool dispatch, transcript, summary),
//   * streaming provider failures map to the existing provider-failed
//     contract (ProviderError + MissionCompleted, never a bare throw).
//
// Fakes: StreamingScriptedLlmClient (no network), FakeToolDispatcher,
// ScriptedPlanner, and an injected fixed clock.

import 'dart:async';

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/config/zuraffa_config.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

/// LLM client whose streaming turns are scripted: turn N's chunk stream is
/// produced by [turnStreams][N-1]().
class StreamingScriptedLlmClient extends LlmClientProvider {
  StreamingScriptedLlmClient({required this.turnStreams})
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

  final List<Stream<LlmResponseChunk> Function()> turnStreams;
  int callCount = 0;

  @override
  Stream<LlmResponseChunk> streamComplete(List<ChatMessage> messages) =>
      turnStreams[callCount++]();
}

/// Records every dispatch; returns scripted results by tool name.
class FakeToolDispatcher implements ToolDispatcher {
  FakeToolDispatcher([this.resultsByTool = const {}]);

  final Map<String, ToolDispatchResult> resultsByTool;
  final List<String> toolNames = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    toolNames.add(toolName);
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
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

/// Plans tool calls by 1-based turn index.
class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.planByTurn);

  final Map<int, List<ToolCall>> planByTurn;
  int _turn = 0;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async => planByTurn[++_turn] ?? const [];
}

const loop = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

const stopPolicy = StopPolicy(
  id: 'test',
  maxTurns: 100,
  wallClockTimeout: Duration.zero,
  repetitionThreshold: 5,
);

LlmResponseChunk contentChunk(String text) => LlmResponseChunk(content: text);

LlmResponseChunk finalChunk({
  String finishReason = 'stop',
  LlmUsage usage = const LlmUsage(inputTokens: 3, outputTokens: 2),
}) => LlmResponseChunk(
  usage: usage,
  isComplete: true,
  finishReason: finishReason,
);

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  MissionRunner makeRunner(
    StreamingScriptedLlmClient llm, {
    required void Function(EngineEvent) onEvent,
    FakeToolDispatcher? dispatcher,
  }) => MissionRunner(
    executor: EngineLoopExecutor(loop, llm),
    toolDispatcher: dispatcher ?? FakeToolDispatcher(),
    stopPolicy: stopPolicy,
    onEvent: onEvent,
    clock: fakeClock,
  );

  group('MissionRunner.runStream (issue #123)', () {
    test(
      'multi-turn mission streams chunks incrementally to the event sink',
      () async {
        final events = <EngineEvent>[];
        // The gate: turn 1's stream holds AFTER the thinking delta until the
        // event sink has observed it. If runStream buffered the whole turn
        // before emitting, the gate would never open and the mission would
        // hang — the test fails on timeout instead of passing silently.
        final thinkingSeenBySink = Completer<void>();
        final turn1 = StreamController<LlmResponseChunk>();

        final llm = StreamingScriptedLlmClient(
          turnStreams: [
            () {
              unawaited(() async {
                turn1.add(const LlmResponseChunk(thinking: 'pondering'));
                await thinkingSeenBySink.future.timeout(
                  const Duration(seconds: 10),
                  onTimeout: () => throw StateError(
                    'runStream never delivered the thinking delta '
                    'incrementally — chunks were buffered until turn end',
                  ),
                );
                turn1.add(contentChunk('hello'));
                await turn1.close();
              }());
              return turn1.stream;
            },
            // Turn 2 completes naturally.
            () => Stream.fromIterable([
              contentChunk('all '),
              contentChunk('done'),
              finalChunk(),
            ]),
          ],
        );

        final planner = ScriptedPlanner({
          1: [
            const ToolCall(
              toolName: 'search',
              arguments: {'q': 'zuraffa'},
              executionMode: 'sequential',
            ),
          ],
        });

        final runner = makeRunner(
          llm,
          onEvent: (event) {
            events.add(event);
            if (event is ThinkingDelta && !thinkingSeenBySink.isCompleted) {
              thinkingSeenBySink.complete();
            }
          },
        );

        final result = await runner.runStream(
          missionId: 'm1',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          planner: planner,
        );

        // Deltas arrive as events, in producer order, inside their turn.
        expect(events.map((e) => e.runtimeType), [
          MissionStarted,
          TurnStarted,
          ThinkingDelta,
          ContentDelta,
          ToolCallStarted,
          ToolCallCompleted,
          TurnCompleted,
          TurnStarted,
          ContentDelta,
          ContentDelta,
          TurnCompleted,
          MissionCompleted,
        ]);
        expect((events[2] as ThinkingDelta).delta, 'pondering');
        expect((events[3] as ContentDelta).delta, 'hello');
        expect(events.whereType<ContentDelta>().map((e) => e.delta).toList(), [
          'hello',
          'all ',
          'done',
        ]);

        // The loop above the streaming turn is unchanged: the assembled
        // completion drives planner + dispatch + natural stop.
        expect(result.status, MissionStatus.completed);
        expect(result.turnsUsed, 2);
        expect(result.summary, 'all done');
        expect(result.transcript.map((m) => m.role), [
          'user',
          'assistant',
          'tool',
          'assistant',
        ]);
        expect(result.transcript[1].content, 'hello');
        expect(result.transcript[1].thinking, 'pondering');
        expect(result.transcript[2].content, 'ok:search');
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('sentinel chunks (usage / isComplete) emit no delta events', () async {
      final events = <EngineEvent>[];
      final llm = StreamingScriptedLlmClient(
        turnStreams: [
          () => Stream.fromIterable([contentChunk('done'), finalChunk()]),
        ],
      );

      final runner = makeRunner(llm, onEvent: events.add);
      final result = await runner.runStream(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(events.whereType<ThinkingDelta>(), isEmpty);
      expect(events.whereType<ContentDelta>().map((e) => e.delta), ['done']);
      expect(result.summary, 'done');
      expect(result.status, MissionStatus.completed);
    });

    test(
      'streaming provider failure maps to the provider-failed contract',
      () async {
        final events = <EngineEvent>[];
        final llm = StreamingScriptedLlmClient(
          turnStreams: [
            () async* {
              yield contentChunk('par');
              throw StateError('gateway exploded mid-stream');
            },
          ],
        );

        final runner = makeRunner(llm, onEvent: events.add);
        final result = await runner.runStream(
          missionId: 'm1',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        );

        // Deltas that arrived before the failure still reached the sink;
        // the error maps to the same provider-failed contract as run().
        expect(events.map((e) => e.runtimeType), [
          MissionStarted,
          TurnStarted,
          ContentDelta,
          ProviderError,
          MissionCompleted,
        ]);
        expect(
          (events[3] as ProviderError).error,
          contains('gateway exploded mid-stream'),
        );
        expect(result.status, MissionStatus.providerFailed);
        expect(result.summary, isNull);
        expect((events.last as MissionCompleted).status, 'providerFailed');
      },
    );

    test('runStream enforces the same startup validation as run', () async {
      final events = <EngineEvent>[];
      final llm = StreamingScriptedLlmClient(turnStreams: []);
      final runner = MissionRunner(
        executor: EngineLoopExecutor(loop, llm),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: stopPolicy,
        onEvent: events.add,
        clock: fakeClock,
        // Invalid: an engine loop section with a non-positive maxTurns.
        config: const ZuraffaConfig(
          engineLoop: EngineLoop(
            id: 'loop-bad',
            sessionId: 's1',
            maxTurns: 0,
            wallClockTimeoutMs: 0,
            repetitionThreshold: 5,
          ),
        ),
      );

      await expectLater(
        runner.runStream(
          missionId: 'm1',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        ),
        throwsA(isA<StateError>()),
      );
      // Nothing ran: no mission lifecycle events, no LLM calls.
      expect(events, isEmpty);
      expect(llm.callCount, 0);
    });
  });
}
