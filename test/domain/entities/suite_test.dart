// Tests for Suite entity — Spec 006: Eval Harness
//
// Covers:
// - Entity construction and field access
// - JSON serialization round-trip
// - copyWith behavior
// - Suite configuration (tasks, k, gate threshold)

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';

Suite makeSuite({
  String? id,
  String? name,
  List<String>? tasks,
  int? k,
  double? gateThreshold,
}) {
  return Suite(
    id: id ?? 'suite-1',
    name: name ?? 'security-audit',
    tasks: tasks ?? ['gm-1', 'gm-2', 'gm-3'],
    k: k ?? 5,
    gateThreshold: gateThreshold ?? 0.8,
  );
}

void main() {
  group('Suite', () {
    test('construction and field access', () {
      final suite = makeSuite();
      expect(suite.id, 'suite-1');
      expect(suite.name, 'security-audit');
      expect(suite.tasks, ['gm-1', 'gm-2', 'gm-3']);
      expect(suite.k, 5);
      expect(suite.gateThreshold, 0.8);
    });

    test('construction with null gate threshold', () {
      final suite = Suite(
        id: 'suite-no-threshold',
        name: 'test',
        tasks: ['gm-1'],
        k: 1,
      );
      expect(suite.gateThreshold, isNull);
    });

    test('copyWith creates new instance with overrides', () {
      final original = makeSuite();
      final updated = original.copyWith(
        name: 'updated-suite',
        k: 10,
      );

      expect(updated.name, 'updated-suite');
      expect(updated.k, 10);
      expect(updated.id, original.id);
      expect(updated.tasks, original.tasks);
    });

    test('toJson produces expected keys', () {
      final suite = makeSuite();
      final json = suite.toJson();

      expect(json['id'], 'suite-1');
      expect(json['name'], 'security-audit');
      expect(json['tasks'], ['gm-1', 'gm-2', 'gm-3']);
      expect(json['k'], 5);
      expect(json['gateThreshold'], 0.8);
    });

    test('fromJson round-trip preserves all fields', () {
      final original = makeSuite(
        id: 'suite-complex',
        name: 'complex-suite',
        tasks: ['gm-1', 'gm-2', 'gm-3', 'gm-4', 'gm-5'],
        k: 10,
        gateThreshold: 0.95,
      );
      final json = original.toJson();
      final restored = Suite.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.tasks, original.tasks);
      expect(restored.k, original.k);
      expect(restored.gateThreshold, original.gateThreshold);
    });

    test('fromJson with minimal data', () {
      final json = {
        'id': 'suite-minimal',
        'name': 'minimal',
        'tasks': ['gm-1'],
        'k': 1,
      };
      final suite = Suite.fromJson(json);

      expect(suite.id, 'suite-minimal');
      expect(suite.gateThreshold, isNull);
    });
  });

  group('Suite - Task Configuration', () {
    test('single task suite', () {
      final suite = makeSuite(tasks: ['gm-1']);
      expect(suite.tasks, hasLength(1));
    });

    test('multi-task suite', () {
      final suite = makeSuite(tasks: ['gm-1', 'gm-2', 'gm-3', 'gm-4', 'gm-5']);
      expect(suite.tasks, hasLength(5));
    });

    test('empty tasks list', () {
      final suite = makeSuite(tasks: []);
      expect(suite.tasks, isEmpty);
    });
  });

  group('Suite - pass@k Configuration', () {
    test('k=1 (pass^1)', () {
      final suite = makeSuite(k: 1);
      expect(suite.k, 1);
    });

    test('k=5 (standard)', () {
      final suite = makeSuite(k: 5);
      expect(suite.k, 5);
    });

    test('k=10 (high sample count)', () {
      final suite = makeSuite(k: 10);
      expect(suite.k, 10);
    });
  });

  group('Suite - Gate Threshold', () {
    test('threshold 0.8 (80%)', () {
      final suite = makeSuite(gateThreshold: 0.8);
      expect(suite.gateThreshold, 0.8);
    });

    test('threshold 0.95 (95%)', () {
      final suite = makeSuite(gateThreshold: 0.95);
      expect(suite.gateThreshold, 0.95);
    });

    test('threshold 1.0 (100%)', () {
      final suite = makeSuite(gateThreshold: 1.0);
      expect(suite.gateThreshold, 1.0);
    });

    test('no threshold (any pass rate)', () {
      final suite = Suite(
        id: 'suite',
        name: 'test',
        tasks: ['gm-1'],
        k: 1,
      );
      expect(suite.gateThreshold, isNull);
    });
  });
}
