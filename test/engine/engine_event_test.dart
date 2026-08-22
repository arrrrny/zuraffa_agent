// Tests for EngineEvent - User Story 5: Typed streaming events
//
// These tests verify that all engine event types are emitted correctly
// with proper structure and can be serialized/deserialized.

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_event/engine_event.dart';
import 'package:zuraffa_agent/src/domain/entities/mission_config/mission_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/engine/engine_loop.dart';
import 'package:zuraffa_agent/src/providers.dart';
import 'package:zuraffa_agent/src/tools.dart';

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

void main() {
  group('EngineEvent Types (User Story 5)', () {
    late MockLlmClient mockLlmClient;
    late MockToolDispatcher mockToolDispatcher;
    late MissionConfig missionConfig;

    setUp(() {
      mockLlmClient = MockLlmClient();
      mockToolDispatcher = MockToolDispatcher();
      missionConfig = MissionConfig(
        missionId: 'test-events',
        initialPrompt: 'Test mission',
        availableTools: ['tool1', 'tool2'],
        metadata: {},
      );
    });

    tearDown(() async {
      await mockLlmClient.close();
    });

    test('emits MissionStarted as first event with correct structure', () async {
      mockLlmClient.responses = [
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final subscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      await engine.executeMission();
      await completer.future;
      await subscription.cancel();

      // First event should be MissionStarted
      expect(events.first, isA<MissionStarted>());
      final started = events.first as MissionStarted;
      expect(started.missionId, 'test-events');
      expect(started.config['initialPrompt'], 'Test mission');
      expect(started.sequenceNumber, 0);
    });

    test('emits TurnStarted and TurnCompleted for each turn', () async {
      mockLlmClient.responses = [
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {'tool1': 'result'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final subscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      await engine.executeMission();
      await completer.future;
      await subscription.cancel();

      // Check TurnStarted events
      final turnStartedEvents = events.whereType<TurnStarted>().toList();
      expect(turnStartedEvents.length, 2);
      expect(turnStartedEvents[0].turnNumber, 1);
      expect(turnStartedEvents[1].turnNumber, 2);

      // Check TurnCompleted events
      final turnCompletedEvents = events.whereType<TurnCompleted>().toList();
      expect(turnCompletedEvents.length, 2);
      expect(turnCompletedEvents[0].turnNumber, 1);
      expect(turnCompletedEvents[0].finishReason, 'tool_calls');
      expect(turnCompletedEvents[0].toolCallCount, 1);
      expect(turnCompletedEvents[1].turnNumber, 2);
      expect(turnCompletedEvents[1].finishReason, 'stop');
      expect(turnCompletedEvents[1].toolCallCount, 0);
    });

    test('emits ToolCallStarted and ToolCallCompleted for each tool call', () async {
      mockLlmClient.responses = [
        LlmResponse(
          content: '',
          toolCalls: [
            ToolCall(id: 'call-1', name: 'tool1', arguments: {'arg1': 'value1'}),
            ToolCall(id: 'call-2', name: 'tool2', arguments: {'arg2': 'value2'}),
          ],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {'tool1': 'result1', 'tool2': 'result2'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final subscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      await engine.executeMission();
      await completer.future;
      await subscription.cancel();

      // Check ToolCallStarted events
      final toolCallStartedEvents = events.whereType<ToolCallStarted>().toList();
      expect(toolCallStartedEvents.length, 2);
      expect(toolCallStartedEvents[0].toolCallId, 'call-1');
      expect(toolCallStartedEvents[0].toolName, 'tool1');
      expect(toolCallStartedEvents[0].arguments, {'arg1': 'value1'});
      expect(toolCallStartedEvents[0].callIndex, 0);
      expect(toolCallStartedEvents[1].toolCallId, 'call-2');
      expect(toolCallStartedEvents[1].toolName, 'tool2');
      expect(toolCallStartedEvents[1].arguments, {'arg2': 'value2'});
      expect(toolCallStartedEvents[1].callIndex, 1);

      // Check ToolCallCompleted events
      final toolCallCompletedEvents = events.whereType<ToolCallCompleted>().toList();
      expect(toolCallCompletedEvents.length, 2);
      expect(toolCallCompletedEvents[0].toolCallId, 'call-1');
      expect(toolCallCompletedEvents[0].result, 'result1');
      expect(toolCallCompletedEvents[0].errorMessage, null);
      expect(toolCallCompletedEvents[0].durationMs, greaterThanOrEqualTo(0));
      expect(toolCallCompletedEvents[1].toolCallId, 'call-2');
      expect(toolCallCompletedEvents[1].result, 'result2');
    });

    test('emits ThinkingDelta events for thinking content', () async {
      mockLlmClient.responses = [
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      // Add thinking content to first response
      mockLlmClient.responses[0] = LlmResponse(
        content: '<thinking>Let me think about this</thinking>',
        toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {})],
        usage: LlmUsage(inputTokens: 100, outputTokens: 50),
        finishReason: 'tool_calls',
      );
      mockToolDispatcher.results = {'tool1': 'result'};

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final subscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      await engine.executeMission();
      await completer.future;
      await subscription.cancel();

      // Check ThinkingDelta events
      final thinkingEvents = events.whereType<ThinkingDelta>().toList();
      expect(thinkingEvents.length, greaterThanOrEqualTo(1));
      
      // First thinking delta should be incomplete
      final firstThinking = thinkingEvents.firstWhere((e) => !e.isComplete);
      expect(firstThinking.content, contains('Let me think'));
      expect(firstThinking.isComplete, false);
      expect(firstThinking.deltaIndex, 0);

      // Last thinking delta should be complete
      final completeThinking = thinkingEvents.lastWhere((e) => e.isComplete);
      expect(completeThinking.isComplete, true);
      expect(completeThinking.content, contains('Let me think'));
    });

    test('emits MissionCompleted as final event with correct outcome', () async {
      mockLlmClient.responses = [
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final subscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      await engine.executeMission();
      await completer.future;
      await subscription.cancel();

      // Last event should be MissionCompleted
      expect(events.last, isA<MissionCompleted>());
      final completed = events.last as MissionCompleted;
      expect(completed.missionId, 'test-events');
      expect(completed.outcome, 'success');
      expect(completed.totalTurns, 1);
      expect(completed.errorMessage, null);
    });

    test('emits MissionCompleted with error outcome on abort', () async {
      mockLlmClient.responses = List.generate(100, (_) => LlmResponse(
        content: '',
        toolCalls: [ToolCall(id: 'call', name: 'tool1', arguments: {})],
        usage: LlmUsage(inputTokens: 100, outputTokens: 50),
        finishReason: 'tool_calls',
      ));
      mockToolDispatcher.results = {'tool1': 'result'};
      // Add delay so abort can take effect before all turns complete
      mockLlmClient.responseDelay = Duration(milliseconds: 10);

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
        stopPolicy: StopPolicy(
          maxTurns: 100,
          wallClockTimeoutMs: 300000,
          repetitionThreshold: 100,
          enabled: true,
        ),
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final eventSubscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      
      // Start execution and abort after a short delay
      final executionFuture = engine.executeMission();
      await Future<void>.delayed(Duration(milliseconds: 50));
      await engine.abort();
      await executionFuture;
      await completer.future;
      await eventSubscription.cancel();

      // Last event should be MissionCompleted with error outcome
      final completedEvents = events.whereType<MissionCompleted>().toList();
      expect(completedEvents.length, 1);
      final completed = completedEvents.first;
      expect(completed.outcome, 'error');
      expect(completed.errorMessage, 'Mission aborted by user');
    });

    test('emits SteeringInjected when steering is injected', () async {
      mockLlmClient.responses = [
        LlmResponse(
          content: '',
          toolCalls: [ToolCall(id: 'call-1', name: 'tool1', arguments: {})],
          usage: LlmUsage(inputTokens: 100, outputTokens: 50),
          finishReason: 'tool_calls',
        ),
        LlmResponse(
          content: 'Done',
          toolCalls: [],
          usage: LlmUsage(inputTokens: 50, outputTokens: 20),
          finishReason: 'stop',
        ),
      ];
      mockToolDispatcher.results = {'tool1': 'result'};
      // Add delay so engine doesn't complete before steering injection
      mockLlmClient.responseDelay = Duration(milliseconds: 50);

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: mockLlmClient,
        toolDispatcher: mockToolDispatcher,
      ));

      final events = <EngineEvent>[];
      final completer = Completer<void>();
      final eventSubscription = engine.events.listen(
        events.add,
        onDone: () => completer.complete(),
      );
      
      // Start execution
      final executionFuture = engine.executeMission();
      
      // Wait for first turn to start, then inject steering
      await Future<void>.delayed(Duration(milliseconds: 10));
      engine.injectSteering('Please focus on X', injectionPoint: 2);
      
      await executionFuture;
      await completer.future;
      await eventSubscription.cancel();

      // Check SteeringInjected event
      final steeringEvents = events.whereType<SteeringInjected>().toList();
      expect(steeringEvents.length, 1);
      expect(steeringEvents[0].content, 'Please focus on X');
      expect(steeringEvents[0].injectionPoint, 2);
    });

    test('all event types can be serialized to JSON and back', () {
      final events = [
        MissionStarted(
          eventId: 'evt-1',
          sequenceNumber: 0,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          config: {'key': 'value'},
        ),
        MissionCompleted(
          eventId: 'evt-2',
          sequenceNumber: 1,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          outcome: 'success',
          errorMessage: null,
          totalTurns: 5,
        ),
        TurnStarted(
          eventId: 'evt-3',
          sequenceNumber: 2,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          turnNumber: 1,
          messageIds: ['msg-1'],
        ),
        TurnCompleted(
          eventId: 'evt-4',
          sequenceNumber: 3,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          turnNumber: 1,
          finishReason: 'tool_calls',
          toolCallCount: 2,
        ),
        ThinkingDelta(
          eventId: 'evt-5',
          sequenceNumber: 4,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          content: 'thinking content',
          deltaIndex: 0,
          isComplete: false,
        ),
        TextDelta(
          eventId: 'evt-5b',
          sequenceNumber: 4,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          content: 'assistant text',
          deltaIndex: 0,
          isComplete: true,
        ),
        ToolCallStarted(
          eventId: 'evt-6',
          sequenceNumber: 5,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          toolCallId: 'call-1',
          toolName: 'tool1',
          arguments: {'arg': 'value'},
          callIndex: 0,
        ),
        ToolCallCompleted(
          eventId: 'evt-7',
          sequenceNumber: 6,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          toolCallId: 'call-1',
          result: 'result',
          errorMessage: null,
          durationMs: 100,
        ),
        ProviderError(
          eventId: 'evt-8',
          sequenceNumber: 7,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          errorType: 'timeout',
          message: 'Request timed out',
          isRecoverable: true,
        ),
        SteeringInjected(
          eventId: 'evt-9',
          sequenceNumber: 8,
          timestamp: DateTime.now(),
          missionId: 'mission-1',
          messageId: 'msg-1',
          content: 'steering content',
          injectionPoint: 2,
        ),
      ];

      for (final event in events) {
        // Serialize to JSON using the specific event's toJson (via EngineEventSerialization extension)
        final Map<String, dynamic> json = (event as dynamic).toJson() as Map<String, dynamic>;
        expect(json['__typename'], isNotNull);
        expect(json['eventId'], event.eventId);
        expect(json['missionId'], event.missionId);

        // Deserialize back
        final restored = EngineEvent.fromJson(json);
        expect(restored.runtimeType, event.runtimeType);
        expect(restored.eventId, event.eventId);
        expect(restored.missionId, event.missionId);
        expect(restored.sequenceNumber, event.sequenceNumber);
      }
    });

    test('EngineEvent.fromJson handles unknown type gracefully', () {
      final json = {
        '__typename': 'UnknownEvent',
        'eventId': 'evt-1',
        'sequenceNumber': 0,
        'timestamp': DateTime.now().toIso8601String(),
        'missionId': 'mission-1',
      };
      
      // Should throw an error for unknown type (UnsupportedError is an Error, not Exception)
      expect(() => EngineEvent.fromJson(json), throwsA(isA<Error>()));
    });
  });
}