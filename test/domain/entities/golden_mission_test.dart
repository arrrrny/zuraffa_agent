// Tests for GoldenMission entity — Spec 006: Eval Harness
//
// Covers:
// - Entity construction and field access
// - JSON serialization round-trip
// - copyWith behavior
// - Cassette and grader bindings structure

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';

GoldenMission makeMission({
  String? id,
  String? name,
  Map<String, dynamic>? cassette,
  String? taskDefinition,
  List<String>? graderBindings,
}) {
  return GoldenMission(
    id: id ?? 'gm-1',
    name: name ?? 'security-scan',
    cassette: cassette ?? {
      'llm_responses': [
        {'request_hash': 'abc123', 'response': 'Analysis complete.'}
      ],
      'tool_results': [
        {'tool': 'read_file', 'result': 'File contents...'}
      ],
    },
    taskDefinition: taskDefinition ?? 'Scan codebase for vulnerabilities.',
    graderBindings: graderBindings ?? ['exact-match', 'schema-validate'],
  );
}

void main() {
  group('GoldenMission', () {
    test('construction and field access', () {
      final mission = makeMission();
      expect(mission.id, 'gm-1');
      expect(mission.name, 'security-scan');
      expect(mission.cassette, isNotNull);
      expect(mission.cassette['llm_responses'], isA<List<dynamic>>());
      expect(mission.taskDefinition, 'Scan codebase for vulnerabilities.');
      expect(mission.graderBindings, ['exact-match', 'schema-validate']);
    });

    test('construction with empty cassette', () {
      final mission = GoldenMission(
        id: 'gm-empty-cassette',
        name: 'test-mission',
        cassette: {},
        taskDefinition: 'Test task.',
        graderBindings: [],
      );
      expect(mission.cassette, isEmpty);
      expect(mission.graderBindings, isEmpty);
    });

    test('copyWith creates new instance with overrides', () {
      final original = makeMission();
      final updated = original.copyWith(
        name: 'updated-scan',
        graderBindings: ['model-judge'],
      );

      expect(updated.name, 'updated-scan');
      expect(updated.graderBindings, ['model-judge']);
      expect(updated.id, original.id);
      expect(updated.taskDefinition, original.taskDefinition);
    });

    test('toJson produces expected keys', () {
      final mission = makeMission();
      final json = mission.toJson();

      expect(json['id'], 'gm-1');
      expect(json['name'], 'security-scan');
      expect(json['cassette'], isA<Map<String, dynamic>>());
      expect(json['taskDefinition'], 'Scan codebase for vulnerabilities.');
      expect(json['graderBindings'], ['exact-match', 'schema-validate']);
    });

    test('fromJson round-trip preserves all fields', () {
      final original = makeMission(
        id: 'gm-complex',
        name: 'complex-mission',
        cassette: {
          'llm_responses': [
            {'request_hash': 'req1', 'response': 'Response 1'},
            {'request_hash': 'req2', 'response': 'Response 2'},
          ],
          'tool_results': [
            {'tool': 'search', 'result': 'Found 5 issues'},
          ],
        },
        taskDefinition: 'Complex analysis task.',
        graderBindings: ['exact-match', 'schema-validate', 'model-judge'],
      );
      final json = original.toJson();
      final restored = GoldenMission.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.cassette, original.cassette);
      expect(restored.taskDefinition, original.taskDefinition);
      expect(restored.graderBindings, original.graderBindings);
    });

    test('fromJson with minimal data', () {
      final json = <String, dynamic>{
        'id': 'gm-minimal',
        'name': 'minimal',
        'cassette': <String, dynamic>{},
        'taskDefinition': 'Simple task.',
        'graderBindings': <String>[],
      };
      final mission = GoldenMission.fromJson(json);

      expect(mission.id, 'gm-minimal');
      expect(mission.cassette, isEmpty);
      expect(mission.graderBindings, isEmpty);
    });
  });

  group('GoldenMission - Cassette Structure', () {
    test('cassette contains llm_responses', () {
      final mission = makeMission(
        cassette: {
          'llm_responses': [
            {'request_hash': 'hash1', 'response': 'Hello'},
          ],
        },
      );
      expect(mission.cassette['llm_responses'], hasLength(1));
    });

    test('cassette contains tool_results', () {
      final mission = makeMission(
        cassette: {
          'tool_results': [
            {'tool': 'read_file', 'result': 'content'},
          ],
        },
      );
      expect(mission.cassette['tool_results'], hasLength(1));
    });

    test('cassette with multiple responses', () {
      final mission = makeMission(
        cassette: {
          'llm_responses': List.generate(
            10,
            (i) => {'request_hash': 'hash$i', 'response': 'Response $i'},
          ),
        },
      );
      expect(mission.cassette['llm_responses'], hasLength(10));
    });
  });

  group('GoldenMission - Grader Bindings', () {
    test('exact-match grader', () {
      final mission = makeMission(graderBindings: ['exact-match']);
      expect(mission.graderBindings, contains('exact-match'));
    });

    test('schema-validate grader', () {
      final mission = makeMission(graderBindings: ['schema-validate']);
      expect(mission.graderBindings, contains('schema-validate'));
    });

    test('model-judge grader', () {
      final mission = makeMission(graderBindings: ['model-judge']);
      expect(mission.graderBindings, contains('model-judge'));
    });

    test('multiple graders', () {
      final mission = makeMission(
        graderBindings: ['exact-match', 'schema-validate', 'model-judge'],
      );
      expect(mission.graderBindings, hasLength(3));
    });
  });
}
