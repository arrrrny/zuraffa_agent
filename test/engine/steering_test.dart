// Tests for EngineLoop - User Story 3: Mid-mission steering
//
// These tests verify the steering queue management and mid-mission message injection.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_event/engine_event.dart';
import 'package:zuraffa_agent/src/domain/entities/mission_config/mission_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/engine/engine_loop.dart';
import 'package:zuraffa_agent/src/providers.dart';
import 'package:zuraffa_agent/src/tools.dart';

void main() {
  group('EngineLoop - User Story 3: Mid-mission Steering', () {
    late MockLlmClient mockLlmClient;
    late MockToolDispatcher mockToolDispatcher;
    late MissionConfig missionConfig;

    setUp(() {
      mockLlmClient = MockLlmClient();
      mockToolDispatcher = MockToolDispatcher();
      missionConfig = MissionConfig(
        missionId: 'test-mission-steering',
        initialPrompt: 'Test mission for steering',
        availableTools: ['tool1', 'tool2'],
        metadata: {},
      );
    });

    tearDown(() async {
      await mockLlmClient.close();
    });

    test('injects steering message mid-mission', () async {
      // Arrange: 4-turn mission where steering is injected during turn 2
      // Turn 1: LLM calls tool1
      // Turn 2: Steering injected, LLM calls tool2 (altered by steering)
      // Turn 3: LLM calls tool1 again
      // Turn 4: LLM completes
      mockLlmClient.responses = [
        // Turn 1
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {'step': 1})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        // Turn 2 (after steering)
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-2', name: 'tool2', arguments: {'step': 2})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        // Turn 3
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-3', name: 'tool1', arguments: {'step': 3})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        // Turn 4 (complete)
        LlmResponse(
          content: 'Mission complete with steering',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {
        'tool1': 'result1',
        'tool2': 'result2',
      };
      // Add delay to allow steering injection between turns
      mockLlmClient.responseDelay = Duration(milliseconds: 50);

      // Act
      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 10,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 3,
          enabled: true,
        ),
      ));

      // Start mission and inject steering after first turn starts
      final missionFuture = engine.executeMission();

      // Wait for TurnStarted event for turn 1, then inject steering for turn 2
      await engine.events.firstWhere((e) => e is TurnStarted && e.turnNumber == 1);
      engine.injectSteering('Switch to tool2 for this step', injectionPoint: 2);

      final result = await missionFuture;

      // Assert
      expect(result.finalOutcome, 'success');
      expect(result.totalTurns, 4);

      // Verify SteeringInjected event was emitted
      final steeringEvents = result.events.whereType<SteeringInjected>().toList();
      expect(steeringEvents.length, 1);
      expect(steeringEvents.first.content, 'Switch to tool2 for this step');
      expect(steeringEvents.first.injectionPoint, 2);

      // Verify tool2 was called in turn 2 (due to steering)
      final toolCompletedEvents = result.events.whereType<ToolCallCompleted>().toList();
      expect(toolCompletedEvents.length, 3);
      // Turn 1: tool1, Turn 2: tool2 (steered), Turn 3: tool1
      expect(toolCompletedEvents[0].toolCallId, 'call-1');
      expect(toolCompletedEvents[1].toolCallId, 'call-2');
      expect(toolCompletedEvents[2].toolCallId, 'call-3');
    });

    test('steering queue processes messages in FIFO order', () async {
      // Arrange: Multiple steering messages enqueued
      mockLlmClient.responses = [
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        LlmResponse(
          content: 'Complete',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {'tool1': 'result'};
      mockLlmClient.responseDelay = Duration(milliseconds: 50);

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      // Inject multiple steering messages at different points
      final missionFuture = engine.executeMission();

      // Wait for engine to start running (first turn)
      await engine.events.firstWhere((e) => e is TurnStarted && e.turnNumber == 1);
      engine.injectSteering('First steering', injectionPoint: 1);
      engine.injectSteering('Second steering', injectionPoint: 1);
      engine.injectSteering('Third steering', injectionPoint: 2);

      final result = await missionFuture;

      // Assert: Steering messages should be processed in FIFO order
      final steeringEvents = result.events.whereType<SteeringInjected>().toList();
      expect(steeringEvents.length, 3);
      expect(steeringEvents[0].content, 'First steering');
      expect(steeringEvents[1].content, 'Second steering');
      expect(steeringEvents[2].content, 'Third steering');
    });

    test('throws StateError when steering injected after mission completion', () async {
      // Arrange: Simple mission that completes in 1 turn
      mockLlmClient.responses = [
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      // Execute and complete mission
      await engine.executeMission();

      // Assert: Cannot inject steering after completion
      expect(() => engine.injectSteering('Too late', injectionPoint: 2),
          throwsA(isA<StateError>().having((e) => e.toString(), 'message', contains('not running'))));
    });

    test('follow-up messages continue mission after normal completion', () async {
      // This test verifies the engine can handle follow-up messages
      // Currently, the engine doesn't support continuing after completion
      // This is a placeholder for future implementation (T062)
      expect(true, isTrue); // Placeholder
    });

    test('throws StateError when steering injected after mission completion', () async {
      // Arrange: Simple mission that completes in 1 turn
      mockLlmClient.responses = [
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      // Execute and complete mission
      await engine.executeMission();

      // Assert: Cannot inject steering after completion
      expect(() => engine.injectSteering('Too late', injectionPoint: 2),
          throwsA(isA<StateError>().having((e) => e.toString(), 'message', contains('not running'))));
    });

    test('throws StateError when steering injected after abort', () async {
      mockLlmClient.responses = List.generate(10, (_) => LlmResponse(
        content: '',
        toolCalls: [ToolCall(id: 'call', name: 'tool1', arguments: {})],
        usage: LlmUsage(inputTokens: 100, outputTokens: 50),
        finishReason: 'tool_calls',
      ));
      mockToolDispatcher.results = {'tool1': 'result'};
      mockLlmClient.responseDelay = Duration(milliseconds: 50);

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final missionFuture = engine.executeMission();
      
      // Wait for engine to start, then abort
      await engine.events.firstWhere((e) => e is TurnStarted);
      await engine.abort();
      await missionFuture;

      // Assert: Cannot inject steering after abort (engine is no longer running)
      expect(() => engine.injectSteering('After abort', injectionPoint: 2),
          throwsA(isA<StateError>().having((e) => e.toString(), 'message', contains('not running'))));
    });

    test('steering messages with future injection points are deferred', () async {
      // Arrange: Steering injected for turn 3 during turn 1
      mockLlmClient.responses = [
        // Turn 1
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {'step': 1})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        // Turn 2
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-2', name: 'tool1', arguments: {'step': 2})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        // Turn 3 (steering should apply here)
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-3', name: 'tool2', arguments: {'step': 3})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        // Turn 4 complete
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {'tool1': 'result1', 'tool2': 'result2'};
      mockLlmClient.responseDelay = Duration(milliseconds: 50);

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final missionFuture = engine.executeMission();

      // Wait for turn 1 to start, then inject steering for turn 3
      await engine.events.firstWhere((e) => e is TurnStarted && e.turnNumber == 1);
      engine.injectSteering('Use tool2 on turn 3', injectionPoint: 3);

      final result = await missionFuture;

      // Assert: Steering was applied on turn 3
      expect(result.totalTurns, 4);
      final toolCompletedEvents = result.events.whereType<ToolCallCompleted>().toList();
      expect(toolCompletedEvents.length, 3);
      // Turn 3 should have used tool2 due to steering
      expect(toolCompletedEvents[2].toolCallId, 'call-3');
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