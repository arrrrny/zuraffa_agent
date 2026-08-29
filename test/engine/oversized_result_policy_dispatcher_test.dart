// R3#3 / SC-003 (spec-003 §4.3, FR-005) — real loop wiring of the oversized-result
// discipline.
//
// The model must never see a large tool body: a result exceeding the active
// OversizedResultPolicy.thresholdBytes is stored via ArtifactService and rewritten
// as a summary + artifactRef before it joins the mission transcript. These tests
// prove (a) the per-result converter and (b) the discipline end-to-end through the
// actual MissionRunner loop via the OversizedResultPolicyDispatcher decorator.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams, ProviderConfig;

import 'package:zuraffa_agent/src/artifact/artifact_service.dart';
import 'package:zuraffa_agent/src/artifact/in_memory_artifact_store.dart';
import 'package:zuraffa_agent/src/artifact/oversized_result_policy_applier.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/data/providers/oversized_result_policy/oversized_result_policy_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/artifact_ref/artifact_ref.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/oversized_result_policy/oversized_result_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/oversized_result_policy_dispatcher.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

// Local fakes mirroring test/engine/mission_runner_test.dart so this file is
// self-contained.
class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient({required this.completions})
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
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    return completions[callCount - 1];
  }
}

class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.planByCall);
  final Map<int, List<ToolCall>> planByCall;
  int _count = 0;

  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async {
    _count++;
    return planByCall[_count] ?? const [];
  }
}

class FakeBigToolDispatcher implements ToolDispatcher {
  FakeBigToolDispatcher(this.payload);
  final String payload;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      ToolDispatchResult(
        success: true,
        result: payload,
        error: '',
        artifactRefs: const [],
      );

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async =>
      const [];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) =>
      const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

const _testPolicy = OversizedResultPolicy(
  id: 'test',
  thresholdBytes: 1024 * 1024, // 1 MB — so a 2 MB result trips it
  summaryMaxChars: 64,
  artifactStore: './artifacts',
);

// Small threshold for the per-result unit cases (200-byte payloads trip it).
const _smallPolicy = OversizedResultPolicy(
  id: 'test-small',
  thresholdBytes: 100,
  summaryMaxChars: 64,
  artifactStore: './artifacts',
);

void main() {
  group('R3#3 / SC-003 — oversized-result loop wiring', () {
    group('enforceOversizedResultPolicyOnDispatch (unit)', () {
      test('a successful result exceeding the threshold is rewritten as summary + artifactRef', () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 100),
        );
        final result = ToolDispatchResult(
          success: true,
          result: 'x' * 200,
          error: '',
          artifactRefs: const [],
        );

        final out = await enforceOversizedResultPolicyOnDispatch(
          result: result,
          policy: _smallPolicy,
          artifactService: store,
        );

        expect(out.result, isNot(equals('x' * 200))); // summarized, not the full body
        expect(out.artifactRefs, hasLength(1));
        final artifact = await store.fetch(
          ArtifactRef(kind: 'artifact', id: out.artifactRefs.first),
        );
        expect(artifact, isNotNull);
        expect(utf8.decode(artifact!.data), equals('x' * 200));
      });

      test('a result within the threshold is unchanged', () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 100),
        );
        final result = ToolDispatchResult(
          success: true,
          result: 'small',
          error: '',
          artifactRefs: const [],
        );

        final out = await enforceOversizedResultPolicyOnDispatch(
          result: result,
          policy: _smallPolicy,
          artifactService: store,
        );

        expect(out.result, 'small');
        expect(out.artifactRefs, isEmpty);
      });

      test('an error result is never summarized', () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 100),
        );
        final result = ToolDispatchResult(
          success: false,
          result: '',
          error: 'x' * 200,
          artifactRefs: const [],
        );

        final out = await enforceOversizedResultPolicyOnDispatch(
          result: result,
          policy: _smallPolicy,
          artifactService: store,
        );

        expect(out.success, isFalse);
        expect(out.error, 'x' * 200);
        expect(out.artifactRefs, isEmpty);
      });
    });

    group('OversizedResultPolicyDispatcher (integration through MissionRunner)', () {
      test('a 2 MB tool result reaches the model transcript as a summary only, with artifactRef recorded', () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 1024 * 1024),
        );
        final big = 'x' * (2 * 1024 * 1024); // 2 MB
        final dispatcher = OversizedResultPolicyDispatcher(
          inner: FakeBigToolDispatcher(big),
          policyService: OversizedResultPolicyProvider(_testPolicy),
          artifactService: store,
        );
        final loop = const EngineLoop(
          id: 'l',
          sessionId: 's',
          maxTurns: 5,
          wallClockTimeoutMs: 0,
          repetitionThreshold: 0,
        );
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop,
            ScriptedLlmClient(
              completions: [completionOf('thinking'), completionOf('done')],
            ),
          ),
          toolDispatcher: dispatcher,
          stopPolicy: const StopPolicy(
            id: 't',
            maxTurns: 5,
            wallClockTimeout: Duration.zero,
            repetitionThreshold: 5,
          ),
          onEvent: (_) {},
        );

        final result = await runner.run(
          missionId: 'm',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          planner: ScriptedPlanner({
            1: [const ToolCall(toolName: 'big', arguments: {}, executionMode: 'sequential')],
          }),
        );

        // The tool-role message in the transcript must NOT contain the 2 MB body.
        final toolMsg = result.transcript.firstWhere((m) => m.role == 'tool');
        expect(toolMsg.content.length, lessThan(big.length));
        expect(toolMsg.content, isNot(equals(big)));

        // The full body is retrievable from the store by the recorded artifactRef.
        final refs = await store.list();
        expect(refs, hasLength(1));
        final artifact = await store.fetch(refs.first);
        expect(artifact, isNotNull);
        expect(utf8.decode(artifact!.data), equals(big));
      });
    });
  });
}
