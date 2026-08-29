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
}
