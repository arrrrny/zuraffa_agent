// Issue #138 — token-counting pre-flight in MissionRunner.
//
// Before every turn the runner must estimate the transcript against the
// model's context window and trigger the ContextCompressor proactively once
// the estimate reaches `model.contextWindow * 0.8` — instead of learning
// about context overflow from a provider 400 after the fact.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/model/model.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/llm/context_compressor.dart';
import 'package:zuraffa_agent/src/llm/token_estimator.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/types.dart';

/// LLM client that records every transcript it is handed and replays a FIFO
/// script of completions (no network).
class RecordingLlmClient extends LlmClientProvider {
  RecordingLlmClient({required this.completions})
    : super(
        config: const ProviderConfig(
          id: 'kilo',
          providerKind: 'openai',
          baseUrl: 'https://example.invalid/v1',
          models: ['test-model'],
          timeoutMs: 1,
        ),
        apiKey: 'test-key',
      );

  final List<ChatCompletion> completions;
  final List<List<ChatMessage>> requests = [];
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    requests.add(List<ChatMessage>.unmodifiable(messages));
    return completions[callCount - 1];
  }
}

/// Records every dispatch; returns a canned success result.
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
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

/// Plans exactly one tool call on the first consultation, then stops.
class OncePlanner implements ToolCallPlanner {
  bool planned = false;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    if (planned) return const [];
    planned = true;
    return const [ToolCall(toolName: 'search', arguments: {'q': 'x'})];
  }
}

/// Counts compress() invocations and records what it saw; replays one
/// scripted [CompressionResult] on every call.
class RecordingCompressor implements ContextCompressor {
  RecordingCompressor(this.result);

  final CompressionResult result;
  int calls = 0;
  final List<List<AgentMessage>> seen = [];

  @override
  Future<CompressionResult> compress(List<AgentMessage> messages) async {
    calls++;
    seen.add(List<AgentMessage>.unmodifiable(messages));
    return result;
  }
}

/// FIFO-scripted estimator that counts estimateMessages() calls.
class FakeTokenEstimator implements TokenEstimator {
  FakeTokenEstimator(List<int> perCall) : _perCall = perCall;

  final List<int> _perCall;
  int calls = 0;

  int _next() {
    final index = calls;
    calls++;
    return index < _perCall.length ? _perCall[index] : _perCall.last;
  }

  @override
  int estimateText(String text) => 0;

  @override
  int estimateImage(ImageBlock image) => 0;

  @override
  int estimateMessages(List<AgentMessage> messages) => _next();
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
    );

const loop10 = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

final model1k = Model(provider: 'openai', modelId: 'test-model', contextWindow: 1000);

CompressionResult snapshotResult({List<AgentMessage>? preserved}) =>
    CompressionResult(
      snapshot: '<state_snapshot><overall_goal>go</overall_goal>'
          '</state_snapshot>',
      preservedMessages: preserved ?? [UserMessage.text('recent')],
      compressedMessages: const [],
      strategy: CompressionStrategy.llm,
    );

void main() {
  final events = <EngineEvent>[];

  MissionRunner makeRunner({
    required RecordingLlmClient llm,
    TokenEstimator? estimator,
    ContextCompressor? compressor,
  }) => MissionRunner(
    executor: EngineLoopExecutor(loop10, llm),
    toolDispatcher: FakeToolDispatcher(),
    stopPolicy: const StopPolicy(
      id: 'test',
      maxTurns: 100,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 5,
    ),
    onEvent: events.add,
    model: model1k,
    tokenEstimator: estimator ?? const HeuristicTokenEstimator(),
    contextCompressor: compressor,
  );

  setUp(() => events.clear());

  test(
    'approaching 80% of the context window triggers compaction before the LLM call',
    () async {
      final llm = RecordingLlmClient(completions: [completionOf('done')]);
      final estimator = FakeTokenEstimator([900]);
      final compressor = RecordingCompressor(snapshotResult());
      final runner = makeRunner(
        llm: llm,
        estimator: estimator,
        compressor: compressor,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: [const ChatMessage(role: 'user', content: 'go')],
      );

      // The compressor ran exactly once, before the only LLM call, on the
      // transcript converted into AgentMessages.
      expect(compressor.calls, 1);
      expect(compressor.seen, hasLength(1));
      expect(compressor.seen.single.whereType<UserMessage>().length, 1);
      // The model received the compacted transcript: snapshot first, then
      // the preserved tail.
      expect(llm.requests, hasLength(1));
      expect(llm.requests.single.first.role, 'user');
      expect(
        llm.requests.single.first.content,
        startsWith('<state_snapshot>'),
      );
      expect(llm.requests.single[1].content, 'recent');
      expect(result.status, MissionStatus.completed);
      expect(result.transcript.first.content, startsWith('<state_snapshot>'));
    },
  );

  test('below the threshold the compressor is never consulted', () async {
    final llm = RecordingLlmClient(completions: [completionOf('done')]);
    final estimator = FakeTokenEstimator([100]);
    final compressor = RecordingCompressor(snapshotResult());
    final runner = makeRunner(
      llm: llm,
      estimator: estimator,
      compressor: compressor,
    );

    await runner.run(
      missionId: 'm1',
      messages: [const ChatMessage(role: 'user', content: 'go')],
    );

    expect(estimator.calls, 1); // queried, but...
    expect(compressor.calls, 0); // ...far below 800 tokens: no compaction.
    expect(llm.requests.single.first.content, 'go');
  });

  test('exactly 80% of the window triggers compaction (>= boundary)', () async {
    final llm = RecordingLlmClient(completions: [completionOf('done')]);
    final estimator = FakeTokenEstimator([800]);
    final compressor = RecordingCompressor(snapshotResult());
    final runner = makeRunner(
      llm: llm,
      estimator: estimator,
      compressor: compressor,
    );

    await runner.run(
      missionId: 'm1',
      messages: [const ChatMessage(role: 'user', content: 'go')],
    );

    expect(compressor.calls, 1);
  });

  test('pre-flight queries the estimator and compresses before every turn',
      () async {
    final llm = RecordingLlmClient(completions: [
      completionOf('using tools', finish: 'tool_calls'),
      completionOf('done'),
    ]);
    final estimator = FakeTokenEstimator([900, 900]);
    final compressor = RecordingCompressor(snapshotResult());
    final runner = makeRunner(
      llm: llm,
      estimator: estimator,
      compressor: compressor,
    );

    final result = await runner.run(
      missionId: 'm1',
      messages: [const ChatMessage(role: 'user', content: 'go')],
      planner: OncePlanner(),
    );

    expect(result.status, MissionStatus.completed);
    expect(result.turnsUsed, 2);
    expect(llm.callCount, 2);
    expect(estimator.calls, 2);
    expect(compressor.calls, 2);
    // Turn 2 was also served a compacted transcript.
    expect(llm.requests[1].first.content, startsWith('<state_snapshot>'));
  });

  test('without a compressor the pre-flight stays inert', () async {
    final llm = RecordingLlmClient(completions: [completionOf('done')]);
    final estimator = FakeTokenEstimator([900]);
    final runner = makeRunner(llm: llm, estimator: estimator);

    final result = await runner.run(
      missionId: 'm1',
      messages: [const ChatMessage(role: 'user', content: 'go')],
    );

    expect(result.status, MissionStatus.completed);
    expect(estimator.calls, 0);
    expect(llm.requests.single.first.content, 'go');
  });

  test(
    'a compressor that declines (empty snapshot) leaves the transcript intact',
    () async {
      final llm = RecordingLlmClient(completions: [completionOf('done')]);
      final estimator = FakeTokenEstimator([900]);
      final compressor = RecordingCompressor(
        const CompressionResult(
          snapshot: '',
          preservedMessages: [],
          compressedMessages: [],
          strategy: CompressionStrategy.none,
        ),
      );
      final runner = makeRunner(
        llm: llm,
        estimator: estimator,
        compressor: compressor,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: [const ChatMessage(role: 'user', content: 'go')],
      );

      expect(compressor.calls, 1);
      expect(llm.requests.single.map((m) => m.content), ['go']);
      expect(result.status, MissionStatus.completed);
    },
  );
}
