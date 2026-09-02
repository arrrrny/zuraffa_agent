// Spec 038 / issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI) —
// UiSpec value object: the `ui:` section of an agent spec.
//
// Covers AC-2 (Spec `ui:` section pins vocabulary; out-of-pin trees
// rejected with typed errors) end-to-end:
// - UiSpec construction + equality
// - UiCaps construction + equality + hasAnyCap
// - UiSpec.validatePayload across all three error kinds:
//   vocabularyMismatch, disallowedComponent, capExceeded
// - UiVocabularyPinError value-object semantics
// - YamlAgentSpec carries ui field; the existing validate() surface
//   still works.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_spec/ui_spec.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';
import 'package:zuraffa_agent/src/domain/entities/yaml_agent_spec/yaml_agent_spec.dart';

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
  group('issue #8 AC-2 — UiSpec value object', () {
    test('UiCaps construction and equality', () {
      expect(
        const UiCaps(depth: 3, nodes: 10),
        const UiCaps(depth: 3, nodes: 10),
      );
      expect(const UiCaps(depth: 3).hashCode, const UiCaps(depth: 3).hashCode);
      expect(const UiCaps().hasAnyCap, isFalse);
      expect(const UiCaps(depth: 3).hasAnyCap, isTrue);
      expect(const UiCaps(nodes: 5).hasAnyCap, isTrue);
    });

    test('UiSpec rejects empty vocabulary at construction', () {
      expect(() => UiSpec(vocabulary: ''), throwsA(isA<ArgumentError>()));
    });

    test('UiSpec equality folds vocabulary, allowedComponents, and caps', () {
      expect(
        UiSpec(
          vocabulary: 'shadcn-ui@1.0.0',
          allowedComponents: const ['Column', 'Text'],
        ),
        UiSpec(
          vocabulary: 'shadcn-ui@1.0.0',
          allowedComponents: const ['Column', 'Text'],
        ),
      );
      expect(
        UiSpec(vocabulary: 'shadcn-ui@1.0.0', caps: const UiCaps(depth: 3)),
        UiSpec(vocabulary: 'shadcn-ui@1.0.0', caps: const UiCaps(depth: 3)),
      );
    });

    test('UiVocabularyPinError is a value object', () {
      const a = UiVocabularyPinError(
        kind: UiVocabularyPinErrorKind.vocabularyMismatch,
        field: 'vocabularyId',
        reason: 'r1',
      );
      const b = UiVocabularyPinError(
        kind: UiVocabularyPinErrorKind.vocabularyMismatch,
        field: 'vocabularyId',
        reason: 'r1',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('issue #8 AC-2 — UiSpec.validatePayload', () {
    test('in-pin payload returns no errors', () {
      final spec = UiSpec(
        vocabulary: 'shadcn-ui@1.0.0',
        allowedComponents: const ['Column', 'Text'],
        caps: const UiCaps(depth: 3, nodes: 10),
      );
      final errors = spec.validatePayload(_payload());
      expect(errors, isEmpty);
    });

    test('vocabulary mismatch produces vocabularyMismatch error', () {
      final spec = UiSpec(vocabulary: 'shadcn-ui@1.0.0');
      final errors = spec.validatePayload(
        _payload(vocab: 'flutter-material@1.0.0'),
      );
      expect(errors.length, 1);
      expect(errors.first.kind, UiVocabularyPinErrorKind.vocabularyMismatch);
      expect(errors.first.field, 'vocabularyId');
      expect(errors.first.reason, contains('flutter-material@1.0.0'));
      expect(errors.first.reason, contains('shadcn-ui@1.0.0'));
    });

    test('disallowed component type produces disallowedComponent error', () {
      final spec = UiSpec(
        vocabulary: 'shadcn-ui@1.0.0',
        allowedComponents: const ['Column', 'Text'],
      );
      // Tree with a 'Button' node — not in the allowlist.
      final payload = _payload(
        tree: {
          'type': 'Column',
          'children': [
            {'type': 'Button'},
          ],
        },
      );
      final errors = spec.validatePayload(payload);
      expect(errors.length, 1);
      expect(errors.first.kind, UiVocabularyPinErrorKind.disallowedComponent);
      expect(errors.first.field, 'tree.type');
      expect(errors.first.reason, contains('Button'));
    });

    test('allowedComponents empty list means no component check', () {
      final spec = UiSpec(
        vocabulary: 'shadcn-ui@1.0.0',
        allowedComponents: const [],
      );
      // Tree with arbitrary types — no error because allowlist is empty.
      final payload = _payload(
        tree: {
          'type': 'Whatever',
          'children': [
            {'type': 'AlsoWhatever'},
          ],
        },
      );
      expect(spec.validatePayload(payload), isEmpty);
    });

    test('depth cap exceeded produces capExceeded error on depth', () {
      final spec = UiSpec(
        vocabulary: 'shadcn-ui@1.0.0',
        caps: const UiCaps(depth: 2),
      );
      // 3-level tree → depth 3 > cap 2.
      final payload = _payload(
        tree: {
          'type': 'Column',
          'children': [
            {
              'type': 'Row',
              'children': [
                {'type': 'Text'},
              ],
            },
          ],
        },
      );
      final errors = spec.validatePayload(payload);
      expect(errors.length, 1);
      expect(errors.first.kind, UiVocabularyPinErrorKind.capExceeded);
      expect(errors.first.field, 'depth');
    });

    test('node count cap exceeded produces capExceeded error on nodeCount', () {
      final spec = UiSpec(
        vocabulary: 'shadcn-ui@1.0.0',
        caps: const UiCaps(nodes: 2),
      );
      // 3-node tree → nodeCount 3 > cap 2.
      final payload = _payload(
        tree: {
          'type': 'Column',
          'children': [
            {'type': 'Text'},
            {'type': 'Text'},
          ],
        },
      );
      final errors = spec.validatePayload(payload);
      expect(errors.length, 1);
      expect(errors.first.kind, UiVocabularyPinErrorKind.capExceeded);
      expect(errors.first.field, 'nodeCount');
    });

    test('multiple violations produce multiple errors in order', () {
      final spec = UiSpec(
        vocabulary: 'shadcn-ui@1.0.0',
        allowedComponents: const ['Column'],
        caps: const UiCaps(depth: 1, nodes: 1),
      );
      // Wrong vocab + disallowed component + both caps exceeded.
      final payload = _payload(
        vocab: 'other@1.0.0',
        tree: {
          'type': 'Column',
          'children': [
            {'type': 'Text'},
          ],
        },
      );
      final errors = spec.validatePayload(payload);
      // vocabularyMismatch, disallowedComponent, capExceeded(depth), capExceeded(nodeCount).
      expect(errors.length, 4);
      expect(errors[0].kind, UiVocabularyPinErrorKind.vocabularyMismatch);
      expect(errors[1].kind, UiVocabularyPinErrorKind.disallowedComponent);
      expect(errors[2].kind, UiVocabularyPinErrorKind.capExceeded);
      expect(errors[2].field, 'depth');
      expect(errors[3].kind, UiVocabularyPinErrorKind.capExceeded);
      expect(errors[3].field, 'nodeCount');
    });
  });

  group('issue #8 AC-2 — YamlAgentSpec carries ui section', () {
    test('YamlAgentSpec.ui is nullable (no pin = no rejection)', () {
      const spec = YamlAgentSpec(
        id: 'default',
        name: 'base',
        toolAllowlist: ['read_file'],
        systemPrompt: 'You are helpful.',
      );
      expect(spec.ui, isNull);
    });

    test('YamlAgentSpec.ui survives equality', () {
      final a = YamlAgentSpec(
        id: 'default',
        name: 'base',
        toolAllowlist: const ['read_file'],
        systemPrompt: 'You are helpful.',
        ui: UiSpec(vocabulary: 'shadcn-ui@1.0.0'),
      );
      final b = YamlAgentSpec(
        id: 'default',
        name: 'base',
        toolAllowlist: const ['read_file'],
        systemPrompt: 'You are helpful.',
        ui: UiSpec(vocabulary: 'shadcn-ui@1.0.0'),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('YamlAgentSpec.validate still works with ui set', () {
      final spec = YamlAgentSpec(
        id: 'default',
        name: 'base',
        toolAllowlist: const ['read_file'],
        systemPrompt: 'You are helpful.',
        ui: UiSpec(vocabulary: 'shadcn-ui@1.0.0'),
      );
      final errors = spec.validate(parentOf: {}, knownTools: {'read_file'});
      expect(errors, isEmpty);
    });
  });
}
