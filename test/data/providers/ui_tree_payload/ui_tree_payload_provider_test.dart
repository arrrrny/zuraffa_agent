// Regression test for arrarrny/zuraffa_agent#8 (UI/tree+json payloads).
//
// Asserts:
// - UiTreePayload.mimeType constant is "ui/tree+json".
// - UiTreePayload is constructible with vocabularyId + schemaVersion +
//   tree and auto-computes depth + nodeCount.
// - computeDepth returns 1 for a leaf node; computes correct depth for
//   multi-level trees.
// - computeNodeCount returns 1 for a leaf node; computes correct count
//   for multi-level trees.
// - UiTreePayload throws ArgumentError on empty vocabularyId or
//   schemaVersion.
// - Value equality holds across all five fields (incl. deep tree equality).
// - The clean-arch layers (UiTreePayloadService + UiTreePayloadProvider)
//   are wired correctly and compile.
// - The provider's UnimplementedError stubs fire.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';
import 'package:zuraffa_agent/src/domain/services/ui_tree_payload_service.dart';
import 'package:zuraffa_agent/src/data/providers/ui_tree_payload/ui_tree_payload_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#8 — UiTreePayload value object', () {
    test('mimeType constant is "ui/tree+json"', () {
      expect(UiTreePayload.mimeType, 'ui/tree+json');
    });

    test('UiTreePayload is constructible with vocabularyId + schemaVersion + tree', () {
      final payload = UiTreePayload(
        vocabularyId: 'shadcn-ui@1.0.0',
        schemaVersion: '1.0.0',
        tree: {'type': 'Card', 'props': {'title': 'hi'}},
      );
      expect(payload.vocabularyId, 'shadcn-ui@1.0.0');
      expect(payload.schemaVersion, '1.0.0');
      expect(payload.tree['type'], 'Card');
      expect(payload.depth, 1);
      expect(payload.nodeCount, 1);
    });

    test('computeDepth returns 1 for a leaf node (no children)', () {
      final depth = UiTreePayload.computeDepth({'type': 'Text'});
      expect(depth, 1);
    });

    test('computeDepth walks multi-level trees correctly', () {
      final tree = {
        'type': 'Column',
        'children': [
          {'type': 'Text'},
          {
            'type': 'Row',
            'children': [
              {'type': 'Text'},
              {'type': 'Text'},
            ]
          },
        ]
      };
      // Column (1) → Row (2) → Text (3) → max depth 3.
      expect(UiTreePayload.computeDepth(tree), 3);
    });

    test('computeNodeCount counts all nodes (root included)', () {
      final tree = {
        'type': 'Column',
        'children': [
          {'type': 'Text'},
          {
            'type': 'Row',
            'children': [
              {'type': 'Text'},
              {'type': 'Text'},
            ]
          },
        ]
      };
      // Column + Text + Row + Text + Text = 5 nodes.
      expect(UiTreePayload.computeNodeCount(tree), 5);
    });

    test('UiTreePayload throws ArgumentError on empty vocabularyId', () {
      expect(
        () => UiTreePayload(
          vocabularyId: '',
          schemaVersion: '1.0.0',
          tree: {'type': 'Text'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('UiTreePayload throws ArgumentError on empty schemaVersion', () {
      expect(
        () => UiTreePayload(
          vocabularyId: 'shadcn-ui@1.0.0',
          schemaVersion: '',
          tree: {'type': 'Text'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('UiTreePayload equality is value-based with deep tree equality', () {
      final treeA = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'props': {'value': 'hi'}},
        ]
      };
      final treeB = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'props': {'value': 'hi'}},
        ]
      };
      final a = UiTreePayload(
        vocabularyId: 'shadcn-ui@1.0.0',
        schemaVersion: '1.0.0',
        tree: treeA,
      );
      final b = UiTreePayload(
        vocabularyId: 'shadcn-ui@1.0.0',
        schemaVersion: '1.0.0',
        tree: treeB,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.depth, b.depth);
      expect(a.nodeCount, b.nodeCount);
    });
  });

  group('arrarrny/zuraffa_agent#8 — UiTreePayload clean-arch layers', () {
    test('UiTreePayloadProvider is a UiTreePayloadService', () {
      final provider = UiTreePayloadProvider();
      expect(provider, isA<UiTreePayloadService>());
    });

    test('UiTreePayloadProvider.current throws UnimplementedError on NoParams', () {
      final provider = UiTreePayloadProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('UiTreePayloadProvider.count throws UnimplementedError on NoParams', () {
      final provider = UiTreePayloadProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
