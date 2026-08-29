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
import 'package:zuraffa_agent/src/engine/playbook_runtime.dart';

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
  });
}
