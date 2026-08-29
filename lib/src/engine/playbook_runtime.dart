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

  SteeringQueue seedSteering(SteeringQueue queue) {
    throw UnimplementedError();
  }

  ToolDispatcher gateDispatcher(ToolDispatcher inner) {
    throw UnimplementedError();
  }

  String constrainResponse(String content) {
    throw UnimplementedError();
  }
}
