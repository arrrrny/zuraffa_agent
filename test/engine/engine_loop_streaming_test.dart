// Tests for EngineLoop text streaming and OpenAI-protocol context assembly.
//
// Covers:
// - assistant text surfaced as TextDelta events and MissionResult.finalText
// - assistant `tool_calls` messages paired with their `tool` replies
// - EngineConfig.messageHistory and EngineConfig.toolDefinitions

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_event/engine_event.dart';
import 'package:zuraffa_agent/src/domain/entities/mission_config/mission_config.dart';
import 'package:zuraffa_agent/src/engine/engine_loop.dart';
import 'package:zuraffa_agent/src/providers.dart';
import 'package:zuraffa_agent/src/tools.dart';

void main() {
  late MissionConfig missionConfig;
  late FakeToolDispatcher toolDispatcher;

  setUp(() {
    missionConfig = MissionConfig(
      missionId: 'mission-streaming',
      initialPrompt: 'Find me red shoes',
      availableTools: ['search_products'],
      metadata: {},
    );
    toolDispatcher = FakeToolDispatcher();
  });

  group('EngineLoop - assistant text', () {
    test('emits TextDelta per chunk plus a final complete TextDelta', () async {
      final llmClient = FakeStreamingLlmClient([
        [
          _content('Hello'),
          _content(' world'),
          _done('stop'),
        ],
      ]);

      final engine = EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      ));
      final result = await engine.executeMission();

      final textDeltas = result.events.whereType<TextDelta>().toList();
      final partial = textDeltas.where((e) => !e.isComplete).toList();
      final complete = textDeltas.where((e) => e.isComplete).toList();

      expect(partial.map((e) => e.content).toList(), ['Hello', ' world']);
      expect(partial.map((e) => e.deltaIndex).toList(), [0, 1]);
      expect(complete.length, 1);
      expect(complete.single.content, 'Hello world');
      expect(complete.single.deltaIndex, 2);
      expect(complete.single.missionId, 'mission-streaming');
      expect(complete.single.eventId, isNotEmpty);
    });

    test('MissionResult.finalText holds the accumulated assistant text',
        () async {
      final llmClient = FakeStreamingLlmClient([
        [
          _content('Hello'),
          _content(' world'),
          _done('stop'),
        ],
      ]);

      final result = await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      expect(result.finalText, 'Hello world');
    });

    test('joins the text of every turn with a newline', () async {
      final llmClient = FakeStreamingLlmClient([
        [
          _content('Let me look'),
          _toolCall('call_1', 'search_products', {'query': 'red shoes'}),
          _done('tool_calls'),
        ],
        [
          _content('Found it'),
          _done('stop'),
        ],
      ]);

      final result = await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      expect(result.totalTurns, 2);
      expect(result.finalText, 'Let me look\nFound it');
    });

    test('finalText is empty when the model produced no text', () async {
      final llmClient = FakeStreamingLlmClient([
        [_done('stop')],
      ]);

      final result = await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      expect(result.finalText, '');
      expect(result.events.whereType<TextDelta>(), isEmpty);
    });
  });

  group('EngineLoop - context assembly', () {
    test('pairs the assistant tool_calls message with its tool replies',
        () async {
      final llmClient = FakeStreamingLlmClient([
        [
          _content('Let me look'),
          _toolCall('call_1', 'search_products', {'query': 'red shoes'}),
          _done('tool_calls'),
        ],
        [
          _content('Found it'),
          _done('stop'),
        ],
      ]);
      toolDispatcher.results['search_products'] = 'two matches';

      await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      expect(llmClient.capturedMessages.length, 2);

      // First turn sees only the user prompt.
      expect(llmClient.capturedMessages.first, [
        {'role': 'user', 'content': 'Find me red shoes'},
      ]);

      final secondTurn = llmClient.capturedMessages[1];
      expect(secondTurn.map((m) => m['role']).toList(),
          ['user', 'assistant', 'tool']);

      final assistant = secondTurn[1];
      expect(assistant['content'], 'Let me look');

      final toolCalls = assistant['tool_calls'] as List;
      expect(toolCalls.length, 1);
      final call = toolCalls.single as Map<String, dynamic>;
      expect(call['id'], 'call_1');
      expect(call['type'], 'function');
      final function = call['function'] as Map<String, dynamic>;
      expect(function['name'], 'search_products');
      // The wire format requires a JSON-encoded string, not a map.
      expect(function['arguments'], isA<String>());
      expect(jsonDecode(function['arguments'] as String),
          {'query': 'red shoes'});

      final toolMessage = secondTurn[2];
      expect(toolMessage['tool_call_id'], 'call_1');
      expect(toolMessage['content'], 'two matches');
    });

    test('reports a failed tool back to the model instead of empty content',
        () async {
      final llmClient = FakeStreamingLlmClient([
        [
          _toolCall('call_1', 'search_products', {'query': 'x'}),
          _done('tool_calls'),
        ],
        [
          _content('Sorry, that failed'),
          _done('stop'),
        ],
      ]);
      toolDispatcher.shouldThrow = true;

      await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      final toolMessage = llmClient.capturedMessages[1]
          .firstWhere((m) => m['role'] == 'tool');
      expect(toolMessage['content'] as String, contains('Error:'));
    });

    test('inlines thinking into the same turn assistant message', () async {
      final llmClient = FakeStreamingLlmClient([
        [
          LlmResponseChunk(
            content: '',
            thinking: 'weighing options',
            toolCalls: const [],
            isComplete: false,
          ),
          _content('Let me look'),
          _toolCall('call_1', 'search_products', {'query': 'x'}),
          _done('tool_calls'),
        ],
        [
          _content('Found it'),
          _done('stop'),
        ],
      ]);

      await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      final secondTurn = llmClient.capturedMessages[1];
      // No standalone assistant thinking message: exactly one assistant message,
      // and it is the one carrying the tool_calls.
      expect(secondTurn.where((m) => m['role'] == 'assistant').length, 1);
      expect(secondTurn[1]['content'],
          '<thinking>weighing options</thinking>Let me look');
    });

    test('prepends EngineConfig.messageHistory verbatim', () async {
      final llmClient = FakeStreamingLlmClient([
        [_content('ok'), _done('stop')],
      ]);

      await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
        messageHistory: [
          {'role': 'system', 'content': 'You are a shop assistant'},
          {'role': 'user', 'content': 'hi'},
          {'role': 'assistant', 'content': 'hello'},
        ],
      )).executeMission();

      expect(llmClient.capturedMessages.single, [
        {'role': 'system', 'content': 'You are a shop assistant'},
        {'role': 'user', 'content': 'hi'},
        {'role': 'assistant', 'content': 'hello'},
        {'role': 'user', 'content': 'Find me red shoes'},
      ]);
    });
  });

  group('EngineLoop - tool definitions', () {
    test('passes EngineConfig.toolDefinitions to the provider verbatim',
        () async {
      final llmClient = FakeStreamingLlmClient([
        [_content('ok'), _done('stop')],
      ]);
      final schemas = <Map<String, dynamic>>[
        {
          'type': 'function',
          'function': {
            'name': 'search_products',
            'description': 'Search the catalogue',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string'},
              },
              'required': ['query'],
            },
          },
        },
      ];

      await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
        toolDefinitions: schemas,
      )).executeMission();

      expect(llmClient.capturedTools.single, same(schemas));
    });

    test('falls back to name-only definitions when none are supplied',
        () async {
      final llmClient = FakeStreamingLlmClient([
        [_content('ok'), _done('stop')],
      ]);

      await EngineLoop(EngineConfig(
        missionConfig: missionConfig,
        llmClient: llmClient,
        toolDispatcher: toolDispatcher,
      )).executeMission();

      final tools = llmClient.capturedTools.single;
      expect(tools.length, 1);
      expect((tools.single['function'] as Map)['name'], 'search_products');
    });
  });
}

LlmResponseChunk _content(String content) => LlmResponseChunk(
      content: content,
      toolCalls: const [],
      isComplete: false,
    );

LlmResponseChunk _toolCall(
  String id,
  String name,
  Map<String, dynamic> arguments,
) =>
    LlmResponseChunk(
      content: '',
      toolCalls: [ToolCall(id: id, name: name, arguments: arguments)],
      isComplete: false,
    );

LlmResponseChunk _done(String finishReason) => LlmResponseChunk(
      content: '',
      toolCalls: const [],
      usage: const LlmUsage(inputTokens: 10, outputTokens: 5),
      isComplete: true,
      finishReason: finishReason,
    );

/// Fake [LlmClient] that replays a scripted chunk list per turn and records
/// what the engine sent it.
class FakeStreamingLlmClient implements LlmClient {
  FakeStreamingLlmClient(this.turns);

  final List<List<LlmResponseChunk>> turns;
  final List<List<Map<String, dynamic>>> capturedMessages = [];
  final List<List<Map<String, dynamic>>> capturedTools = [];
  int _turnIndex = 0;

  @override
  Future<LlmResponse> generate({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) async {
    throw UnsupportedError('FakeStreamingLlmClient only supports stream()');
  }

  @override
  Stream<LlmResponseChunk> stream({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) async* {
    capturedMessages.add(messages);
    capturedTools.add(tools);
    final chunks = _turnIndex < turns.length
        ? turns[_turnIndex]
        : <LlmResponseChunk>[_content('fallback'), _done('stop')];
    _turnIndex++;
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  @override
  Future<void> close() async {}
}

/// Fake [ToolDispatcher] returning canned results.
class FakeToolDispatcher implements ToolDispatcher {
  final Map<String, String> results = {};
  bool shouldThrow = false;

  @override
  Future<String> dispatch(String toolName, Map<String, dynamic> arguments) async {
    if (shouldThrow) {
      throw Exception('tool blew up');
    }
    return results[toolName] ?? 'default_result';
  }
}
