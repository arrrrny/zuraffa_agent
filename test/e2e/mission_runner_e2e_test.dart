// E2E — issue #113: the full multi-turn mission loop, composed exactly the
// way production wires it, with NO component-level shortcuts:
//
//   FakeLlmClient (seam-level LlmClient, test/llm/fake_llm_client.dart)
//     -> LlmClientProvider (request conversion + response projection)
//       -> EngineLoopExecutor (turn cap enforcement)
//         -> MissionRunner (loop: steering drain, tool dispatch, stop policies)
//           -> registry-backed dispatcher over the REAL InMemoryToolRegistry
//
// Unlike the spec-069 unit suite (ScriptedLlmClient returns ChatCompletion
// directly, bypassing the provider), this drives the seam client: every turn
// is a real LlmRequest/LlmResponse round-trip through the provider's
// ChatMessage -> AgentMessage conversion and back, so the E2E proves tool
// results and steering input actually reach the next wire request.
//
// Coverage: 5+ turns including tool calls (fs.read x2, calc.add), a
// mid-mission steering injection enqueued from an event handler (spec 002
// FR-003), and a stop-on-maxTurns mission in a second test.
//
// AgentTool is declaration-only (no handler field), and no production
// registry-backed dispatcher exists yet (mission_runner.dart header: "tests
// inject fakes, future specs inject the real registry/dispatcher") — so the
// dispatcher here is a test-owned bridge that resolves every call through
// the real InMemoryToolRegistry (registration, namespace resolution,
// params-schema validation, risk-tier check) and executes deterministic
// handlers keyed by tool id.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_message/steering_message.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_queue/steering_queue.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/in_memory_tool_registry.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/engine/tool_registry.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

import '../llm/fake_llm_client.dart';

/// The real tool surface the mission dispatches against, registered in the
/// real InMemoryToolRegistry (DDA namespace: bare ids).
const fsReadTool = AgentTool(
  id: 'fs.read',
  description: 'Reads a file from the mission workspace.',
  paramsSchema: {
    'type': 'object',
    'required': ['path'],
  },
);

const calcAddTool = AgentTool(
  id: 'calc.add',
  description: 'Adds two numbers.',
  paramsSchema: {
    'type': 'object',
    'required': ['a', 'b'],
  },
);

/// Dispatcher backed by the REAL [ToolRegistry]: every dispatch resolves the
/// tool through the registry first (namespace + collision + schema metadata),
/// then executes the deterministic handler keyed by tool id.
class RegistryBackedDispatcher implements ToolDispatcher {
  RegistryBackedDispatcher(this._registry, this._handlers);

  final ToolRegistry _registry;
  final Map<String, Object? Function(Map<String, dynamic> arguments)> _handlers;
  final List<String> dispatched = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    dispatched.add(toolName);
    final tool = await _registry.resolve(toolName);
    if (tool == null) {
      return ToolDispatchResult(
        success: false,
        result: '',
        error: 'unknown tool "$toolName" — not registered in the ToolRegistry',
        artifactRefs: const [],
      );
    }
    if (tool.isAdmin && !isInternalMission) {
      return ToolDispatchResult(
        success: false,
        result: '',
        error:
            'tool "$toolName" is admin-tier and this mission carries no '
            'admin grant',
        artifactRefs: const [],
      );
    }
    final handler = _handlers[tool.id];
    if (handler == null) {
      return ToolDispatchResult(
        success: false,
        result: '',
        error: 'tool "$toolName" has no handler wired in this test',
        artifactRefs: const [],
      );
    }
    try {
      return ToolDispatchResult(
        success: true,
        result: '${handler(arguments)}',
        error: '',
        artifactRefs: const [],
      );
    } catch (e) {
      return ToolDispatchResult(
        success: false,
        result: '',
        error: e.toString(),
        artifactRefs: const [],
      );
    }
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) => Future.wait([
    for (final call in calls)
      dispatch(
        toolName: call.toolName,
        arguments: call.arguments,
        isInternalMission: isInternalMission,
      ),
  ]);

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) {
    final required = schema['required'];
    if (required is! List) return const [];
    return [
      for (final key in required)
        if (!arguments.containsKey(key)) 'missing required param: $key',
    ];
  }

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => riskTier != 'admin' || isInternalMission;
}

/// The pluggable tool-call parser seam (ToolCallPlanner). ChatCompletion
/// carries no structured tool-call payload (spec 051), so — exactly like a
/// real parser would — it reads the model's TEXT output: a line
/// `@tool:<name> {json}` plans a call, anything else plans nothing.
class MarkerPlanner implements ToolCallPlanner {
  final planned = <List<ToolCall>>[];

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    final pattern = RegExp(r'@tool:([A-Za-z0-9_.:-]+)(?:\s+(\{[^\n]*\}))?');
    final calls = <ToolCall>[];
    for (final match in pattern.allMatches(completion.content)) {
      Map<String, dynamic> arguments = const {};
      final rawArgs = match.group(2);
      if (rawArgs != null) {
        arguments = jsonDecode(rawArgs) as Map<String, dynamic>;
      }
      calls.add(
        ToolCall(
          toolName: match.group(1)!,
          arguments: arguments,
          executionMode: 'sequential',
        ),
      );
    }
    planned.add(calls);
    return calls;
  }
}

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  Future<
    (
      MissionRunner,
      FakeLlmClient,
      RegistryBackedDispatcher,
      InMemoryToolRegistry,
    )
  >
  makeRunner({
    required List<ScriptedOutcome> outcomes,
    required List<EngineEvent> events,
    required SteeringQueue queue,
    void Function(EngineEvent event)? onEvent,
    EngineLoop? loop,
  }) async {
    final registry = InMemoryToolRegistry();
    await registry.registerDdaTool(fsReadTool);
    await registry.registerDdaTool(calcAddTool);
    final dispatcher = RegistryBackedDispatcher(registry, {
      'fs.read': (arguments) {
        final path = arguments['path'] as String?;
        return switch (path) {
          'brief.txt' => 'MISSION BRIEF v7: keep the gate green.',
          'notes.txt' => 'NOTES: ratchet the coverage gate.',
          _ => throw StateError('no fixture file "$path" in this test'),
        };
      },
      'calc.add': (arguments) =>
          (arguments['a'] as num) + (arguments['b'] as num),
    });
    final fake = FakeLlmClient(
      providerName: 'fake-e2e',
      model: 'e2e-model',
      outcomes: outcomes,
    );
    final runner = MissionRunner(
      executor: EngineLoopExecutor(
        loop ??
            const EngineLoop(
              id: 'loop-e2e',
              sessionId: 's-e2e',
              maxTurns: 8,
              wallClockTimeoutMs: 60000,
              repetitionThreshold: 5,
            ),
        LlmClientProvider(
          config: const ProviderConfig(
            id: 'fake-e2e',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['e2e-model'],
            timeoutMs: 1,
          ),
          apiKey: 'test-key',
          client: fake,
        ),
      ),
      toolDispatcher: dispatcher,
      stopPolicy: const StopPolicy(
        id: 'e2e',
        maxTurns: 8,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      ),
      steeringQueue: queue,
      onEvent: (event) {
        events.add(event);
        onEvent?.call(event);
      },
      clock: fakeClock,
    );
    return (runner, fake, dispatcher, registry);
  }

  ScriptedOutcome turn(String content, {String finish = 'tool_calls'}) =>
      ScriptedOutcome(
        response: LlmResponse(content: content, finishReason: finish),
      );

  test('five-turn mission: tool calls via the real registry, mid-mission '
      'steering injection, natural completion', () async {
    final events = <EngineEvent>[];
    final planner = MarkerPlanner();
    // Steering is enqueued by an event handler the moment turn 2 completes
    // (spec 002 FR-003: "queued at mission end" keeps the loop going).
    MissionRunner? runnerRef;
    final wired = await makeRunner(
      outcomes: [
        turn('I need the brief first.\n@tool:fs.read {"path": "brief.txt"}'),
        turn('Now the notes.\n@tool:fs.read {"path": "notes.txt"}'),
        turn('Numbers.\n@tool:calc.add {"a": 2, "b": 3}'),
        turn(
          'Steering acknowledged — assembling the answer.',
          finish: 'length',
        ),
        turn(
          'FINAL: brief + notes read, sum=5, steering applied.',
          finish: 'stop',
        ),
      ],
      events: events,
      queue: SteeringQueue(id: 'q-e2e', pending: const [], processedCount: 0),
      onEvent: (event) {
        if (event is TurnCompleted &&
            events.whereType<TurnCompleted>().length == 2) {
          runnerRef?.enqueue(
            SteeringMessage(
              id: 'steer-1',
              content: 'STEERING: include the token totals in the answer.',
              injectedAt: fakeNow,
            ),
          );
        }
      },
    );
    final runner = wired.$1;
    final fake = wired.$2;
    final dispatcher = wired.$3;
    final registry = wired.$4;
    runnerRef = runner;

    final result = await runner.run(
      missionId: 'm-e2e',
      planner: planner,
      messages: const [
        ChatMessage(role: 'system', content: 'You are a mission agent.'),
        ChatMessage(role: 'user', content: 'Run the onboarding mission.'),
      ],
    );

    // Terminal outcome.
    expect(result.status, MissionStatus.completed);
    expect(result.turnsUsed, 5);
    expect(
      result.summary,
      'FINAL: brief + notes read, sum=5, steering applied.',
    );
    expect(fake.generateCalls, 5);

    // The full lifecycle, in order: MissionStarted, 5 turns (each
    // TurnStarted..TurnCompleted with tool pairs inside), MissionCompleted.
    expect(events.first, isA<MissionStarted>());
    expect(events.last, isA<MissionCompleted>());
    expect(events.whereType<TurnStarted>(), hasLength(5));
    expect(events.whereType<TurnCompleted>(), hasLength(5));
    final completed = events.last as MissionCompleted;
    expect(completed.status, 'completed');

    // Tool calls went through the REAL registry: two fs.read + one
    // calc.add, all ok, dispatched in order.
    expect(dispatcher.dispatched, ['fs.read', 'fs.read', 'calc.add']);
    expect(
      events.whereType<ToolCallStarted>().map((e) => e.toolName).toList(),
      ['fs.read', 'fs.read', 'calc.add'],
    );
    expect(
      events.whereType<ToolCallCompleted>().map((e) => e.toolName).toList(),
      ['fs.read', 'fs.read', 'calc.add'],
    );
    expect(
      events.whereType<ToolCallCompleted>().map((e) => e.ok),
      everyElement(isTrue),
    );

    // The steering injection happened between turn 2 and turn 3: drained
    // FIFO at the start of turn 3, announced with SteeringInjected, and
    // joined the transcript as a user message BEFORE the turn-3 assistant
    // reply.
    final steeringEvents = events.whereType<SteeringInjected>().toList();
    expect(steeringEvents, hasLength(1));
    expect(
      steeringEvents.single.content,
      'STEERING: include the token totals in the answer.',
    );
    final roles = result.transcript.map((m) => m.role).toList();
    expect(roles, [
      'system', 'user', // seed
      'assistant', 'tool', // turn 1: fs.read brief
      'assistant', 'tool', // turn 2: fs.read notes
      'user', 'assistant', 'tool', // turn 3: steering drain + calc.add
      'assistant', // turn 4: no call, non-stop finish -> loop continues
      'assistant', // turn 5: natural stop
    ]);
    expect(
      result.transcript[6].content,
      'STEERING: include the token totals in the answer.',
    );

    // THE E2E POINT: the wire requests the fake LLM actually received
    // carry the accumulated context — the system prompt from the seed
    // message, the tool results from the registry-resolved tools, and the
    // steering text. Nothing was lost between the loop and the provider.
    expect(fake.requests, hasLength(5));
    expect(fake.requests[0].systemPrompt, 'You are a mission agent.');
    final requestJson = [
      for (final request in fake.requests)
        [for (final message in request.messages) message.toJson()],
    ];
    expect(jsonEncode(requestJson[1]), contains('MISSION BRIEF v7'));
    expect(
      jsonEncode(requestJson[2]),
      contains('NOTES: ratchet the coverage gate'),
    );
    expect(
      jsonEncode(requestJson[2]),
      contains('STEERING: include the token totals'),
    );
    // The calc.add result ('5') from the registry-resolved tool reached the
    // FINAL wire request (turn 5's context) — 'sum=5' is turn 5's own
    // completion, which no request can contain.
    expect(jsonEncode(requestJson[4]), contains('"content":"5"'));

    await registry.dispose();
  });

  test(
    'mission stops at maxTurns with the typed maxTurnsExceeded outcome',
    () async {
      final events = <EngineEvent>[];
      final (runner, fake, dispatcher, _) = await makeRunner(
        // Exactly 3 scripted outcomes: a 4th turn would throw inside
        // FakeLlmClient (no scripted outcome left) and surface as
        // providerFailed — so status maxTurnsExceeded proves the CAP stopped
        // the loop, not the script running dry.
        outcomes: [
          turn('More.\n@tool:calc.add {"a": 1, "b": 2}'),
          turn('More.\n@tool:calc.add {"a": 1, "b": 2}'),
          turn('More.\n@tool:calc.add {"a": 1, "b": 2}'),
        ],
        events: events,
        queue: SteeringQueue(id: 'q-cap', pending: const [], processedCount: 0),
        loop: const EngineLoop(
          id: 'loop-cap',
          sessionId: 's-cap',
          maxTurns: 3,
          wallClockTimeoutMs: 60000,
          repetitionThreshold: 5,
        ),
      );

      final result = await runner.run(
        missionId: 'm-cap',
        planner: MarkerPlanner(),
        messages: const [ChatMessage(role: 'user', content: 'Keep going.')],
      );

      expect(result.status, MissionStatus.maxTurnsExceeded);
      expect(result.turnsUsed, 3);
      // Non-natural ends carry no summary.
      expect(result.summary, isNull);
      expect(fake.generateCalls, 3);
      expect(dispatcher.dispatched, hasLength(3));
      expect(events.whereType<TurnStarted>(), hasLength(3));
      final completed = events.last as MissionCompleted;
      expect(completed.status, 'maxTurnsExceeded');
      expect(completed.summary, isNull);
    },
  );
}
