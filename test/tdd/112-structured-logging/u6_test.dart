// GENERATED TEST — `zfa tdd gen U6` (spec 044-test-tdd-generation).
//
// behavior_id: U6
// source_criterion: FR-006, AgentLog.document
// kind: unit
// description: ARCHITECTURE.md MUST document the logger hierarchy, the
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/112-structured-logging/u6_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/u6_subject.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/u6_subject.dart' as subject;

String _section(String heading, String nextHeading) {
  final doc = File('ARCHITECTURE.md').readAsStringSync();
  final start = doc.indexOf(heading);
  final end = doc.indexOf(nextHeading);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing heading $heading');
  expect(end, greaterThan(start), reason: 'missing heading $nextHeading');
  return doc.substring(start, end);
}

void main() {
  group('U6 (FR-006, AgentLog.document)', () {
    test('U6 — ARCHITECTURE.md MUST document the logger hierarchy, the', () {
      // Assertion-shaped guard: a missing docs section fails HERE.
      expect(
        () => subject_u6(
          _section('### Logger hierarchy', '### Level policy'),
          _section('### Level policy', '### Recommended consumer sink'),
          // The sink recipe runs to end-of-doc — bound by the parent
          // heading would match the parent itself earlier in the file.
          File('ARCHITECTURE.md').readAsStringSync().substring(
              File('ARCHITECTURE.md').readAsStringSync().indexOf('### Recommended consumer sink')),
        ),
        returnsNormally,
      );
      // The pinned six-subsystem names all appear in the hierarchy table.
      final hierarchy = _section('### Logger hierarchy', '### Level policy');
      for (final subsystem in ['llm', 'mcp', 'engine', 'eval', 'session', 'eventBus']) {
        expect(hierarchy, contains('`zuraffa.agent.$subsystem`'),
            reason: 'hierarchy missing $subsystem');
      }
      // The level policy table pins all four classes.
      final policy = _section('### Level policy', '### Recommended consumer sink');
      for (final level in ['FINE', 'INFO', 'WARNING', 'SEVERE']) {
        expect(policy, contains(level), reason: 'policy missing $level');
      }
      // The sink recipe names the install point.
      final doc = File('ARCHITECTURE.md').readAsStringSync();
      final recipe = doc.substring(doc.indexOf('### Recommended consumer sink'));
      expect(recipe, contains('ZuraffaLogging.install'));
    });
  });
}
