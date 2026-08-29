// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// Spec 104 — playbook-as-spec behavior steering (R5#4).
//
// The engine application of a loaded playbook: the runtime converts the
// declarative document into the engine's EXISTING behavior surfaces —
// steering entries become SteeringMessages seeded into the SteeringQueue
// (FR-003), the tool gate wraps the mission's ToolDispatcher (FR-004), and
// the response constraints shape the final response (FR-005). It composes
// spec 033's queue and spec 003/047's dispatcher; it introduces no new
// loop, event, or persistence format (FR-007), and it never branches on a
// specific playbook's identity or content (FR-006) — a different loaded
// document is the ONLY way behavior changes.
//
// Not exported from lib/zuraffa_agent.dart — consistent with the sibling
// engine runtimes (mission_runner.dart, sub_agent_dispatch.dart).
//
// Pattern: plain Dart, no @Zorphy annotation (constitution IX exemption —
// same documented precedent as the Playbook value object).

import '../domain/entities/playbook/playbook.dart';
import '../domain/entities/steering_message/steering_message.dart';
import '../domain/entities/steering_queue/steering_queue.dart';
import '../domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'tool_dispatcher.dart';

/// Applies a loaded [Playbook] as the active steering/behavior context.
///
/// Construct one per mission with the mission's playbook and an injectable
/// clock (house pattern, spec 069). The three application surfaces:
///
/// - [steeringMessages] / [seedSteering] — the playbook's steering entries
///   (plus the response-language directive) as [SteeringMessage]s, seeded
///   FIFO into the mission's [SteeringQueue] and drained by the engine
///   loop (observable as `SteeringInjected` events).
/// - [gateDispatcher] — wraps the mission's [ToolDispatcher] with the
///   playbook's tool gate; refusals follow the spec 070
///   `AllowlistToolDispatcher` contract (`tool not allowed: <name>`).
/// - [constrainResponse] — applies the mechanical response constraints to
///   the final response text.
class PlaybookRuntime {
  PlaybookRuntime({
    required Playbook playbook,
    DateTime Function()? clock,
  })  : _playbook = playbook,
        _clock = clock ?? DateTime.now;

  final Playbook _playbook;
  final DateTime Function() _clock;

  /// The playbook's steering entries as [SteeringMessage]s, in document
  /// order, plus — when the playbook declares a response [PlaybookResponse.language]
  /// — one pinned directive message appended after them:
  /// `[playbook:<id>] Respond in language '<language>'.`
  ///
  /// Message ids are deterministic and playbook-attributable: an entry's
  /// own `id` when present, otherwise `pb-<playbookId>-steer-<index>`; the
  /// directive is `pb-<playbookId>-lang`. Timestamps come from the
  /// runtime's clock.
  List<SteeringMessage> steeringMessages() {
    final messages = <SteeringMessage>[];
    for (var i = 0; i < _playbook.steering.length; i++) {
      final entry = _playbook.steering[i];
      messages.add(SteeringMessage(
        id: entry.id ?? 'pb-${_playbook.id}-steer-$i',
        content: entry.content,
        injectedAt: _clock(),
      ));
    }
    final language = _playbook.response.language;
    if (language != null) {
      messages.add(SteeringMessage(
        id: 'pb-${_playbook.id}-lang',
        content: "[playbook:${_playbook.id}] Respond in language '$language'.",
        injectedAt: _clock(),
      ));
    }
    return messages;
  }

  /// Seeds [queue] with [steeringMessages]: returns a NEW snapshot with the
  /// playbook's messages enqueued FIFO (appended after anything already
  /// pending), the input queue never mutated (FR-007). A playbook with no
  /// steering returns the queue unchanged.
  SteeringQueue seedSteering(SteeringQueue queue) {
    var seeded = queue;
    for (final message in steeringMessages()) {
      seeded = seeded.enqueue(message);
    }
    return seeded;
  }

  /// Wraps [inner] with the playbook's tool gate (FR-004): the returned
  /// dispatcher refuses calls the playbook's gate blocks — the inner
  /// dispatcher never sees them — and delegates everything else unchanged.
  /// An `off` (or absent) gate wraps without refusing anything.
  ToolDispatcher gateDispatcher(ToolDispatcher inner) =>
      PlaybookToolGateDispatcher(
        inner: inner,
        gate: _playbook.toolGate,
      );

  /// Applies the playbook's mechanical response constraint to a final
  /// response (FR-005): with `maxChars` set, a response longer than the cap
  /// becomes exactly its first `maxChars` characters followed by a
  /// truncation marker naming the playbook —
  /// `[playbook:<id>] response truncated at <maxChars> characters`. A
  /// response at or under the cap (or a playbook with no constraint)
  /// passes through unchanged.
  String constrainResponse(String content) {
    final maxChars = _playbook.response.maxChars;
    if (maxChars == null || content.length <= maxChars) {
      return content;
    }
    return '${content.substring(0, maxChars)}'
        '[playbook:${_playbook.id}] response truncated at $maxChars characters';
  }
}

/// Decorator enforcing a playbook's [PlaybookToolGate] at the dispatch
/// boundary (FR-004).
///
/// Mirrors the spec 070 `AllowlistToolDispatcher` contract exactly: a
/// refused call yields a typed failure (`success: false`, `result: ''`,
/// `error: 'tool not allowed: <name>'`, no artifact refs) so the mission
/// records the refusal as a failed tool call and continues — the wrapped
/// dispatcher is never invoked for it. `allowlist` admits only `allowed`
/// (an empty list locks down every tool); `blocklist` refuses exactly
/// `blocked`; `off` refuses nothing.
class PlaybookToolGateDispatcher implements ToolDispatcher {
  PlaybookToolGateDispatcher({
    required ToolDispatcher inner,
    required PlaybookToolGate gate,
  })  : _inner = inner,
        _gate = gate;

  final ToolDispatcher _inner;
  final PlaybookToolGate _gate;

  bool _refuses(String toolName) {
    switch (_gate.mode) {
      case PlaybookGateMode.off:
        return false;
      case PlaybookGateMode.allowlist:
        return !_gate.allowed.contains(toolName);
      case PlaybookGateMode.blocklist:
        return _gate.blocked.contains(toolName);
    }
  }

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    if (_refuses(toolName)) {
      return ToolDispatchResult(
        success: false,
        result: '',
        error: 'tool not allowed: $toolName',
        artifactRefs: const [],
      );
    }
    return _inner.dispatch(
      toolName: toolName,
      arguments: arguments,
      isInternalMission: isInternalMission,
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
      _inner.validateSchema(schema: schema, arguments: arguments);

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) =>
      _inner.checkRiskTier(riskTier: riskTier, isInternalMission: isInternalMission);
}
