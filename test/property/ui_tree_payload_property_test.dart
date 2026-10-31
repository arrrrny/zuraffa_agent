// Property-based tests for the UiTreePayload value object — issue #128 AC-2.
//
// UiTreePayload is a pure JSON carrier — ideal for round-trip properties.
// The core invariant (quoted from the fromJson doc comment) is
// `fromJson(toJson(p)) == p`. These properties push it over the wire (through
// jsonEncode/jsonDecode) and over randomized tree shapes:
//
//   R1  fromJson(jsonEncode(toJson(p))) == p for random trees
//   R2  re-serialization is byte-stable: encode(toJson(fromJson(j))) == j
//   R3  unknown top-level keys are ignored (forward compatibility)
//   C1  depth/nodeCount match an independent recursive computation
//   C2  depth >= 1, nodeCount >= 1, nodeCount >= depth
//   D1  diff(p, p) is empty; pinning drift flags are exact
//   D2  adding/removing a leaf is reported exactly at that path
//
// All randomness is seeded (see property_harness.dart) — CI-stable.
library;

import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';

import 'property_harness.dart';

void main() {
  UiTreePayload randomPayload(Random rnd, {int maxDepth = 4}) => UiTreePayload(
    vocabularyId: randomNonEmptyString(rnd, maxLength: 12),
    schemaVersion: randomNonEmptyString(rnd, maxLength: 8),
    tree: randomUiTreeNode(rnd, maxDepth: maxDepth),
  );

  /// Independent reference implementation (the oracle): written against the
  /// doc-comment definition, not against the production walker.
  int refDepth(Map<String, dynamic> node) {
    final children = node['children'];
    if (children is! List || children.isEmpty) return 1;
    var maxChild = 0;
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        final d = refDepth(child);
        if (d > maxChild) maxChild = d;
      }
    }
    return maxChild == 0 ? 1 : 1 + maxChild;
  }

  int refNodeCount(Map<String, dynamic> node) {
    final children = node['children'];
    if (children is! List || children.isEmpty) return 1;
    var count = 1;
    for (final child in children) {
      if (child is Map<String, dynamic>) count += refNodeCount(child);
    }
    return count;
  }

  group('UiTreePayload properties (seeded, randomized)', () {
    test('R1: fromJson(jsonEncode(toJson(p))) == p for random trees', () {
      check('R1 wire round-trip', (rnd, trial) {
        final payload = randomPayload(rnd, maxDepth: intBetween(rnd, 1, 5));
        final wire = jsonEncode(payload.toJson());
        final parsed = UiTreePayload.fromJson(
          jsonDecode(wire) as Map<String, dynamic>,
        );
        expect(
          parsed,
          equals(payload),
          reason:
              'trial $trial: round-trip broke on '
              'depth=${payload.depth} nodes=${payload.nodeCount}',
        );
      }, iterations: 300);
    });

    test('R2: re-serialization is byte-stable through the wire', () {
      check('R2 byte-stable reserialization', (rnd, trial) {
        final payload = randomPayload(rnd, maxDepth: intBetween(rnd, 1, 5));
        final wire = jsonEncode(payload.toJson());
        final parsed = UiTreePayload.fromJson(
          jsonDecode(wire) as Map<String, dynamic>,
        );
        final wireAgain = jsonEncode(parsed.toJson());
        expect(
          wireAgain,
          wire,
          reason: 'trial $trial: serialization is not a fixed point',
        );
      }, iterations: 300);
    });

    test('R3: unknown top-level keys are ignored on parse', () {
      check('R3 forward compatibility', (rnd, trial) {
        final payload = randomPayload(rnd, maxDepth: intBetween(rnd, 1, 4));
        final json = payload.toJson()
          ..['futureField'] = randomJsonValue(rnd, maxDepth: 2);
        final parsed = UiTreePayload.fromJson(json);
        expect(parsed, equals(payload), reason: 'trial $trial');
      }, iterations: 200);
    });

    test('C1: depth/nodeCount match an independent recursive oracle', () {
      check('C1 depth/count oracle', (rnd, trial) {
        final tree = randomUiTreeNode(rnd, maxDepth: intBetween(rnd, 1, 6));
        final payload = UiTreePayload(
          vocabularyId: 'vocab-$trial',
          schemaVersion: '1.0.0',
          tree: tree,
        );
        expect(payload.depth, refDepth(tree), reason: 'trial $trial');
        expect(payload.nodeCount, refNodeCount(tree), reason: 'trial $trial');
      }, iterations: 300);
    });

    test('C2: depth >= 1, nodeCount >= 1, nodeCount >= depth always', () {
      check('C2 structural bounds', (rnd, trial) {
        final payload = randomPayload(rnd, maxDepth: intBetween(rnd, 1, 5));
        expect(payload.depth, greaterThanOrEqualTo(1), reason: 'trial $trial');
        expect(
          payload.nodeCount,
          greaterThanOrEqualTo(1),
          reason: 'trial $trial',
        );
        expect(
          payload.nodeCount,
          greaterThanOrEqualTo(payload.depth),
          reason: 'trial $trial: a tree cannot have fewer nodes than depth',
        );
      }, iterations: 300);
    });

    test('D1: diff against itself is empty; pinning drift is exact', () {
      check('D1 self-diff empty', (rnd, trial) {
        final a = randomPayload(rnd, maxDepth: intBetween(rnd, 1, 4));
        final b = randomPayload(rnd, maxDepth: intBetween(rnd, 1, 4));
        expect(a.diff(a).hasChanges, isFalse, reason: 'trial $trial');

        final crossVocab = a.diff(b);
        expect(
          crossVocab.vocabularyChanged,
          a.vocabularyId != b.vocabularyId,
          reason: 'trial $trial',
        );
        expect(
          crossVocab.schemaChanged,
          a.schemaVersion != b.schemaVersion,
          reason: 'trial $trial',
        );
        // Structural diff must be symmetric.
        expect(
          b.diff(a).addedPaths,
          a.diff(b).removedPaths,
          reason: 'trial $trial: added/removed must be symmetric',
        );
      }, iterations: 200);
    });

    test('D2: adding/removing one leaf is reported exactly at its path', () {
      check('D2 single-leaf delta', (rnd, trial) {
        final base = randomPayload(rnd, maxDepth: 3);
        // Deep-copy the tree, then graft one extra leaf as the LAST child
        // of the root (positional diff: existing children keep their
        // indices — nothing shifts, which is exactly the contract).
        final graft = jsonDecode(jsonEncode(base.tree)) as Map<String, dynamic>;
        final existing = (graft['children'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();
        final newIndex = existing.length;
        final marker = 'leaf-$trial-${intBetween(rnd, 0, 9999)}';
        existing.add({'type': 'leaf', 'id': marker});
        graft['children'] = existing;

        final bigger = UiTreePayload(
          vocabularyId: base.vocabularyId,
          schemaVersion: base.schemaVersion,
          tree: graft,
        );

        final grew = base.diff(bigger);
        expect(grew.addedPaths, ['root/$newIndex'], reason: 'trial $trial');
        expect(grew.removedPaths, isEmpty, reason: 'trial $trial');
        expect(grew.changedPaths, isEmpty, reason: 'trial $trial');
        expect(grew.hasChanges, isTrue, reason: 'trial $trial');

        final shrank = bigger.diff(base);
        expect(shrank.removedPaths, ['root/$newIndex'], reason: 'trial $trial');
        expect(shrank.addedPaths, isEmpty, reason: 'trial $trial');
      }, iterations: 200);
    });
  });
}
