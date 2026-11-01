// Tests for SuiteLoader (issue #115).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/eval/suite_loader.dart';

void main() {
  group('SuiteLoader', () {
    test('loadFromString parses valid YAML suite', () {
      const yaml = '''
id: test-suite
name: Test Suite
k: 2
gate_threshold: 0.8
tasks:
  - GM-1
  - GM-2
  - GM-3
''';
      const loader = SuiteLoader();
      final suite = loader.loadFromString(yaml);

      expect(suite.id, 'test-suite');
      expect(suite.name, 'Test Suite');
      expect(suite.k, 2);
      expect(suite.gateThreshold, 0.8);
      expect(suite.tasks, ['GM-1', 'GM-2', 'GM-3']);
    });

    test('loadFromString throws on missing required fields', () {
      const yaml = '''
id: test-suite
name: Test Suite
''';
      const loader = SuiteLoader();

      expect(
        () => loader.loadFromString(yaml),
        throwsA(isA<SuiteLoadException>()),
      );
    });

    test('loadFromString throws on invalid k type', () {
      const yaml = '''
id: test-suite
name: Test Suite
k: not_an_int
gate_threshold: 0.8
tasks:
  - GM-1
''';
      const loader = SuiteLoader();

      expect(
        () => loader.loadFromString(yaml),
        throwsA(isA<SuiteLoadException>()),
      );
    });

    test('loadFromString throws on invalid gate_threshold type', () {
      const yaml = '''
id: test-suite
name: Test Suite
k: 2
gate_threshold: not_a_number
tasks:
  - GM-1
''';
      const loader = SuiteLoader();

      expect(
        () => loader.loadFromString(yaml),
        throwsA(isA<SuiteLoadException>()),
      );
    });

    test('loadFromString throws on missing tasks', () {
      const yaml = '''
id: test-suite
name: Test Suite
k: 2
gate_threshold: 0.8
''';
      const loader = SuiteLoader();

      expect(
        () => loader.loadFromString(yaml),
        throwsA(isA<SuiteLoadException>()),
      );
    });

    test('loadFromString handles integer gate_threshold', () {
      const yaml = '''
id: test-suite
name: Test Suite
k: 2
gate_threshold: 0
tasks:
  - GM-1
''';
      const loader = SuiteLoader();
      final suite = loader.loadFromString(yaml);

      expect(suite.gateThreshold, 0.0);
    });

    test('loadFromString handles empty tasks list', () {
      const yaml = '''
id: empty-suite
name: Empty Suite
k: 2
gate_threshold: 0.8
tasks: []
''';
      const loader = SuiteLoader();
      final suite = loader.loadFromString(yaml);

      expect(suite.tasks, isEmpty);
    });
  });
}
