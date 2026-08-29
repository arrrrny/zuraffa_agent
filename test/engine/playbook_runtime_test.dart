// Tests for the PlaybookRuntime (spec 104 — playbook-as-spec behavior
// steering, R5#4).
//
// The unit groups (U18–U30) pin the runtime's surfaces one behavior at a
// time; the R5#4 acceptance group (A3–A6) composes them through real
// MissionRunner missions (it lands with the outer-loop close — see
// tdd/cycle-log.md).
//
// Determinism: an injected fixed clock (spec 069 exemplar pattern) so every
// timestamp is deterministic.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/playbook/playbook.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_message/steering_message.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_queue/steering_queue.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/playbook/playbook_loader.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/playbook_runtime.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

/// Records every dispatch; returns scripted results by tool name (spec 069
/// exemplar — the gate asserts against what the INNER dispatcher saw).
class FakeToolDispatcher implements ToolDispatcher {
  FakeToolDispatcher([this.resultsByTool = const {}]);

  final Map<String, ToolDispatchResult> resultsByTool;
  final List<({String toolName, Map<String, dynamic> arguments, bool isInternalMission})>
      calls = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    calls.add((
      toolName: toolName,
      arguments: arguments,
      isInternalMission: isInternalMission,
    ));
    return resultsByTool[toolName] ??
        ToolDispatchResult(
          success: true,
          result: 'ok:$toolName',
          error: '',
          artifactRefs: const [],
        );
  }

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
  }) =>
      const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

/// Counts validateSchema/checkRiskTier delegations for U27 (the gate must
/// pass these through to the wrapped dispatcher untouched).
class DelegationSpy implements ToolDispatcher {
  final dispatches = <String>[];
  int schemaCalls = 0;
  int riskCalls = 0;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    dispatches.add(toolName);
    return ToolDispatchResult(
      success: true,
      result: 'ok:$toolName',
      error: '',
      artifactRefs: const [],
    );
  }

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
  }) {
    schemaCalls++;
    return const [];
  }

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) {
    riskCalls++;
    return true;
  }
}

/// LLM client returning a FIFO script of completions (spec 069 exemplar).
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

/// Plans tool calls by 1-based completion index (069 exemplar).
class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.planByCall);

  final Map<int, List<ToolCall>> planByCall;
  int _count = 0;

  @override
  Future<List<ToolCall>> plan(
      ChatCompletion completion, List<ChatMessage> transcript) async {
    _count++;
    return planByCall[_count] ?? const [];
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

const loop10 = EngineLoop(
  id: 'loop-104',
  sessionId: 's104',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);
/// The Germany country playbook document (allowlist gate).
const _deYaml = '''
id: pb-de-001
name: germany
description: Country playbook for Germany market missions
domain: country
country: DE
steering:
  - content: Greet in German.
  - content: Cite GDPR for personal data.
toolGating:
  mode: allowlist
  allowed: [search, fetch]
response:
  language: de
  maxChars: 120
''';

/// The Japan country playbook document (blocklist gate — search refused,
/// shell admitted: the opposite of Germany on the same tools).
const _jpYaml = '''
id: pb-jp-001
name: japan
description: Country playbook for Japan market missions
domain: country
country: JP
steering:
  - content: Greet in Japanese.
toolGating:
  mode: blocklist
  blocked: [search]
response:
  language: jp
  maxChars: 80
''';

/// A third, novel playbook document — nothing in the engine knows about
/// France; loading it proves adding a playbook requires only the document
/// (FR-006).
const _frYaml = '''
id: pb-fr-001
name: france
description: Country playbook for France market missions
steering:
  - content: Answer in French market idiom.
toolGating:
  mode: allowlist
  allowed: [translate]
response:
  maxChars: 200
''';

/// What one run under a playbook observes: the engine event stream, the
/// mission result, what the wrapped dispatcher actually saw, and the
/// response after the playbook's constraints.
class RunObservation {
  RunObservation({
    required this.events,
    required this.result,
    required this.dispatcher,
    required this.constrainedResponse,
  });

  final List<EngineEvent> events;
  final MissionResult result;
  final FakeToolDispatcher dispatcher;
  final String constrainedResponse;

  List<SteeringInjected> get steeringEvents => [
        for (final e in events)
          if (e is SteeringInjected) e,
      ];

  List<ToolCallCompleted> get toolEvents => [
        for (final e in events)
          if (e is ToolCallCompleted) e,
      ];
}

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  group('spec 104 — PlaybookRuntime steering', () {
    test('U18: entries become steering messages in document order', () {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        steering: [
          const PlaybookSteering(id: 's1', content: 'First.'),
          const PlaybookSteering(content: 'Second.'),
        ],
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);

      final messages = runtime.steeringMessages();

      expect(messages, hasLength(2));
      // Document order preserved; content verbatim.
      expect(messages[0].content, 'First.');
      expect(messages[1].content, 'Second.');
      // An entry's own id is respected; a missing one is derived from the
      // playbook id + entry index (playbook-attributable).
      expect(messages[0].id, 's1');
      expect(messages[1].id, 'pb-de-001-steer-1');
      // Timestamps come from the runtime's clock.
      expect(messages[0].injectedAt, DateTime.utc(2026, 1, 1));
      expect(messages[1].injectedAt, DateTime.utc(2026, 1, 1));
    });

    test('U19: language constraint appends the pinned directive message', () {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        steering: const [PlaybookSteering(content: 'First.')],
        response: const PlaybookResponse(language: 'de'),
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);

      final messages = runtime.steeringMessages();

      // Exactly one directive, appended AFTER the entries.
      expect(messages, hasLength(2));
      final directive = messages.last;
      expect(directive.id, 'pb-de-001-lang');
      expect(directive.content, "[playbook:de-001] Respond in language 'de'.");
      expect(directive.injectedAt, DateTime.utc(2026, 1, 1));
    });

    test('U20: empty steering yields no messages', () {
      final playbook = Playbook(id: 'de-001', name: 'x', description: 'd');
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);

      expect(runtime.steeringMessages(), isEmpty);
    });

    test('U21: seedSteering returns a new FIFO-seeded queue', () {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        steering: const [
          PlaybookSteering(content: 'First.'),
          PlaybookSteering(content: 'Second.'),
        ],
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final preexisting = SteeringMessage(
        id: 'user-1',
        content: 'queued by the user before the playbook',
        injectedAt: DateTime.utc(2025, 12, 31),
      );
      final input = SteeringQueue(
        id: 'q-104',
        pending: [preexisting],
        processedCount: 3,
      );

      final seeded = runtime.seedSteering(input);

      // FIFO: playbook messages are appended AFTER the pre-existing pending
      // message — document order preserved head -> tail.
      expect(
        seeded.pending.map((m) => m.content),
        [
          'queued by the user before the playbook',
          'First.',
          'Second.',
        ],
      );
      // The input queue is unmutated (value semantics — FR-007).
      expect(input.pending, hasLength(1));
      expect(input.pending.single, preexisting);
      expect(input.processedCount, 3);
      // The seeded snapshot preserves the drained count and stamps the
      // newest injection.
      expect(seeded.processedCount, 3);
      expect(seeded.lastInjectedAt, DateTime.utc(2026, 1, 1));
    });

    test('U22: seeding nothing is a no-op', () {
      final playbook = Playbook(id: 'de-001', name: 'x', description: 'd');
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final input = SteeringQueue(
        id: 'q-104',
        pending: const [],
        processedCount: 7,
      );

      final seeded = runtime.seedSteering(input);

      expect(seeded, equals(input));
      expect(seeded.pending, isEmpty);
      expect(seeded.processedCount, 7);
    });
  });

  group('spec 104 — PlaybookRuntime tool gate', () {
    test('U23: off gate delegates everything', () async {
      final playbook = Playbook(id: 'de-001', name: 'x', description: 'd');
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final inner = FakeToolDispatcher();
      final gated = runtime.gateDispatcher(inner);

      final result = await gated.dispatch(
        toolName: 'shell',
        arguments: {'cmd': 'ls'},
        isInternalMission: true,
      );

      // The call reached the inner dispatcher untouched — toolName,
      // arguments, and mission context all preserved.
      expect(result.success, isTrue);
      expect(inner.calls, hasLength(1));
      expect(inner.calls.single.toolName, 'shell');
      expect(inner.calls.single.arguments, {'cmd': 'ls'});
      expect(inner.calls.single.isInternalMission, isTrue);
    });

    test('U24: allowlist gate refuses unlisted tools', () async {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        toolGate: const PlaybookToolGate(
          mode: PlaybookGateMode.allowlist,
          allowed: ['search', 'fetch'],
        ),
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final inner = FakeToolDispatcher();
      final gated = runtime.gateDispatcher(inner);

      final refused = await gated.dispatch(
        toolName: 'shell',
        arguments: {'cmd': 'ls'},
        isInternalMission: false,
      );

      // Typed refusal — the spec 070 AllowlistToolDispatcher contract.
      expect(refused.success, isFalse);
      expect(refused.result, isEmpty);
      expect(refused.error, 'tool not allowed: shell');
      expect(refused.artifactRefs, isEmpty);
      // The inner dispatcher NEVER saw the refused call.
      expect(inner.calls, isEmpty);

      // An allowlisted tool delegates with its arguments preserved.
      final allowed = await gated.dispatch(
        toolName: 'search',
        arguments: {'q': 'markets'},
        isInternalMission: false,
      );
      expect(allowed.success, isTrue);
      expect(inner.calls, hasLength(1));
      expect(inner.calls.single.toolName, 'search');
      expect(inner.calls.single.arguments, {'q': 'markets'});
    });

    test('U25: empty allowlist locks down all tools', () async {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        toolGate: const PlaybookToolGate(mode: PlaybookGateMode.allowlist),
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final inner = FakeToolDispatcher();
      final gated = runtime.gateDispatcher(inner);

      final refused = await gated.dispatch(
        toolName: 'search',
        arguments: {},
        isInternalMission: false,
      );

      expect(refused.success, isFalse);
      expect(refused.error, 'tool not allowed: search');
      expect(inner.calls, isEmpty);
    });

    test('U26: blocklist gate refuses only listed tools', () async {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        toolGate: const PlaybookToolGate(
          mode: PlaybookGateMode.blocklist,
          blocked: ['shell'],
        ),
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final inner = FakeToolDispatcher();
      final gated = runtime.gateDispatcher(inner);

      final refused = await gated.dispatch(
        toolName: 'shell',
        arguments: {},
        isInternalMission: false,
      );
      expect(refused.success, isFalse);
      expect(refused.error, 'tool not allowed: shell');
      expect(inner.calls, isEmpty);

      // Everything NOT on the blocklist delegates.
      final allowed = await gated.dispatch(
        toolName: 'search',
        arguments: {},
        isInternalMission: false,
      );
      expect(allowed.success, isTrue);
      expect(inner.calls.map((c) => c.toolName), ['search']);

      // An empty blocked list refuses nothing.
      final openPlaybook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        toolGate: const PlaybookToolGate(mode: PlaybookGateMode.blocklist),
      );
      final openGate = PlaybookRuntime(playbook: openPlaybook, clock: fakeClock)
          .gateDispatcher(inner);
      final passed = await openGate.dispatch(
        toolName: 'shell',
        arguments: {},
        isInternalMission: false,
      );
      expect(passed.success, isTrue);
      expect(inner.calls.map((c) => c.toolName), ['search', 'shell']);
    });

    test('U27: batch dispatch gates per call; schema/risk delegate', () async {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        toolGate: const PlaybookToolGate(
          mode: PlaybookGateMode.allowlist,
          allowed: ['search'],
        ),
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
      final spy = DelegationSpy();
      final gated = runtime.gateDispatcher(spy);

      final results = await gated.dispatchBatch(
        calls: [
          const ToolCall(
              toolName: 'search',
              arguments: {},
              executionMode: 'sequential'),
          const ToolCall(
              toolName: 'shell',
              arguments: {},
              executionMode: 'sequential'),
          const ToolCall(
              toolName: 'search',
              arguments: {},
              executionMode: 'sequential'),
        ],
        isInternalMission: false,
      );

      // Each call is gated independently: search passes, shell is refused,
      // search passes again.
      expect(results.map((r) => r.success), [true, false, true]);
      expect(results[1].error, 'tool not allowed: shell');
      // The spy saw exactly the admitted calls, in order.
      expect(spy.dispatches, ['search', 'search']);

      // Schema validation and risk-tier checks delegate to the wrapped
      // dispatcher untouched.
      expect(
        gated.validateSchema(schema: {}, arguments: {}),
        isEmpty,
      );
      expect(spy.schemaCalls, 1);
      expect(
        gated.checkRiskTier(riskTier: 'safe', isInternalMission: false),
        isTrue,
      );
      expect(spy.riskCalls, 1);
    });
  });

  group('spec 104 — PlaybookRuntime response', () {
    test('U28: maxChars truncation boundaries', () {
      PlaybookRuntime runtimeWith(int? maxChars) => PlaybookRuntime(
            playbook: Playbook(
              id: 'de-001',
              name: 'x',
              description: 'd',
              response: PlaybookResponse(maxChars: maxChars),
            ),
            clock: fakeClock,
          );
      const marker = '[playbook:de-001] response truncated at 5 characters';

      // No cap: unchanged.
      expect(runtimeWith(null).constrainResponse('x' * 500), 'x' * 500);
      // At the limit: unchanged (boundary — exactly maxChars passes).
      expect(runtimeWith(5).constrainResponse('abcde'), 'abcde');
      // One over the limit: truncated (boundary — the other side).
      expect(runtimeWith(5).constrainResponse('abcdef'), 'abcde$marker');
      // Far over: exactly the first maxChars characters plus the marker.
      expect(runtimeWith(5).constrainResponse('x' * 500), 'xxxxx$marker');
    });

    test('U29: no constraints means no change', () {
      final runtime = PlaybookRuntime(
        playbook: Playbook(id: 'de-001', name: 'x', description: 'd'),
        clock: fakeClock,
      );

      expect(runtime.constrainResponse('short'), 'short');
      expect(runtime.constrainResponse('x' * 10000), 'x' * 10000);
    });

    test('U30: steering timestamps come from the injected clock', () {
      final playbook = Playbook(
        id: 'de-001',
        name: 'x',
        description: 'd',
        steering: const [PlaybookSteering(content: 'First.')],
      );
      final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);

      final first = runtime.steeringMessages().single.injectedAt;
      expect(first, DateTime.utc(2026, 1, 1));

      // The clock is READ at generation time — advancing it advances the
      // stamp (not captured once at construction).
      fakeNow = DateTime.utc(2026, 1, 2);
      final second = runtime.steeringMessages().single.injectedAt;
      expect(second, DateTime.utc(2026, 1, 2));
      expect(second.isAfter(first), isTrue);
    });
  });
  // The single composition under test — the IDENTICAL code path every
  // playbook runs through (FR-006: no branch on playbook identity or
  // content anywhere). [withToolCalls] plans the same tool calls for
  // whichever playbook is loaded.
  Future<RunObservation> runUnderPlaybook(
    String yamlDocument, {
    List<ToolCall> plannedCalls = const [],
  }) async {
    final playbook = PlaybookLoader().loadYaml(yamlDocument);
    final runtime = PlaybookRuntime(playbook: playbook, clock: fakeClock);
    final events = <EngineEvent>[];
    final inner = FakeToolDispatcher();
    final queue = runtime.seedSteering(SteeringQueue(
      id: 'q-104',
      pending: const [],
      processedCount: 0,
    ));
    final runner = MissionRunner(
      executor: EngineLoopExecutor(
        loop10,
        ScriptedLlmClient(completions: [
          completionOf('need tools', finish: 'tool_calls'),
          completionOf('x' * 500),
        ]),
      ),
      toolDispatcher: runtime.gateDispatcher(inner),
      stopPolicy: const StopPolicy(
        id: 'test-104',
        maxTurns: 100,
        wallClockTimeout: Duration.zero,
        repetitionThreshold: 5,
      ),
      steeringQueue: queue,
      onEvent: events.add,
      clock: fakeClock,
    );
    final result = await runner.run(
      missionId: 'm-104',
      messages: const [ChatMessage(role: 'user', content: 'go')],
      planner: ScriptedPlanner({1: plannedCalls}),
    );
    return RunObservation(
      events: events,
      result: result,
      dispatcher: inner,
      constrainedResponse: runtime.constrainResponse(result.summary ?? ''),
    );
  }

  group('spec 104 — R5#4 acceptance', () {
    test('A3: playbook steering drains through the mission loop', () async {
      final run = await runUnderPlaybook(_deYaml);

      // One SteeringInjected event per steering entry, in document order...
      final contents = [for (final e in run.steeringEvents) e.content];
      expect(contents, [
        'Greet in German.',
        'Cite GDPR for personal data.',
        // ...plus the response-language directive (FR-005, pinned by U19).
        "[playbook:pb-de-001] Respond in language 'de'.",
      ]);
      // ...and each entry's content is in the transcript as a user message.
      final userContents = [
        for (final m in run.result.transcript)
          if (m.role == 'user') m.content,
      ];
      expect(userContents, containsAll(contents));
    });

    test('A4: playbook tool gating refuses the blocked tool in a mission',
        () async {
      final run = await runUnderPlaybook(
        _deYaml,
        plannedCalls: [
          ToolCall(
              toolName: 'shell',
              arguments: {'cmd': 'ls'},
              executionMode: 'sequential'),
          ToolCall(
              toolName: 'search',
              arguments: {'q': 'markets'},
              executionMode: 'sequential'),
        ],
      );

      // The allowlist gate refuses shell with the typed failure...
      final shellEvent = run.toolEvents
          .firstWhere((e) => e.toolName == 'shell');
      expect(shellEvent.ok, isFalse);
      // ...the refusal lands in the transcript as the tool message...
      expect(
        run.result.transcript
            .where((m) => m.role == 'tool')
            .map((m) => m.content)
            .contains('tool not allowed: shell'),
        isTrue,
      );
      // ...the inner dispatcher NEVER saw it...
      expect(
        run.dispatcher.calls.map((c) => c.toolName),
        isNot(contains('shell')),
      );
      // ...while the allowlisted search dispatched with its arguments.
      expect(
        run.dispatcher.calls.map((c) => c.toolName),
        contains('search'),
      );
      final searchCall = run.dispatcher.calls
          .firstWhere((c) => c.toolName == 'search');
      expect(searchCall.arguments, {'q': 'markets'});
      final searchEvent = run.toolEvents
          .firstWhere((e) => e.toolName == 'search');
      expect(searchEvent.ok, isTrue);
    });

    test('A5: response constraints shape the mission response', () async {
      final run = await runUnderPlaybook(_deYaml);

      // The language directive is injected as playbook steering...
      expect(
        run.steeringEvents.map((e) => e.content),
        contains("[playbook:pb-de-001] Respond in language 'de'."),
      );
      // ...and the 500-char response is capped at maxChars: 120 — exactly
      // the first 120 characters plus the truncation marker.
      expect(run.result.summary, hasLength(500));
      const deMarker =
          '[playbook:pb-de-001] response truncated at 120 characters';
      expect(run.constrainedResponse, 'x' * 120 + deMarker);
    });

    test('A6: three documents, one code path — behavior follows the document (R5#4)',
        () async {
      const planned = <ToolCall>[
        ToolCall(
            toolName: 'shell',
            arguments: {'cmd': 'ls'},
            executionMode: 'sequential'),
        ToolCall(
            toolName: 'search',
            arguments: {'q': 'markets'},
            executionMode: 'sequential'),
      ];
      // The SAME composition, three different documents.
      final de = await runUnderPlaybook(_deYaml, plannedCalls: planned);
      final jp = await runUnderPlaybook(_jpYaml, plannedCalls: planned);
      final fr = await runUnderPlaybook(_frYaml, plannedCalls: planned);

      // Germany: allowlist [search, fetch] — search dispatched, shell
      // refused; 2 entries + de directive injected; capped at 120.
      expect(de.dispatcher.calls.map((c) => c.toolName), ['search']);
      expect(de.steeringEvents, hasLength(3));
      expect(
          de.constrainedResponse,
          'x' * 120 +
              '[playbook:pb-de-001] response truncated at 120 characters');

      // Japan: blocklist [search] — search REFUSED (the opposite of
      // Germany on the same code), shell dispatched; 1 entry + jp
      // directive; capped at 80.
      expect(jp.dispatcher.calls.map((c) => c.toolName), ['shell']);
      expect(jp.steeringEvents, hasLength(2));
      expect(
          jp.constrainedResponse,
          'x' * 80 +
              '[playbook:pb-jp-001] response truncated at 80 characters');

      // France (novel document): allowlist [translate] — both planned
      // tools refused; no language directive (none declared); capped at 200.
      expect(fr.dispatcher.calls, isEmpty);
      expect(fr.steeringEvents, hasLength(1));
      expect(
          fr.constrainedResponse,
          'x' * 200 +
              '[playbook:pb-fr-001] response truncated at 200 characters');

      // The observable behavior differs per document on every surface —
      // steering, gating, and response constraints — through one code path.
      expect(de.steeringEvents.first.content, 'Greet in German.');
      expect(jp.steeringEvents.first.content, 'Greet in Japanese.');
      expect(fr.steeringEvents.first.content, 'Answer in French market idiom.');
    });
  });
}
