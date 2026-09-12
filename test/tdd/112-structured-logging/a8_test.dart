// GENERATED TEST — `zfa tdd gen A8` (spec 044-test-tdd-generation).
//
// behavior_id: A8
// source_criterion: AC-8
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a8_subject.dart';

void main() {
  group('A8 (AC-8)', () {
    test('A8 — there are zero matches (the engine', ()  {
      final sources = <String, String>{};
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        sources[entity.path] = entity.readAsStringSync();
      }
      expect(sources, isNotEmpty);
      final offenders = subject_a8(sources);
      expect(offenders, isEmpty);
      // Pattern fixtures: the scanner flags real console writes and
      // ignores child-process pipe fields and comments.
      final probes = subject_a8(const {
        'p1.dart': 'void f() { print("hi"); }',
        'p2.dart': 'void f() { stdout.writeln("x"); }',
        'p3.dart': 'void f() { stderr.write("y"); }',
        'p4.dart': 'void f() { process.stdout.pipe(stdout); }',
        'p5.dart': '// stdout.writeln("commented out");',
        'p6.dart': 'var x = 1;',
        // Every matcher alternative on both sinks.
        'p7.dart': 'void f() { stdout.write("a"); }',
        'p8.dart': 'void f() { stdout.add("b"); }',
        'p9.dart': 'void f() { stdout.addStream(s); }',
        'p10.dart': 'void f() { stderr.writeln("c"); }',
        'p11.dart': 'void f() { stderr.add("d"); }',
        'p12.dart': 'void f() { stderr.addStream(s); }',
      });
      expect(
        probes,
        [
          'p1.dart', 'p2.dart', 'p3.dart', 'p7.dart', 'p8.dart',
          'p9.dart', 'p10.dart', 'p11.dart', 'p12.dart',
        ],
        reason: 'pipe fields and comments are not console output',
      );
    });
  });
}
