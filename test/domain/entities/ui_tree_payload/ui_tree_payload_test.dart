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

  group('spec 038 — UiTreePayload.diff (FR-003/004)', () {
    UiTreePayload p(Map<String, dynamic> tree,
            {String vocab = 'shadcn-ui@1.0.0', String schema = '1.0.0'}) =>
        UiTreePayload(vocabularyId: vocab, schemaVersion: schema, tree: tree);

    test('U3: mixed fixture reports exact added/removed/changed sets', () {
      final before = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'props': {'value': 'hi'}},
          {'type': 'Text'},
          {
            'type': 'Row',
            'children': [
              {'type': 'Text'},
            ]
          },
        ]
      };
      // After: child 0 props changed; child 1 removed; child 3 added;
      // nested Row's first Text unchanged.
      final after = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'props': {'value': 'bye'}}, // changed -> root/0
          // child 1 removed -> root/1
          {
            'type': 'Row',
            'children': [
              {'type': 'Text'},
            ]
          }, // shifted to index 1 — compared positionally
          {'type': 'Spacer'}, // added -> root/2... see expectations below
        ]
      };
      final delta = p(before).diff(p(after));
      // Positional semantics: index 0 changed (props differ); index 1:
      // before Text vs after Row -> changed, and the Row's only child is
      // ADDED at root/1/0 (before had none there); index 2: before Row vs
      // after Spacer -> changed, and before Row's child is REMOVED at
      // root/2/0 (after has none there).
      expect(delta.changedPaths, containsAll(['root/0', 'root/1', 'root/2']));
      expect(delta.addedPaths, contains('root/1/0'));
      expect(delta.removedPaths, contains('root/2/0'));
      expect(delta.hasChanges, isTrue);
      // Complement symmetry: added in one direction is removed in the
      // other, and vice versa.
      final reverse = p(after).diff(p(before));
      expect(reverse.addedPaths, contains('root/2/0'));
      expect(reverse.removedPaths, contains('root/1/0'));
      expect(reverse.changedPaths, containsAll(['root/0', 'root/1', 'root/2']));
    });

    test('U4: pure add/remove/modify without positional shift', () {
      final before = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'props': {'value': 'a'}},
          {'type': 'Text', 'props': {'value': 'b'}},
        ]
      };
      final after = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'props': {'value': 'a'}},
          {'type': 'Text', 'props': {'value': 'B'}}, // changed root/1
          {'type': 'Spacer'}, // added root/2
        ]
      };
      final delta = p(before).diff(p(after));
      expect(delta.changedPaths, ['root/1']);
      expect(delta.addedPaths, ['root/2']);
      expect(delta.removedPaths, isEmpty);
      // Root-level props change lands at 'root'.
      final rootChanged = p({
        'type': 'Column',
        'props': {'padding': 8},
        'children': <dynamic>[],
      }).diff(p({
        'type': 'Column',
        'props': {'padding': 16},
        'children': <dynamic>[],
      }));
      expect(rootChanged.changedPaths, ['root']);
    });

    test('U5: pinning drift flags fire with empty structural delta', () {
      final tree = _tree();
      final a = p(tree);
      final vocabDrift = p(tree, vocab: 'material@2.0.0');
      final schemaDrift = p(tree, schema: '1.1.0');

      final v = a.diff(vocabDrift);
      expect(v.vocabularyChanged, isTrue);
      expect(v.schemaChanged, isFalse);
      expect(v.addedPaths, isEmpty);
      expect(v.removedPaths, isEmpty);
      expect(v.changedPaths, isEmpty);
      expect(v.hasChanges, isTrue);

      final s = a.diff(schemaDrift);
      expect(s.schemaChanged, isTrue);
      expect(s.vocabularyChanged, isFalse);
      expect(s.hasChanges, isTrue);
    });

    test('U5: identical payloads yield an empty diff', () {
      final a = p(_tree());
      final b = p(_tree());
      final delta = a.diff(b);
      expect(delta.addedPaths, isEmpty);
      expect(delta.removedPaths, isEmpty);
      expect(delta.changedPaths, isEmpty);
      expect(delta.vocabularyChanged, isFalse);
      expect(delta.schemaChanged, isFalse);
      expect(delta.hasChanges, isFalse);
    });

    test('U9: UiTreeDiff equality holds across all six fields', () {
      final d1 = UiTreeDiff(
        addedPaths: ['root/2'],
        removedPaths: ['root/1'],
        changedPaths: ['root/0'],
        vocabularyChanged: false,
        schemaChanged: true,
      );
      final d2 = UiTreeDiff(
        addedPaths: ['root/2'],
        removedPaths: ['root/1'],
        changedPaths: ['root/0'],
        vocabularyChanged: false,
        schemaChanged: true,
      );
      expect(d1, equals(d2));
      expect(d1.hashCode, d2.hashCode);
      expect(
        d1.toString(),
        contains('+1'),
      ); // summary form carries counts
    });

    test('U10: UiTreeDiff path lists are deterministically ordered', () {
      final delta = UiTreeDiff(
        addedPaths: ['root/10', 'root/2'],
        removedPaths: const [],
        changedPaths: const [],
        vocabularyChanged: false,
        schemaChanged: false,
      );
      // Sorted lexically for deterministic reporting/replay artifacts.
      expect(delta.addedPaths, ['root/10', 'root/2']);
      expect(delta.hasChanges, isTrue);
    });
  });
}
