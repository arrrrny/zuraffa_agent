// spec 109 (issue #118) — the sanitizer wired into MissionRunner at the
// LLM egress boundary (the transcript join). Fakes mirror the spec 069
// exemplar.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
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
import 'package:zuraffa_agent/src/security/tool_result_sanitizer.dart';

class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient({required this.completions})
    : super(
        config: const ProviderConfig(
          id: 'test-provider',
          providerKind: 'openai',
          baseUrl: 'https://example.invalid/v1',
          models: ['test/model'],
          timeoutMs: 1,
        ),
        apiKey: 'test-key',
      );

  final List<ChatCompletion> completions;
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    return completions[callCount - 1];
  }
}

/// Returns a fixed tool result — optionally containing secret material.
class FixedToolDispatcher implements ToolDispatcher {
  FixedToolDispatcher(this.result);

  final ToolDispatchResult result;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async => result;

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => const [];

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

/// Plans one tool call on the first completion; empty afterwards (spec 069
/// exemplar pattern).
class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.calls);

  final List<ToolCall> calls;
  bool planned = false;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    if (planned) return const [];
    planned = true;
    return calls;
  }
}

ChatCompletion completionOf(String content, {String finish = 'tool_calls'}) =>
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

const _awsSecret =
    'AKIA'
    'IOSFODNN7EXAMPLE';

DateTime fakeClock() => DateTime.utc(2026, 1, 1);

void main() {
  MissionRunner makeRunner({
    required void Function(EngineEvent) onEvent,
    required ToolDispatcher dispatcher,
    required List<ChatCompletion> completions,
    ToolResultSanitizer? sanitizer,
  }) {
    return MissionRunner(
      executor: EngineLoopExecutor(
        loop10,
        ScriptedLlmClient(completions: completions),
      ),
      toolDispatcher: dispatcher,
      stopPolicy: const StopPolicy(
        id: 'test',
        maxTurns: 100,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      ),
      onEvent: onEvent,
      clock: fakeClock,
      toolResultSanitizer: sanitizer,
    );
  }

  test(
    'U9: a secret-bearing tool result joins the transcript redacted',
    () async {
      final events = <EngineEvent>[];
      final dispatcher = FixedToolDispatcher(
        ToolDispatchResult(
          success: true,
          result: 'creds: $_awsSecret',
          error: '',
          artifactRefs: const [],
        ),
      );
      final runner = makeRunner(
        onEvent: events.add,
        dispatcher: dispatcher,
        // Turn 1 plans one tool call; turn 2 finishes naturally.
        completions: [
          completionOf('reading creds', finish: 'tool_calls'),
          completionOf('done'),
        ],
        sanitizer: RegexToolResultSanitizer(),
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'read the creds')],
        planner: ScriptedPlanner(const [
          ToolCall(
            toolName: 'read_file',
            arguments: {'path': 'creds.txt'},
            executionMode: 'sequential',
          ),
        ]),
      );

      final toolMessage = result.transcript.singleWhere(
        (m) => m.role == 'tool',
      );
      expect(toolMessage.content, contains('[REDACTED:aws-access-key-id]'));
      expect(toolMessage.content, isNot(contains(_awsSecret)));
    },
  );

  test('U9b: error text is sanitized too', () async {
    final events = <EngineEvent>[];
    final dispatcher = FixedToolDispatcher(
      ToolDispatchResult(
        success: false,
        result: '',
        error: 'failed reading $_awsSecret',
        artifactRefs: const [],
      ),
    );
    final runner = makeRunner(
      onEvent: events.add,
      dispatcher: dispatcher,
      completions: [
        completionOf('reading creds', finish: 'tool_calls'),
        completionOf('done'),
      ],
      sanitizer: RegexToolResultSanitizer(),
    );

    final result = await runner.run(
      missionId: 'm2',
      messages: const [ChatMessage(role: 'user', content: 'read it')],
      planner: ScriptedPlanner(const [
        ToolCall(
          toolName: 'read_file',
          arguments: {'path': 'creds.txt'},
          executionMode: 'sequential',
        ),
      ]),
    );

    final toolMessage = result.transcript.singleWhere((m) => m.role == 'tool');
    expect(toolMessage.content, contains('[REDACTED:aws-access-key-id]'));
  });

  test('U10: without a sanitizer the transcript is verbatim', () async {
    final events = <EngineEvent>[];
    final dispatcher = FixedToolDispatcher(
      ToolDispatchResult(
        success: true,
        result: 'creds: $_awsSecret',
        error: '',
        artifactRefs: const [],
      ),
    );
    final runner = makeRunner(
      onEvent: events.add,
      dispatcher: dispatcher,
      completions: [
        completionOf('reading creds', finish: 'tool_calls'),
        completionOf('done'),
      ],
    );

    final result = await runner.run(
      missionId: 'm3',
      messages: const [ChatMessage(role: 'user', content: 'read the creds')],
      planner: ScriptedPlanner(const [
        ToolCall(
          toolName: 'read_file',
          arguments: {'path': 'creds.txt'},
          executionMode: 'sequential',
        ),
      ]),
    );

    final toolMessage = result.transcript.singleWhere((m) => m.role == 'tool');
    expect(toolMessage.content, 'creds: $_awsSecret');
  });
}
