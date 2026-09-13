// GENERATED TEST — `zfa tdd gen A5` (spec 044-test-tdd-generation).
//
// behavior_id: A5
// source_criterion: AC-5
// kind: acceptance
// description: each declares `zuraffa_agent` + the platform interface as
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/a5_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A5:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';
import 'dart:io';


import 'package:zuraffa_agent/tdd/115-agent-platform-packages/a5_subject.dart';


Map<String, dynamic> _readPackages() {
  const names = [
    'zuraffa_agent_android',
    'zuraffa_agent_ios',
    'zuraffa_agent_macos',
    'zuraffa_agent_platform_interface',
  ];
  return {
    for (final name in names)
      name: _parse(
        name,
        File('packages/$name/pubspec.yaml').readAsStringSync(),
        isInterface: name == 'zuraffa_agent_platform_interface',
      ),
  };
}

Map<String, dynamic> _parse(String name, String pubspec, {bool isInterface = false}) {
  final deps = <String>[
    if (pubspec.contains('zuraffa_agent:')) 'zuraffa_agent',
    if (pubspec.contains('zuraffa_agent_platform_interface:')) 'zuraffa_agent_platform_interface',
  ];
  final pluginPlatforms = <String>[
    if (pubspec.contains('android:')) 'android',
    if (pubspec.contains('ios:')) 'ios',
    if (pubspec.contains('macos:')) 'macos',
  ];
  return {
    'deps': deps,
    'pluginPlatforms': isInterface ? <String>[] : pluginPlatforms,
  };
}

void main() {
  group('A5 (AC-5)', () {
    test('A5 — each declares `zuraffa_agent` + the platform interface as', ()  {
      final packages = _readPackages();
      // Assertion-shaped guard: structure drift fails HERE.
      expect(() => subject_a5(packages), returnsNormally);
      final failures = subject_a5(packages);
      expect(failures, isEmpty, reason: 'structure drift: $failures');
    });
  });
}
