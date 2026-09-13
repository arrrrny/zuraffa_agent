// Hand-stepped acceptance subject (spec 112, AC-6): a mission run emits
// INFO lifecycle records (start + terminal status) on the engine logger.
// Returns the mission lifecycle messages.
// ignore_for_file: non_constant_identifier_names
library;

import 'package:logging/logging.dart';

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/src/logging/memory_log_sink.dart';

class _A6Client extends LlmClientProvider {
  _A6Client()
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
  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async =>
      const ChatCompletion(
        content: 'done',
        finishReason: 'stop',
        usage: TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
      );
}

class _A6Dispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async => throw UnimplementedError('no tools in A6');
  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => const <ToolDispatchResult>[];
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

Future<List<String>> subject_a6() async {
  ZuraffaLogging.reset();
  final sink = MemoryLogSink();
  ZuraffaLogging.install(level: Level.INFO, onRecord: sink.add);
  final runner = MissionRunner(
    executor: EngineLoopExecutor(
      const EngineLoop(
        id: 'loop-a6',
        sessionId: 's-a6',
        maxTurns: 10,
        wallClockTimeoutMs: 60000,
        repetitionThreshold: 5,
      ),
      _A6Client(),
    ),
    toolDispatcher: _A6Dispatcher(),
    stopPolicy: const StopPolicy(
      id: 'test',
      maxTurns: 10,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 5,
    ),
    onEvent: (_) {},
    clock: () => DateTime.fromMillisecondsSinceEpoch(0),
  );
  await runner.run(
    missionId: 'm-a6',
    messages: const [ChatMessage(role: 'user', content: 'go')],
  );
  ZuraffaLogging.reset();
  final missionRecords = sink.records
      .where((r) => r.loggerName == 'zuraffa.agent.engine')
      .toList();
  return missionRecords.map((r) => r.message).toList();
}
