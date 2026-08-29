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
            // Legal gate variant: blocklist with its own blocked list (the
            // reference is an allowlist gate — mode + lists differ).
            toolGate: const PlaybookToolGate(
              mode: PlaybookGateMode.blocklist,
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

  group('spec 104 — Playbook schema validation', () {
    test('U3: blank identity fields are rejected', () {
      Matcher rejectsNamed(String field) => throwsA(isA<ArgumentError>()
          .having((e) => e.name, 'name', contains(field)));

      expect(
        () => Playbook(
          id: '',
          name: 'germany',
          description: 'desc',
          steering: _steering,
          toolGate: _gate,
          response: _response,
        ),
        rejectsNamed('id'),
      );
      expect(
        () => Playbook(
          id: 'pb-1',
          name: '',
          description: 'desc',
          steering: _steering,
          toolGate: _gate,
          response: _response,
        ),
        rejectsNamed('name'),
      );
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: '',
          steering: _steering,
          toolGate: _gate,
          response: _response,
        ),
        rejectsNamed('description'),
      );
      // Optional metadata: null is fine (U1 pins that), empty is not.
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: 'desc',
          domain: '',
          steering: _steering,
          toolGate: _gate,
          response: _response,
        ),
        rejectsNamed('domain'),
      );
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: 'desc',
          country: '',
          steering: _steering,
          toolGate: _gate,
          response: _response,
        ),
        rejectsNamed('country'),
      );
    });

    test('U4: blank steering content is rejected', () {
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: 'desc',
          steering: [PlaybookSteering(content: '')],
          toolGate: _gate,
          response: _response,
        ),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('content'))),
      );
    });

    test('U5: blank tool ids in a gate list are rejected', () {
      Playbook withGate(PlaybookToolGate gate) => Playbook(
            id: 'pb-1',
            name: 'germany',
            description: 'desc',
            steering: _steering,
            toolGate: gate,
            response: _response,
          );

      expect(
        () => withGate(const PlaybookToolGate(
          mode: PlaybookGateMode.allowlist,
          allowed: ['search', ''],
          blocked: [],
        )),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('allowed'))),
      );
      expect(
        () => withGate(const PlaybookToolGate(
          mode: PlaybookGateMode.blocklist,
          allowed: [],
          blocked: ['shell', ''],
        )),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('blocked'))),
      );
    });

    test('U6: non-empty irrelevant gate lists are rejected', () {
      Playbook withGate(PlaybookToolGate gate) => Playbook(
            id: 'pb-1',
            name: 'germany',
            description: 'desc',
            steering: _steering,
            toolGate: gate,
            response: _response,
          );

      // blocked has no effect on an allowlist gate — loader drift.
      expect(
        () => withGate(const PlaybookToolGate(
          mode: PlaybookGateMode.allowlist,
          allowed: ['search'],
          blocked: ['shell'],
        )),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('blocked'))),
      );
      // allowed has no effect on a blocklist gate.
      expect(
        () => withGate(const PlaybookToolGate(
          mode: PlaybookGateMode.blocklist,
          allowed: ['search'],
          blocked: ['shell'],
        )),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('allowed'))),
      );
      // an off gate carries no lists at all.
      expect(
        () => withGate(const PlaybookToolGate(
          mode: PlaybookGateMode.off,
          allowed: ['search'],
          blocked: [],
        )),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('allowed'))),
      );
      expect(
        () => withGate(const PlaybookToolGate(
          mode: PlaybookGateMode.off,
          allowed: [],
          blocked: ['shell'],
        )),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('blocked'))),
      );
    });

    test('U7: legal gate boundaries construct (lock-down, empty, off)', () {
      // Empty allowlist locks down every tool — valid and meaningful.
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: 'desc',
          steering: _steering,
          toolGate: const PlaybookToolGate(
              mode: PlaybookGateMode.allowlist, allowed: [], blocked: []),
          response: _response,
        ),
        returnsNormally,
      );
      // Empty blocklist refuses nothing — valid.
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: 'desc',
          steering: _steering,
          toolGate: const PlaybookToolGate(
              mode: PlaybookGateMode.blocklist, allowed: [], blocked: []),
          response: _response,
        ),
        returnsNormally,
      );
      // Off with both lists empty — the default no-op gate.
      expect(
        () => Playbook(
          id: 'pb-1',
          name: 'germany',
          description: 'desc',
          steering: _steering,
          toolGate:
              const PlaybookToolGate(mode: PlaybookGateMode.off),
          response: _response,
        ),
        returnsNormally,
      );
    });

    test('U8: response constraint boundaries (maxChars 0/1, blank language)',
        () {
      Playbook withResponse(PlaybookResponse response) => Playbook(
            id: 'pb-1',
            name: 'germany',
            description: 'desc',
            steering: _steering,
            toolGate: _gate,
            response: response,
          );

      expect(() => withResponse(const PlaybookResponse(maxChars: 0)),
          throwsA(isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('maxChars'))));
      expect(() => withResponse(const PlaybookResponse(maxChars: -5)),
          throwsA(isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('maxChars'))));
      // maxChars == 1 is the smallest legal cap.
      expect(() => withResponse(const PlaybookResponse(maxChars: 1)),
          returnsNormally);
      expect(() => withResponse(const PlaybookResponse(language: '')),
          throwsA(isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('language'))));
      // Both null: no constraints — the default response.
      expect(() => withResponse(const PlaybookResponse()), returnsNormally);
    });
  });
}

const _steering = [PlaybookSteering(content: 'Focus on the market.')];
const _gate = PlaybookToolGate(mode: PlaybookGateMode.off);
const _response = PlaybookResponse();
