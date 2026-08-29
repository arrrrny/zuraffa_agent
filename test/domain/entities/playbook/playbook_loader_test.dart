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
  });
}
