// Tests for StopPolicy - User Story 4: Loop safety rails
//
// These tests verify the stop policy enforcement including max turns,
// wall-clock timeout, and repetition detection.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_event/engine_event.dart';
import 'package:zuraffa_agent/src/domain/entities/mission_config/mission_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart' show defaultPolicy;
import 'package:zuraffa_agent/src/engine/engine_loop.dart';
import 'package:zuraffa_agent/src/providers.dart';
import 'package:zuraffa_agent/src/tools.dart';

void main() {
  group('EngineLoop - Stop Policy (User Story 4)', () {
    late MockLlmClient mockLlmClient;
    late MockToolDispatcher mockToolDispatcher;
    late MissionConfig missionConfig;

    setUp(() {
      mockLlmClient = MockLlmClient();
      mockToolDispatcher = MockToolDispatcher();
      missionConfig = MissionConfig(
        missionId: 'test-stop-policy',
        initialPrompt: 'Test',
        availableTools: ['tool1'],
        metadata: {},
      );
    });

    tearDown(() async {
      await mockLlmClient.close();
    });

    test('enforces max turns limit and emits MaxTurnsExceeded', () async {
      // Arrange: LLM always returns tool calls with DIFFERENT arguments to avoid repetition detection
      mockLlmClient.responses = List.generate(15, (i) => LlmResponse(
        content: '',
        toolCalls: [ToolCall(id: 'call-$i', name: 'tool1', arguments: {'step': i})],
        usage: LlmUsage(inputTokens: 100, outputTokens: 50),
        finishReason: 'tool_calls',
      ));
      mockToolDispatcher.results = {'tool1': 'result'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 5,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 3,
          enabled: true,
        ),
      ));
      final result = await engine.executeMission();

      // Assert: Should stop at maxTurns (5 turns)
      expect(result.totalTurns, 5);
      expect(result.finalOutcome, 'max_turns_exceeded');
      
      final missionCompleted = result.events.whereType<MissionCompleted>().first;
      expect(missionCompleted.outcome, 'max_turns_exceeded');
    });

    test('enforces wall-clock timeout and emits timeout outcome', () async {
      // Arrange: LLM always returns tool calls, with small timeout
      mockLlmClient.responses = List.generate(100, (_) => LlmResponse(
        content: '',
        toolCalls: [ToolCall(id: 'call', name: 'tool1', arguments: {})],
        usage: LlmUsage(inputTokens: 100, outputTokens: 50),
        finishReason: 'tool_calls',
      ));
      mockToolDispatcher.results = {'tool1': 'result'};
      mockLlmClient.responseDelay = Duration(milliseconds: 50); // Slow responses

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 100,
          wallClockTimeoutMs: 200, // 200ms timeout
          repetitionThreshold: 3,
          enabled: true,
        ),
      ));
      final result = await engine.executeMission();

      // Assert: Should stop due to timeout
      expect(result.finalOutcome, 'timeout');
      expect(result.totalTurns, lessThan(100));
      
      final missionCompleted = result.events.whereType<MissionCompleted>().first;
      expect(missionCompleted.outcome, 'timeout');
    });

    test('detects repetitive tool calls and emits LoopDetected', () async {
      // Arrange: LLM returns same tool call repeatedly
      mockLlmClient.responses = List.generate(10, (_) => LlmResponse(
        content: '',
        toolCalls: [ToolCall(id: 'call', name: 'tool1', arguments: {'same': 'args'})],
        usage: LlmUsage(inputTokens: 100, outputTokens: 50),
        finishReason: 'tool_calls',
      ));
      mockToolDispatcher.results = {'tool1': 'result'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 100,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 3, // Should detect after 3 repetitions
          enabled: true,
        ),
      ));
      final result = await engine.executeMission();

      // Assert: Should stop due to repetition detection
      expect(result.finalOutcome, 'loop_detected');
      expect(result.totalTurns, lessThanOrEqualTo(5)); // 1st + 3 repetitions = 4 turns max
      
      final missionCompleted = result.events.whereType<MissionCompleted>().first;
      expect(missionCompleted.outcome, 'loop_detected');
    });

    test('repetition detection distinguishes different arguments', () async {
      // Arrange: LLM returns tool calls with different arguments (not repetitive)
      // Provide 5 tool_calls responses + 1 final stop response = 6 total turns
      mockLlmClient.responses = List.generate(6, (i) {
        if (i < 5) {
          return LlmResponse(
            content: '',
            toolCalls: [ToolCall(id: 'call-$i', name: 'tool1', arguments: {'step': i})],
            usage: LlmUsage(inputTokens: 100, outputTokens: 50),
            finishReason: 'tool_calls',
          );
        } else {
          // Final response with no tool calls - mission completes
          return LlmResponse(
            content: 'Done',
            toolCalls: [],
            usage: LlmUsage(inputTokens: 50, outputTokens: 20),
            finishReason: 'stop',
          );
        }
      });
      mockToolDispatcher.results = {'tool1': 'result'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 100,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 3,
          enabled: true,
        ),
      ));
      final result = await engine.executeMission();

      // Assert: Should NOT stop due to repetition (different args)
      // Completes after 5 tool_calls turns + 1 stop turn = 6 turns
      expect(result.finalOutcome, 'success');
      expect(result.totalTurns, 6);
    });

    test('repetition detection resets on different tool', () async {
      // Arrange: Alternating tools should not trigger repetition
      mockLlmClient.responses = [
        LlmResponse(content: '', toolCalls: [ToolCall(id: '1', name: 'tool1', arguments: {})], usage: LlmUsage(inputTokens: 100, outputTokens: 50), finishReason: 'tool_calls'),
        LlmResponse(content: '', toolCalls: [ToolCall(id: '2', name: 'tool2', arguments: {})], usage: LlmUsage(inputTokens: 100, outputTokens: 50), finishReason: 'tool_calls'),
        LlmResponse(content: '', toolCalls: [ToolCall(id: '3', name: 'tool1', arguments: {})], usage: LlmUsage(inputTokens: 100, outputTokens: 50), finishReason: 'tool_calls'),
        LlmResponse(content: '', toolCalls: [ToolCall(id: '4', name: 'tool2', arguments: {})], usage: LlmUsage(inputTokens: 100, outputTokens: 50), finishReason: 'tool_calls'),
        LlmResponse(content: '', toolCalls: [ToolCall(id: '5', name: 'tool1', arguments: {})], usage: LlmUsage(inputTokens: 100, outputTokens: 50), finishReason: 'tool_calls'),
        LlmResponse(content: '', toolCalls: [ToolCall(id: '6', name: 'tool2', arguments: {})], usage: LlmUsage(inputTokens: 100, outputTokens: 50), finishReason: 'tool_calls'),
        LlmResponse(content: 'Done', toolCalls: [], usage: LlmUsage(inputTokens: 50, outputTokens: 20), finishReason: 'stop'),
      ];
      mockToolDispatcher.results = {'tool1': 'result1', 'tool2': 'result2'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 100,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 3,
          enabled: true,
        ),
      ));
      final result = await engine.executeMission();

      // Assert: Should NOT stop due to repetition (alternating tools)
      expect(result.finalOutcome, 'success');
      expect(result.totalTurns, 7);
    });
  });

  group('StopPolicy Entity', () {
    test('defaultPolicy() returns correct defaults', () {
      final policy = defaultPolicy();
      
      expect(policy.maxTurns, 100);
      expect(policy.wallClockTimeoutMs, 300000);
      expect(policy.repetitionThreshold, 3);
      expect(policy.enabled, true);
    });

    test('copyWith() creates immutable copies', () {
      final original = StopPolicy(
        maxTurns: 10,
        wallClockTimeoutMs: 5000,
        repetitionThreshold: 2,
        enabled: true,
      );

      final modified = original.copyWith(maxTurns: 20, enabled: false);

      expect(original.maxTurns, 10);
      expect(original.wallClockTimeoutMs, 5000);
      expect(original.repetitionThreshold, 2);
      expect(original.enabled, true);

      expect(modified.maxTurns, 20);
      expect(modified.wallClockTimeoutMs, 5000);
      expect(modified.repetitionThreshold, 2);
      expect(modified.enabled, false);
    });

    test('StopPolicy equality works correctly', () {
      const testId = 'test-equality-id';
      final p1 = StopPolicy(id: testId, maxTurns: 10, wallClockTimeoutMs: 5000, repetitionThreshold: 2, enabled: true);
      final p2 = StopPolicy(id: testId, maxTurns: 10, wallClockTimeoutMs: 5000, repetitionThreshold: 2, enabled: true);
      final p3 = StopPolicy(id: 'different-id', maxTurns: 20, wallClockTimeoutMs: 5000, repetitionThreshold: 2, enabled: true);

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('StopPolicy toJson and fromJson roundtrip', () {
      final original = StopPolicy(
        maxTurns: 25,
        wallClockTimeoutMs: 120000,
        repetitionThreshold: 5,
        enabled: false,
      );

      final json = original.toJson();
      final restored = StopPolicy.fromJson(json);

      expect(restored.maxTurns, original.maxTurns);
      expect(restored.wallClockTimeoutMs, original.wallClockTimeoutMs);
      expect(restored.repetitionThreshold, original.repetitionThreshold);
      expect(restored.enabled, original.enabled);
    });
  });
}

/// Mock LLM Client for testing
class MockLlmClient implements LlmClient {
  List<LlmResponse> responses = [];
  List<Stream<LlmResponseChunk>> streamResponses = [];
  bool shouldThrow = false;
  int callCount = 0;
  Duration responseDelay = Duration.zero;

  @override
  Future<LlmResponse> generate({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) async {
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    if (shouldThrow) {
      throw Exception('Provider disconnected');
    }
    if (callCount >= responses.length) {
      return LlmResponse(
        content: 'Default response',
        toolCalls: [],
        usage: LlmUsage(inputTokens: 10, outputTokens: 10),
        finishReason: 'stop',
      );
    }
    return responses[callCount++];
  }

  @override
  Stream<LlmResponseChunk> stream({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) async* {
    if (shouldThrow) {
      throw Exception('Provider disconnected');
    }
    if (streamResponses.isNotEmpty && callCount < streamResponses.length) {
      final stream = streamResponses[callCount++];
      await for (final chunk in stream) {
        yield chunk;
      }
    } else if (responses.isNotEmpty && callCount < responses.length) {
      final response = responses[callCount++];

      if (responseDelay > Duration.zero) {
        await Future<void>.delayed(responseDelay);
      }

      String remainingContent = response.content;
      while (remainingContent.contains('<thinking>')) {
        final thinkingStart = remainingContent.indexOf('<thinking>');
        if (thinkingStart >= 0) {
          final thinkingEnd = remainingContent.indexOf('</thinking>', thinkingStart);
          if (thinkingEnd > thinkingStart) {
            final thinking = remainingContent.substring(thinkingStart + 10, thinkingEnd);
            yield LlmResponseChunk(
              content: '',
              thinking: thinking,
              toolCalls: [],
              usage: null,
              isComplete: false,
            );
          }
          remainingContent = remainingContent.substring(thinkingEnd + 11);
        } else {
          break;
        }
      }

      if (remainingContent.isNotEmpty) {
        yield LlmResponseChunk(
          content: remainingContent,
          thinking: null,
          toolCalls: [],
          usage: null,
          isComplete: false,
        );
      }

      if (response.toolCalls.isNotEmpty) {
        yield LlmResponseChunk(
          content: '',
          thinking: null,
          toolCalls: response.toolCalls,
          usage: null,
          isComplete: false,
        );
      }

      yield LlmResponseChunk(
        content: '',
        thinking: null,
        toolCalls: [],
        usage: response.usage,
        isComplete: true,
        finishReason: response.finishReason,
      );
    } else {
      yield LlmResponseChunk(
        content: 'Default response',
        thinking: null,
        toolCalls: [],
        usage: LlmUsage(inputTokens: 10, outputTokens: 10),
        isComplete: true,
        finishReason: 'stop',
      );
    }
  }

  @override
  Future<void> close() async {}
}

/// Mock Tool Dispatcher for testing
class MockToolDispatcher implements ToolDispatcher {
  Map<String, String> results = {};
  bool shouldThrow = false;

  @override
  Future<String> dispatch(String toolName, Map<String, dynamic> arguments) async {
    if (shouldThrow) {
      throw Exception('Tool execution failed');
    }
    return results[toolName] ?? 'default_result';
  }
}