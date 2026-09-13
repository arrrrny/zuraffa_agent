// GENERATED TEST — `zfa tdd gen A7` (spec 044-test-tdd-generation).
//
// behavior_id: A7
// source_criterion: AC-7
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a7_subject.dart';

void main() {
  group('A7 (AC-7)', () {
    test('A7 — it documents the `zuraffa.agent.` logger hierarchy (Type: acceptance)', ()  {
      final doc = File('ARCHITECTURE.md').readAsStringSync();
      expect(
        () => subject_a7(
          doc.substring(doc.indexOf('### Logger hierarchy'), doc.indexOf('### Level policy')),
          doc.substring(doc.indexOf('### Level policy'), doc.indexOf('### Recommended consumer sink')),
          doc.substring(doc.indexOf('### Recommended consumer sink')),
        ),
        returnsNormally,
      );
      for (final subsystem in ['llm', 'mcp', 'engine', 'eval', 'session', 'eventBus']) {
        expect(doc, contains('`zuraffa.agent.$subsystem`'));
      }
      for (final level in ['FINE', 'INFO', 'WARNING', 'SEVERE']) {
        expect(doc, contains(level));
      }
      expect(doc, contains('ZuraffaLogging.install'));
    });
  });
}
