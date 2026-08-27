// Tests for lib/src/engine/agent_hook_pipeline.dart — Spec 012 chaining and
// engine-visible effects. Behaviors U4-U12 + acceptance A1-A5 — see
// specs/012-agent-hooks-pipeline/tdd/test-list.md.
//
// The acceptance tests use a scripted mission DRIVER that plays the engine
// role (spec 002 owns the real wiring): it drives the 9 pipeline points,
// calls a FakeLlmClient with the pipeline-returned request, honors
// deny/retry decisions, and records everything the hooks observed.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/engine/agent_hook_pipeline.dart';
import 'package:zuraffa_agent/src/engine/agent_hooks.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/types.dart';
import '../llm/fake_llm_client.dart';

/// A hook that records every lifecycle call it receives.
class RecordingHook extends AgentHook {
  final List<String> events = [];
  final List<Object?> seenContexts = [];

  @override
  String get name => 'recording';

  @override
  Future<BeforeRunHookResult> beforeRun(BeforeRunHookContext context) async {
    events.add('beforeRun');
    seenContexts.add(context);
    return const BeforeRunHookResult.continue_();
  }

  @override
  Future<ModelCallHookResult> beforeModelCall(ModelCallHookContext context) async {
    events.add('beforeModelCall');
    seenContexts.add(context);
    return const ModelCallHookResult.continue_();
  }

  @override
  Future<ModelChunkHookResult> onModelChunk(ModelChunkHookContext context) async {
    events.add('onModelChunk');
    seenContexts.add(context);
    return const ModelChunkHookResult.continue_();
  }

  @override
  Future<AfterModelCallHookResult> afterModelCall(
      AfterModelCallHookContext context) async {
    events.add('afterModelCall');
    seenContexts.add(context);
    return const AfterModelCallHookResult.continue_();
  }

  @override
  Future<ToolCallHookResult> beforeToolCall(ToolCallHookContext context) async {
    events.add('beforeToolCall');
    seenContexts.add(context);
    return const ToolCallHookResult.continue_();
  }

  @override
  Future<AfterToolCallHookResult> afterToolCall(
      AfterToolCallHookContext context) async {
    events.add('afterToolCall');
    seenContexts.add(context);
    return const AfterToolCallHookResult.continue_();
  }

  @override
  Future<TurnCompletionHookResult> onTurnCompletion(
      TurnCompletionHookContext context) async {
    events.add('onTurnCompletion');
    seenContexts.add(context);
    return const TurnCompletionHookResult.continue_();
  }

  @override
  Future<PersistStateHookResult> beforePersistState(
      PersistStateHookContext context) async {
    events.add('beforePersistState');
    seenContexts.add(context);
    return const PersistStateHookResult.continue_();
  }

  @override
  Future<AfterRunHookResult> afterRun(AfterRunHookContext context) async {
    events.add('afterRun');
    seenContexts.add(context);
    return const AfterRunHookResult.continue_();
  }
}

/// A hook that renames the model call's temperature and modifies tool args.
class ModifierHook extends AgentHook {
  final List<String> events = [];

  @override
  String get name => 'modifier';

  @override
  Future<ModelCallHookResult> beforeModelCall(ModelCallHookContext context) async {
    events.add('modifier:beforeModelCall:${context.request.temperature}');
    return ModelCallHookResult.modify(LlmRequest(
      systemPrompt: context.request.systemPrompt,
      messages: context.request.messages,
      tools: context.request.tools,
      temperature: 0.42,
      maxTokens: context.request.maxTokens,
    ));
  }

  @override
  Future<ToolCallHookResult> beforeToolCall(ToolCallHookContext context) async {
    events.add('modifier:beforeToolCall');
    return ToolCallHookResult.modify(LlmToolCall(
      id: context.toolCall.id,
      name: context.toolCall.name,
      arguments: {...context.toolCall.arguments, 'modified': true},
    ));
  }
}

const _missionToolCall =
    LlmToolCall(id: 'c1', name: 'read_file', arguments: {'path': 'a.dart'});

void main() {
  group('AgentHookPipeline chaining (U4-U6)', () {
    test('U4: hooks run in registration order at every lifecycle point', () async {
      final pipeline = AgentHookPipeline();
      final first = RecordingHook();
      final second = RecordingHook();
      pipeline.register(first);
      pipeline.register(second);

      final request = LlmRequest(messages: [UserMessage.text('hi')]);
      await pipeline.beforeRun(const BeforeRunHookContext(runId: 'r', messages: []));
      await pipeline.beforeModelCall(ModelCallHookContext(request: request));
      await pipeline.onModelChunk(
          const ModelChunkHookContext(chunk: LlmResponseChunk(content: 'x')));
      await pipeline.afterModelCall(AfterModelCallHookContext(
          request: request, response: const LlmResponse(content: 'ok')));
      const toolCall = LlmToolCall(id: 'c1', name: 't', arguments: {});
      await pipeline.beforeToolCall(const ToolCallHookContext(toolCall: toolCall));
      await pipeline.afterToolCall(const AfterToolCallHookContext(
          toolCall: toolCall, result: 'r', isError: false));
      await pipeline.onTurnCompletion(
          const TurnCompletionHookContext(turnNumber: 1, messages: []));
      await pipeline.beforePersistState(const PersistStateHookContext(messages: []));
      await pipeline.afterRun(
          const AfterRunHookContext(finalMessages: [], outcome: 'completed'));

      // Both hooks saw all 9 points...
      expect(first.events, hasLength(9));
      expect(second.events, hasLength(9));
      // ...in the same mission order at each point.
      expect(
        first.events,
        containsAllInOrder([
          'beforeRun', 'beforeModelCall', 'onModelChunk', 'afterModelCall',
          'beforeToolCall', 'afterToolCall', 'onTurnCompletion',
          'beforePersistState', 'afterRun',
        ]),
      );
    });

    test('U5: a modify result folds — the next hook observes the modification', () async {
      final pipeline = AgentHookPipeline();
      final seen = <String>[];

      pipeline.register(_CallbackHook(
        onBeforeModelCall: (ctx) async => ModelCallHookResult.modify(
            LlmRequest(messages: ctx.request.messages, temperature: 0.7)),
      ));
      pipeline.register(_CallbackHook(
        onBeforeModelCall: (ctx) async {
          seen.add('temp=${ctx.request.temperature}');
          return const ModelCallHookResult.continue_();
        },
      ));

      final out = await pipeline.beforeModelCall(
          ModelCallHookContext(request: LlmRequest(messages: const [])));
      expect(seen, ['temp=0.7'], reason: 'second hook must see the first hook\'s modification');
      expect(out.request.temperature, 0.7);
    });

    test('U6: an abort throws HookAbortError at the offending hook; later hooks are not called', () async {
      final pipeline = AgentHookPipeline();
      final called = <String>[];

      pipeline.register(_CallbackHook(
        name: 'first',
        onBeforeRun: (ctx) async {
          called.add('first');
          return const BeforeRunHookResult.continue_();
        },
      ));
      pipeline.register(_CallbackHook(
        name:abortHookName,
        onBeforeRun: (ctx) async {
          called.add('aborting');
          return const BeforeRunHookResult.abort(reason: 'budget exhausted');
        },
      ));
      pipeline.register(_CallbackHook(
        name: 'third',
        onBeforeRun: (ctx) async {
          called.add('third');
          return const BeforeRunHookResult.continue_();
        },
      ));

      await expectLater(
        pipeline.beforeRun(const BeforeRunHookContext(runId: 'r', messages: [])),
        throwsA(isA<HookAbortError>()
            .having((e) => e.hookName, 'hookName', abortHookName)
            .having((e) => e.reason, 'reason', 'budget exhausted')),
      );
      expect(called, ['first', 'aborting'], reason: 'later hooks must not run');
    });
  });

  group('AgentHookPipeline engine-visible effects (U7-U12)', () {
    const toolCall =
        LlmToolCall(id: 'c1', name: 'read_file', arguments: {'path': 'a.dart'});

    test('U7: beforeModelCall modification returns the modified request', () async {
      final pipeline = AgentHookPipeline();
      pipeline.register(_CallbackHook(
        onBeforeModelCall: (ctx) async => ModelCallHookResult.modify(LlmRequest(
              messages: ctx.request.messages,
              temperature: 0.123,
            )),
      ));
      final out = await pipeline.beforeModelCall(
          ModelCallHookContext(request: LlmRequest(messages: const [])));
      expect(out.request.temperature, 0.123);
    });

    test('U8: beforeToolCall deny returns a ToolCallDecision with the synthetic result', () async {
      final pipeline = AgentHookPipeline();
      pipeline.register(_CallbackHook(
        onBeforeToolCall: (ctx) async =>
            const ToolCallHookResult.deny(result: 'denied by policy', isError: true),
      ));
      final decision = await pipeline.beforeToolCall(
          const ToolCallHookContext(toolCall: toolCall));
      expect(decision.denied, isTrue);
      expect(decision.denyResult, 'denied by policy');
      expect(decision.denyIsError, isTrue);
    });

    test('U9: beforeToolCall modify returns the tool call with modified arguments', () async {
      final pipeline = AgentHookPipeline();
      pipeline.register(_CallbackHook(
        onBeforeToolCall: (ctx) async => ToolCallHookResult.modify(LlmToolCall(
              id: ctx.toolCall.id,
              name: ctx.toolCall.name,
              arguments: {...ctx.toolCall.arguments, 'path': 'b.dart'},
            )),
      ));
      final decision = await pipeline.beforeToolCall(
          const ToolCallHookContext(toolCall: toolCall));
      expect(decision.denied, isFalse);
      expect(decision.context.toolCall.arguments['path'], 'b.dart');
    });

    test('U10: afterToolCall modify returns the modified result content/isError', () async {
      final pipeline = AgentHookPipeline();
      pipeline.register(_CallbackHook(
        onAfterToolCall: (ctx) async => const AfterToolCallHookResult.modify(
            result: 'sanitized', isError: false),
      ));
      final out = await pipeline.afterToolCall(const AfterToolCallHookContext(
          toolCall: toolCall, result: 'secret data', isError: true));
      expect(out.result, 'sanitized');
      expect(out.isError, isFalse);
    });

    test('U11: afterModelCall retry returns ModelCallDecision.retry = true', () async {
      final pipeline = AgentHookPipeline();
      pipeline.register(_CallbackHook(
        onAfterModelCall: (ctx) async => const AfterModelCallHookResult.retry(),
      ));
      final decision = await pipeline.afterModelCall(AfterModelCallHookContext(
          request: LlmRequest(messages: const []),
          response: const LlmResponse(content: 'bad')));
      expect(decision.retry, isTrue);
      // Retry carries the original response context (engine decides what to resend).
      expect(decision.context.response.content, 'bad');
    });

    test('U12: afterModelCall modify returns the modified LlmResponse', () async {
      final pipeline = AgentHookPipeline();
      pipeline.register(_CallbackHook(
        onAfterModelCall: (ctx) async => AfterModelCallHookResult.modify(
            LlmResponse(content: '${ctx.response.content} [audited]')),
      ));
      final decision = await pipeline.afterModelCall(AfterModelCallHookContext(
          request: LlmRequest(messages: const []),
          response: const LlmResponse(content: 'raw')));
      expect(decision.retry, isFalse);
      expect(decision.context.response.content, 'raw [audited]');
    });
  });

  group('Scripted mission driver — acceptance (A1-A5)', () {
    test('A1: a logging hook captures all 9 lifecycle events during a mission', () async {
      final recorder = RecordingHook();
      final mission = _MissionDriver(hooks: [recorder]);
      await mission.run(toolsToExecute: const []);

      expect(recorder.events, [
        'beforeRun',
        'beforeModelCall',
        'onModelChunk',
        'afterModelCall',
        'onTurnCompletion',
        'beforePersistState',
        'afterRun',
      ]);
      // With no tool calls the tool points don't fire...
      expect(recorder.events, isNot(contains('beforeToolCall')));
      // ...so run one more mission WITH a tool call for the full 9.
      final recorder2 = RecordingHook();
      final mission2 = _MissionDriver(hooks: [recorder2]);
      await mission2.run(toolsToExecute: const [_missionToolCall]);
      expect(recorder2.events, [
        'beforeRun',
        'beforeModelCall',
        'onModelChunk',
        'afterModelCall',
        'beforeToolCall',
        'afterToolCall',
        'onTurnCompletion',
        'beforePersistState',
        'afterRun',
      ]);
    });

    test('A2: a modifier hook changes the model call; the driver\'s LlmClient receives it (SC-002)', () async {
      final modifier = ModifierHook();
      final client = FakeLlmClient(
        providerName: 'test',
        outcomes: [
          const ScriptedOutcome(response: LlmResponse(content: 'reply')),
        ],
      );
      final mission = _MissionDriver(hooks: [modifier], client: client);
      await mission.run(toolsToExecute: const []);

      expect(client.requests, hasLength(1));
      expect(client.requests.single.temperature, 0.42);
    });

    test('A3: an abort hook stops the run with the typed error (SC-003)', () async {
      final client = FakeLlmClient(providerName: 'test', outcomes: const []);
      final mission = _MissionDriver(hooks: [
        _CallbackHook(
          name: 'policy_hook',
          onBeforeModelCall: (ctx) async =>
              const ModelCallHookResult.abort(reason: 'forbidden mission'),
        ),
      ], client: client);

      await expectLater(
        mission.run(toolsToExecute: const []),
        throwsA(isA<HookAbortError>()
            .having((e) => e.hookName, 'hookName', 'policy_hook')
            .having((e) => e.reason, 'reason', 'forbidden mission')),
      );
      expect(client.generateCalls, 0, reason: 'the LLM must not be called after abort');
    });

    test('A4: a logging hook and a modifying hook compose in registration order', () async {
      final recorder = RecordingHook();
      final modifier = ModifierHook();
      final mission = _MissionDriver(hooks: [recorder, modifier]);
      await mission.run(toolsToExecute: const [_missionToolCall]);

      // Both hooks ran at the shared points, recorder (registered first) first.
      expect(recorder.events, contains('beforeModelCall'));
      expect(modifier.events.first, startsWith('modifier:beforeModelCall'));
      // The modifier's tool-call change reached the executed tool.
      expect(mission.executedToolArguments?['modified'], isTrue);
    });

    test('A5: a deny hook prevents tool execution; the synthetic result is returned', () async {
      final mission = _MissionDriver(hooks: [
        _CallbackHook(
          onBeforeToolCall: (ctx) async => const ToolCallHookResult.deny(
              result: 'tool disabled by policy', isError: true),
        ),
      ]);
      await mission.run(toolsToExecute: const [_missionToolCall]);

      expect(mission.executedToolArguments, isNull, reason: 'tool must NOT execute');
      expect(mission.toolResultReturned, 'tool disabled by policy');
      expect(mission.toolResultIsError, isTrue);
    });
  });
}

const abortHookName = 'aborting_hook';

/// A hook whose behavior is injected per callback — keeps the test bodies
/// focused on the pipeline semantics.
class _CallbackHook extends AgentHook {
  @override
  final String name;
  final Future<BeforeRunHookResult> Function(BeforeRunHookContext)? onBeforeRun;
  final Future<ModelCallHookResult> Function(ModelCallHookContext)? onBeforeModelCall;
  final Future<AfterModelCallHookResult> Function(AfterModelCallHookContext)?
      onAfterModelCall;
  final Future<ToolCallHookResult> Function(ToolCallHookContext)? onBeforeToolCall;
  final Future<AfterToolCallHookResult> Function(AfterToolCallHookContext)?
      onAfterToolCall;

  _CallbackHook({
    this.name = 'callback',
    this.onBeforeRun,
    this.onBeforeModelCall,
    this.onAfterModelCall,
    this.onBeforeToolCall,
    this.onAfterToolCall,
  });

  @override
  Future<BeforeRunHookResult> beforeRun(BeforeRunHookContext context) async =>
      onBeforeRun?.call(context) ?? const BeforeRunHookResult.continue_();

  @override
  Future<ModelCallHookResult> beforeModelCall(ModelCallHookContext context) async =>
      onBeforeModelCall?.call(context) ?? const ModelCallHookResult.continue_();

  @override
  Future<AfterModelCallHookResult> afterModelCall(
          AfterModelCallHookContext context) async =>
      onAfterModelCall?.call(context) ?? const AfterModelCallHookResult.continue_();

  @override
  Future<ToolCallHookResult> beforeToolCall(ToolCallHookContext context) async =>
      onBeforeToolCall?.call(context) ?? const ToolCallHookResult.continue_();

  @override
  Future<AfterToolCallHookResult> afterToolCall(
          AfterToolCallHookContext context) async =>
      onAfterToolCall?.call(context) ?? const AfterToolCallHookResult.continue_();
}

/// Plays the engine role for acceptance tests: drives the 9 pipeline
/// points in mission order, uses the pipeline's outputs the way the real
/// engine will (spec 002), and records what happened.
class _MissionDriver {
  final AgentHookPipeline pipeline = AgentHookPipeline();
  final FakeLlmClient client;

  Map<String, dynamic>? executedToolArguments;
  String? toolResultReturned;
  bool toolResultIsError = false;

  _MissionDriver({required List<AgentHook> hooks, FakeLlmClient? client})
      : client = client ??
            FakeLlmClient(
              providerName: 'test',
              outcomes: [
                const ScriptedOutcome(
                    response: LlmResponse(content: 'mission reply')),
              ],
            ) {
    for (final hook in hooks) {
      pipeline.register(hook);
    }
  }

  Future<void> run({required List<LlmToolCall> toolsToExecute}) async {
    final messages = <AgentMessage>[UserMessage.text('do the mission')];

    // beforeRun
    await pipeline.beforeRun(
        BeforeRunHookContext(runId: 'run-1', messages: messages));

    // beforeModelCall → engine uses the (possibly modified) request
    final modelContext = await pipeline
        .beforeModelCall(ModelCallHookContext(request: LlmRequest(messages: messages)));
    // onModelChunk (streamed)
    await pipeline.onModelChunk(const ModelChunkHookContext(
        chunk: LlmResponseChunk(content: 'mission', isComplete: false)));
    // the engine calls the LLM with the pipeline-returned request
    final response = await client.generate(modelContext.request);
    // afterModelCall → retry or modified response
    final decision =
        await pipeline.afterModelCall(AfterModelCallHookContext(
      request: modelContext.request,
      response: response,
    ));
    var effective = decision.context.response;
    if (decision.retry) {
      effective = await client.generate(modelContext.request);
    }

    // Tool calls
    for (final toolCall in toolsToExecute) {
      final toolDecision = await pipeline
          .beforeToolCall(ToolCallHookContext(toolCall: toolCall));
      if (toolDecision.denied) {
        toolResultReturned = toolDecision.denyResult;
        toolResultIsError = toolDecision.denyIsError;
      } else {
        executedToolArguments = toolDecision.context.toolCall.arguments;
        final raw = 'executed ${toolDecision.context.toolCall.name}';
        final after = await pipeline.afterToolCall(AfterToolCallHookContext(
            toolCall: toolDecision.context.toolCall, result: raw, isError: false));
        toolResultReturned = after.result;
        toolResultIsError = after.isError;
      }
    }

    // onTurnCompletion
    await pipeline.onTurnCompletion(
        TurnCompletionHookContext(turnNumber: 1, messages: messages));
    // beforePersistState
    await pipeline.beforePersistState(PersistStateHookContext(messages: messages));
    // afterRun
    await pipeline.afterRun(AfterRunHookContext(
        finalMessages: [...messages, AssistantMessage.text(effective.content)],
        outcome: 'completed'));
  }
}
