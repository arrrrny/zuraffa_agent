// Tests for the PlaybookLoader (spec 104 — playbook-as-spec behavior
// steering, R5#4): document -> typed playbook with actionable diagnostics.
//
// Fakes: none — the loader is a pure transform from document text to value
// object (the yaml package does the parsing; no I/O).

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/playbook/playbook.dart';
import 'package:zuraffa_agent/src/domain/entities/playbook/playbook_loader.dart';

/// The Germany reference document — mirrors the reference playbook in
/// playbook_test.dart: every section populated, one duplicate steering
/// entry, one entry with an explicit id, one without.
const _deYaml = '''
id: pb-de-001
name: germany
description: Country playbook for Germany market missions
domain: country
country: DE
steering:
  - id: s1
    content: Greet in German.
  - content: Cite GDPR for personal data.
  - content: Greet in German.
toolGating:
  mode: allowlist
  allowed: [search, fetch]
response:
  language: de
  maxChars: 2000
''';

const _deJson = <String, dynamic>{
  'id': 'pb-de-001',
  'name': 'germany',
  'description': 'Country playbook for Germany market missions',
  'domain': 'country',
  'country': 'DE',
  'steering': [
    {'id': 's1', 'content': 'Greet in German.'},
    {'content': 'Cite GDPR for personal data.'},
    {'content': 'Greet in German.'},
  ],
  'toolGating': {
    'mode': 'allowlist',
    'allowed': ['search', 'fetch'],
  },
  'response': {'language': 'de', 'maxChars': 2000},
};

Playbook _expectedGermany() => Playbook(
      id: 'pb-de-001',
      name: 'germany',
      description: 'Country playbook for Germany market missions',
      domain: 'country',
      country: 'DE',
      steering: [
        const PlaybookSteering(id: 's1', content: 'Greet in German.'),
        const PlaybookSteering(content: 'Cite GDPR for personal data.'),
        const PlaybookSteering(content: 'Greet in German.'),
      ],
      toolGate: const PlaybookToolGate(
        mode: PlaybookGateMode.allowlist,
        allowed: ['search', 'fetch'],
      ),
      response: const PlaybookResponse(language: 'de', maxChars: 2000),
    );

void main() {
  final loader = PlaybookLoader();

  group('spec 104 — PlaybookLoader', () {
    group('loads', () {
      test('U10: full YAML document preserves every field', () {
        final pb = loader.loadYaml(_deYaml);
        expect(pb, equals(_expectedGermany()));
      });

      test('U11: JSON path equals YAML path; unknown keys ignored', () {
        expect(loader.loadJson(_deJson), equals(_expectedGermany()));

        // Forward compatibility: a newer document may carry keys an older
        // engine does not know — the unknown key is ignored, not an error.
        final withUnknown = Map<String, dynamic>.of(_deJson)
          ..['futureSection'] = {'anything': true};
        expect(loader.loadJson(withUnknown), equals(_expectedGermany()));
      });

      test('U16: identity-only document loads as the no-op playbook', () {
        final pb = loader.loadYaml('''
id: pb-min
name: minimal
description: Just identity.
''');
        expect(pb.id, 'pb-min');
        expect(pb.name, 'minimal');
        expect(pb.description, 'Just identity.');
        expect(pb.steering, isEmpty);
        expect(pb.toolGate.mode, PlaybookGateMode.off);
        expect(pb.toolGate.allowed, isEmpty);
        expect(pb.toolGate.blocked, isEmpty);
        expect(pb.response.language, isNull);
        expect(pb.response.maxChars, isNull);
      });
    });

    group('rejects', () {
      Matcher rejectsNamed(String field) => throwsA(isA<ArgumentError>()
          .having((e) => e.name, 'name', contains(field)));

      test('U12: non-map top level and bad identity are rejected', () {
        // Top level must be a mapping — a list or a scalar is not a
        // playbook document.
        expect(() => loader.loadYaml('- one\n- two\n'),
            rejectsNamed('document'));
        expect(() => loader.loadYaml('42'), rejectsNamed('document'));

        // Identity keys are required strings.
        expect(
          () => loader.loadJson({
            'name': 'germany',
            'description': 'desc',
          }),
          rejectsNamed('id'),
        );
        expect(
          () => loader.loadJson({
            'id': 123,
            'name': 'germany',
            'description': 'desc',
          }),
          rejectsNamed('id'),
        );
        expect(
          () => loader.loadJson({
            'id': 'pb-1',
            'description': 'desc',
          }),
          rejectsNamed('name'),
        );
        expect(
          () => loader.loadJson({
            'id': 'pb-1',
            'name': 'germany',
          }),
          rejectsNamed('description'),
        );
      });

      test('U13: malformed steering section is rejected', () {
        Map<String, dynamic> withSteering(Object? steering) => {
              'id': 'pb-1',
              'name': 'germany',
              'description': 'desc',
              'steering': steering,
            };

        // steering must be a list of entries...
        expect(() => loader.loadJson(withSteering('not-a-list')),
            rejectsNamed('steering'));
        // ...and each entry must be a mapping...
        expect(() => loader.loadJson(withSteering([42])),
            rejectsNamed('steering'));
        // ...carrying non-empty content (missing key)...
        expect(() => loader.loadJson(withSteering([
              {'id': 's1'},
            ])),
            rejectsNamed('content'));
        // ...and non-empty content (blank value) — pinned end-to-end through
        // the aggregate constructor (cycle 2's U4 red proved that rule).
        expect(() => loader.loadJson(withSteering([
              {'content': ''},
            ])),
            rejectsNamed('content'));
      });

      test('U14: malformed toolGating section is rejected', () {
        Map<String, dynamic> withGate(Map<String, dynamic> gate) => {
              'id': 'pb-1',
              'name': 'germany',
              'description': 'desc',
              'toolGating': gate,
            };

        // mode vocabulary is closed: off | allowlist | blocklist.
        expect(
          () => loader.loadJson(withGate({
            'mode': 'whitelist',
            'allowed': ['search'],
          })),
          rejectsNamed('mode'),
        );
        // gate lists must be lists...
        expect(
          () => loader.loadJson(withGate({
            'mode': 'allowlist',
            'allowed': 'oops',
          })),
          rejectsNamed('allowed'),
        );
        // ...of tool names (strings)...
        expect(
          () => loader.loadJson(withGate({
            'mode': 'allowlist',
            'allowed': [42],
          })),
          rejectsNamed('allowed'),
        );
        // ...never blank (blank tool id through the document path — the
        // aggregate's U5 rule pinned end-to-end).
        expect(
          () => loader.loadJson(withGate({
            'mode': 'blocklist',
            'blocked': [''],
          })),
          rejectsNamed('blocked'),
        );
      });

      test('U15: malformed response section is rejected', () {
        Map<String, dynamic> withResponse(Map<String, dynamic> response) => {
              'id': 'pb-1',
              'name': 'germany',
              'description': 'desc',
              'response': response,
            };

        // maxChars must be an integer...
        expect(
          () => loader.loadJson(withResponse({'maxChars': '2000'})),
          rejectsNamed('maxChars'),
        );
        // ...and a positive one (aggregate's U8 rule, end-to-end).
        expect(
          () => loader.loadJson(withResponse({'maxChars': 0})),
          rejectsNamed('maxChars'),
        );
        // language must be a non-empty string...
        expect(
          () => loader.loadJson(withResponse({'language': 123})),
          rejectsNamed('language'),
        );
        // ...when present (blank through the document path — U8's rule).
        expect(
          () => loader.loadJson(withResponse({'language': ''})),
          rejectsNamed('language'),
        );
      });

      test('U17: inconsistent gate documents are rejected at load', () {
        Map<String, dynamic> withGate(Map<String, dynamic> gate) => {
              'id': 'pb-1',
              'name': 'germany',
              'description': 'desc',
              'toolGating': gate,
            };

        // A non-empty irrelevant list is loader drift — the value-object's
        // U6 rule, surfaced through the loader (end-to-end observable).
        expect(
          () => loader.loadJson(withGate({
            'mode': 'allowlist',
            'allowed': ['search'],
            'blocked': ['shell'],
          })),
          rejectsNamed('blocked'),
        );
        expect(
          () => loader.loadJson(withGate({
            'mode': 'off',
            'allowed': ['search'],
          })),
          rejectsNamed('allowed'),
        );
      });
    });
  });
}
