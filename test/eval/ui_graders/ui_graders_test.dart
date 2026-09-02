// Spec: issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI) —
// UI tree graders for the eval harness (AC-4): schema grader (validates
// against pinned vocabulary) + snapshot grader (byte-stable canonical
// JSON diff) + GM-6-style golden mission graded headless in CI.
//
// Covers:
// - UiSchemaGrader: PASS on in-pin payload; FAIL with colon-joined
//   reasons on out-of-pin payload.
// - UiSnapshotGrader: byte-stable canonical JSON diff — insertion-order
//   independent, key-sorted at every level, no padding.
// - GM-6 fixture: a golden mission cassette whose emitted tree is
//   graded headlessly by both graders (issue #8 §4: "golden-mission
//   GM-6 (dws_playground) uses this").

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_spec/ui_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';
import 'package:zuraffa_agent/src/eval/ui_graders/ui_graders.dart';
import '../../fixtures/gm6/gm6_fixture.dart';

UiTreePayload _payload({
  String vocab = 'shadcn-ui@1.0.0',
  String schema = '1.0.0',
  Map<String, dynamic>? tree,
}) => UiTreePayload(
  vocabularyId: vocab,
  schemaVersion: schema,
  tree:
      tree ??
      {
        'type': 'Column',
        'children': [
          {
            'type': 'Text',
            'props': {'value': 'hi'},
          },
        ],
      },
);

void main() {
  group('issue #8 AC-4 — UiGradeResult value object', () {
    test('.passed() constructs a passing result', () {
      const r = UiGradeResult.passed();
      expect(r.passed, isTrue);
      expect(r.detail, 'PASS');
    });

    test('.failed(detail) constructs a failing result with the detail', () {
      const r = UiGradeResult.failed('boom');
      expect(r.passed, isFalse);
      expect(r.detail, 'boom');
    });

    test('equality folds passed + detail', () {
      const a = UiGradeResult.passed();
      const b = UiGradeResult.passed();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('issue #8 AC-4 — UiSchemaGrader', () {
    test('PASS on in-pin payload', () {
      final grader = UiSchemaGrader(
        UiSpec(
          vocabulary: 'shadcn-ui@1.0.0',
          allowedComponents: const ['Column', 'Text'],
          caps: const UiCaps(depth: 3, nodes: 10),
        ),
      );
      expect(grader.grade(_payload()).passed, isTrue);
    });

    test('FAIL with joined reasons on out-of-pin payload', () {
      final grader = UiSchemaGrader(
        UiSpec(
          vocabulary: 'shadcn-ui@1.0.0',
          allowedComponents: const ['Column'],
          caps: const UiCaps(depth: 1, nodes: 1),
        ),
      );
      final result = grader.grade(
        _payload(
          vocab: 'other@1.0.0',
          tree: {
            'type': 'Column',
            'children': [
              {'type': 'Text'},
            ],
          },
        ),
      );
      expect(result.passed, isFalse);
      // Reasons are joined by '; ' — see UiSchemaGrader.grade.
      expect(result.detail, contains('vocabulary'));
      expect(result.detail, contains('depth'));
      expect(result.detail, contains('nodeCount'));
    });

    test('pure: same payload + pin yields same verdict every call', () {
      final grader = UiSchemaGrader(UiSpec(vocabulary: 'shadcn-ui@1.0.0'));
      final p = _payload();
      expect(grader.grade(p), grader.grade(p));
    });
  });

  group('issue #8 AC-4 — UiSnapshotGrader', () {
    test('PASS when actual equals pinned (same insertion order)', () {
      final pinned = _payload();
      final grader = UiSnapshotGrader(pinned);
      expect(grader.grade(_payload()).passed, isTrue);
    });

    test(
      'PASS when actual equals pinned (different insertion order, same content)',
      () {
        final pinned = UiTreePayload(
          vocabularyId: 'shadcn-ui@1.0.0',
          schemaVersion: '1.0.0',
          tree: {
            'type': 'Column',
            'props': {'a': 1, 'b': 2, 'c': 3},
            'children': [
              {'type': 'Text'},
            ],
          },
        );
        final grader = UiSnapshotGrader(pinned);
        // Same content, different insertion order.
        final actual = UiTreePayload(
          vocabularyId: 'shadcn-ui@1.0.0',
          schemaVersion: '1.0.0',
          tree: {
            'children': [
              {'type': 'Text'},
            ],
            'props': {'c': 3, 'a': 1, 'b': 2},
            'type': 'Column',
          },
        );
        expect(grader.grade(actual).passed, isTrue);
      },
    );

    test('FAIL when actual differs from pinned', () {
      final pinned = _payload();
      final grader = UiSnapshotGrader(pinned);
      final actual = _payload(
        tree: {
          'type': 'Row', // different root type
          'children': [
            {'type': 'Text'},
          ],
        },
      );
      expect(grader.grade(actual).passed, isFalse);
    });

    test(
      'canonicalize is byte-stable: same input → same output across calls',
      () {
        final input = {
          'b': 2,
          'a': 1,
          'children': [3, 2, 1],
        };
        final c1 = UiSnapshotGrader.canonicalize(input);
        final c2 = UiSnapshotGrader.canonicalize(input);
        expect(c1, c2);
        // Keys are sorted.
        expect(c1, '{"a":1,"b":2,"children":[3,2,1]}');
      },
    );

    test('canonicalize is recursive (nested maps sorted)', () {
      final input = {
        'outer': {'z': 1, 'a': 2},
      };
      final c = UiSnapshotGrader.canonicalize(input);
      expect(c, '{"outer":{"a":2,"z":1}}');
    });

    test('fromCanonical constructor: stored string is ground truth', () {
      final canonical = UiSnapshotGrader.canonicalize(_payload().toJson());
      final grader = UiSnapshotGrader.fromCanonical(canonical);
      expect(grader.grade(_payload()).passed, isTrue);
    });

    test('pure: same actual yields same verdict every call', () {
      final grader = UiSnapshotGrader(_payload());
      final p = _payload();
      expect(grader.grade(p), grader.grade(p));
    });

    test('byte-stable: canonical form is valid JSON decodable', () {
      final c = UiSnapshotGrader.canonicalize(_payload().toJson());
      expect(() => jsonDecode(c), returnsNormally);
    });
  });

  group('issue #8 AC-4 — GM-6 fixture (headless golden mission)', () {
    test('fixture exposes a pinned UiSpec and a pinned canonical snapshot', () {
      expect(gm6Fixture.pinnedSpec, isA<UiSpec>());
      expect(gm6Fixture.pinnedCanonicalSnapshot, isA<String>());
      expect(gm6Fixture.pinnedCanonicalSnapshot, isNotEmpty);
    });

    test('fixture exposes a cassette with an emitted ui/tree+json payload', () {
      final emitted = gm6Fixture.emittedPayload;
      expect(UiTreePayload.mimeType, 'ui/tree+json');
      expect(emitted.toJson()['mimeType'], 'ui/tree+json');
      expect(emitted.vocabularyId, gm6Fixture.pinnedSpec.vocabulary);
    });

    test('schema grader passes on the emitted payload', () {
      final grader = UiSchemaGrader(gm6Fixture.pinnedSpec);
      final result = grader.grade(gm6Fixture.emittedPayload);
      expect(result.passed, isTrue, reason: result.detail);
    });

    test(
      'snapshot grader passes on the emitted payload (byte-stable canonical)',
      () {
        final grader = UiSnapshotGrader.fromCanonical(
          gm6Fixture.pinnedCanonicalSnapshot,
        );
        final result = grader.grade(gm6Fixture.emittedPayload);
        expect(result.passed, isTrue, reason: result.detail);
      },
    );

    test('schema grader FAILS on an out-of-pin payload (negative control)', () {
      final grader = UiSchemaGrader(gm6Fixture.pinnedSpec);
      final outOfPin = UiTreePayload(
        vocabularyId: 'wrong-vocab@1.0.0',
        schemaVersion: '1.0.0',
        tree: {'type': 'Column'},
      );
      expect(grader.grade(outOfPin).passed, isFalse);
    });

    test('snapshot grader FAILS on a different payload (negative control)', () {
      final grader = UiSnapshotGrader.fromCanonical(
        gm6Fixture.pinnedCanonicalSnapshot,
      );
      final different = UiTreePayload(
        vocabularyId: gm6Fixture.pinnedSpec.vocabulary,
        schemaVersion: '1.0.0',
        tree: {'type': 'Row'}, // different root type
      );
      expect(grader.grade(different).passed, isFalse);
    });
  });
}
