// Tests for the Playbook schema value object (spec 104 — playbook-as-spec
// behavior steering, R5#4).
//
// Fakes: none needed — a pure value object. Clock not involved here (the
// runtime tests inject one).

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/playbook/playbook.dart';

/// The reference playbook used by the construction/equality pins: every
/// field carries a distinct, recognizable value so a lost or swapped field
/// fails its assertion by name.
Playbook _referencePlaybook() => Playbook(
      id: 'pb-de-001',
      name: 'germany',
      description: 'Country playbook for Germany market missions',
      domain: 'country',
      country: 'DE',
      steering: [
        PlaybookSteering(id: 's1', content: 'Greet in German.'),
        PlaybookSteering(content: 'Cite GDPR for personal data.'),
        // Deliberate duplicate: steering is an ordered narrative, not a set.
        PlaybookSteering(content: 'Greet in German.'),
      ],
      toolGate: PlaybookToolGate(
        mode: PlaybookGateMode.allowlist,
        allowed: ['search', 'fetch'],
        blocked: [],
      ),
      response: PlaybookResponse(language: 'de', maxChars: 2000),
    );

void main() {
  group('spec 104 — Playbook schema', () {
    test('U1: construction preserves every field', () {
      final pb = _referencePlaybook();

      expect(pb.id, 'pb-de-001');
      expect(pb.name, 'germany');
      expect(pb.description, 'Country playbook for Germany market missions');
      expect(pb.domain, 'country');
      expect(pb.country, 'DE');

      expect(pb.steering, hasLength(3));
      expect(pb.steering[0].id, 's1');
      expect(pb.steering[0].content, 'Greet in German.');
      expect(pb.steering[1].id, isNull);
      expect(pb.steering[1].content, 'Cite GDPR for personal data.');
      // Duplicate preserved verbatim, in order.
      expect(pb.steering[2].content, 'Greet in German.');

      expect(pb.toolGate.mode, PlaybookGateMode.allowlist);
      expect(pb.toolGate.allowed, ['search', 'fetch']);
      expect(pb.toolGate.blocked, isEmpty);

      expect(pb.response.language, 'de');
      expect(pb.response.maxChars, 2000);
    });

    test('U2: value equality spans every field', () {
      final a = _referencePlaybook();
      final b = _referencePlaybook();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(identical(a, a), isTrue); // identity short-circuit

      Playbook mutate(Playbook Function(Playbook) change) => change(a);

      expect(mutate((p) => Playbook(
            id: 'pb-jp-001',
            name: p.name,
            description: p.description,
            domain: p.domain,
            country: p.country,
            steering: p.steering,
            toolGate: p.toolGate,
            response: p.response,
          )), isNot(equals(b)));

      expect(mutate((p) => Playbook(
            id: p.id,
            name: p.name,
            description: p.description,
            domain: p.domain,
            country: p.country,
            steering: p.steering.sublist(0, 2),
            toolGate: p.toolGate,
            response: p.response,
          )), isNot(equals(b)));

      expect(mutate((p) => Playbook(
            id: p.id,
            name: p.name,
            description: p.description,
            domain: p.domain,
            country: p.country,
            steering: p.steering,
            toolGate: PlaybookToolGate(
              mode: PlaybookGateMode.blocklist,
              allowed: p.toolGate.allowed,
              blocked: ['shell'],
            ),
            response: p.response,
          )), isNot(equals(b)));

      expect(mutate((p) => Playbook(
            id: p.id,
            name: p.name,
            description: p.description,
            domain: p.domain,
            country: p.country,
            steering: p.steering,
            toolGate: PlaybookToolGate(
              mode: PlaybookGateMode.allowlist,
              allowed: ['search'],
              blocked: p.toolGate.blocked,
            ),
            response: p.response,
          )), isNot(equals(b)));

      expect(mutate((p) => Playbook(
            id: p.id,
            name: p.name,
            description: p.description,
            domain: p.domain,
            country: p.country,
            steering: p.steering,
            toolGate: p.toolGate,
            response: PlaybookResponse(language: 'jp', maxChars: 2000),
          )), isNot(equals(b)));
    });

    test('U9: toString names the type and identity', () {
      final text = _referencePlaybook().toString();
      expect(text, contains('Playbook'));
      expect(text, contains('pb-de-001'));
      expect(text, contains('germany'));
      // No steering-content dump: toString stays log-friendly.
      expect(text, isNot(contains('Greet in German.')));
    });
  });
}
