// Spec 038 (issue arrrrny/zuraffa_agent#8) — UiTreePayload serialization
// and diffing semantics, test-first via /speckit.tdd.run.
//
// Behaviors (specs/038-ui-tree-payload/tdd/test-list.md):
// - U1/U2/U6 (FR-001/002): toJson shape, fromJson validation (5 error
//   shapes), lossless round-trip.
// - U3/U4/U5 (FR-003): path-keyed structural diff + pinning flags.
// - U9/U10 (FR-004): UiTreeDiff value-object semantics.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';

/// Shared 3-level fixture: depth 3, nodeCount 5 (Column -> [Text, Row ->
/// [Text, Text]]).
Map<String, dynamic> _tree() => {
      'type': 'Column',
      'props': {'padding': 8},
      'children': [
        {'type': 'Text', 'props': {'value': 'hi'}},
        {
          'type': 'Row',
          'children': [
            {'type': 'Text'},
            {'type': 'Text'},
          ]
        },
      ]
    };

void main() {
  group('spec 038 — UiTreePayload serialization (FR-001/002)', () {
    test('U1: toJson produces exactly the four contract keys', () {
      final p = UiTreePayload(
        vocabularyId: 'shadcn-ui@1.0.0',
        schemaVersion: '1.0.0',
        tree: _tree(),
      );
      final json = p.toJson();
      expect(json.keys.toSet(), {
        'mimeType',
        'vocabularyId',
        'schemaVersion',
        'tree',
      });
      expect(json['mimeType'], 'ui/tree+json');
      expect(json['vocabularyId'], 'shadcn-ui@1.0.0');
      expect(json['schemaVersion'], '1.0.0');
      expect(json['tree'], isA<Map<String, dynamic>>());
    });

    test('U6: 3-level tree round-trips losslessly', () {
      final original = UiTreePayload(
        vocabularyId: 'shadcn-ui@1.0.0',
        schemaVersion: '1.0.0',
        tree: _tree(),
      );
      final parsed = UiTreePayload.fromJson(original.toJson());
      expect(parsed, equals(original));
      expect(parsed.depth, original.depth);
      expect(parsed.nodeCount, original.nodeCount);
      // Idempotent second round.
      expect(parsed.toJson(), equals(original.toJson()));
    });

    test('U2: missing mimeType throws ArgumentError naming mimeType', () {
      final json = {
        'vocabularyId': 'shadcn-ui@1.0.0',
        'schemaVersion': '1.0.0',
        'tree': _tree(),
      };
      expect(
        () => UiTreePayload.fromJson(json),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('mimeType'))),
      );
    });

    test('U2: wrong mimeType throws ArgumentError naming mimeType', () {
      final json = {
        'mimeType': 'application/json',
        'vocabularyId': 'shadcn-ui@1.0.0',
        'schemaVersion': '1.0.0',
        'tree': _tree(),
      };
      expect(
        () => UiTreePayload.fromJson(json),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('mimeType'))),
      );
    });

    test('U2: empty vocabularyId / schemaVersion / non-map tree throw', () {
      final base = {
        'mimeType': 'ui/tree+json',
        'vocabularyId': 'shadcn-ui@1.0.0',
        'schemaVersion': '1.0.0',
        'tree': _tree(),
      };
      expect(
        () => UiTreePayload.fromJson({...base, 'vocabularyId': ''}),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('vocabularyId'))),
      );
      expect(
        () => UiTreePayload.fromJson({...base, 'schemaVersion': ''}),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('schemaVersion'))),
      );
      expect(
        () => UiTreePayload.fromJson({...base, 'tree': <String, dynamic>{}}
          ..['tree'] = ['not', 'a', 'map']),
        throwsA(isA<ArgumentError>()
            .having((e) => e.name, 'name', contains('tree'))),
      );
    });
  });
}
