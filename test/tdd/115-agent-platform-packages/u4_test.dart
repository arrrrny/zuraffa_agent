// GENERATED TEST — `zfa tdd gen U4` (spec 044-test-tdd-generation).
//
// behavior_id: U4
// source_criterion: FR-004, FederatedBridge.structure
// kind: unit
// description: The federated packages MUST ship with correct pubspec
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/u4_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.


library;

import 'package:test/test.dart';
import 'dart:io';


import 'package:zuraffa_agent/tdd/115-agent-platform-packages/u4_subject.dart';



Map<String, dynamic> _readPackages() {
  const names = [
    'zuraffa_agent_android',
    'zuraffa_agent_ios',
    'zuraffa_agent_macos',
    'zuraffa_agent_platform_interface',
  ];
  return {
    for (final name in names)
      name: _parse(name, File('packages/$name/pubspec.yaml').readAsStringSync()),
  };
}

Map<String, dynamic> _parse(String name, String pubspec) {
  final deps = <String>[
    if (pubspec.contains('zuraffa_agent:')) 'zuraffa_agent',
    if (pubspec.contains('zuraffa_agent_platform_interface:')) 'zuraffa_agent_platform_interface',
  ];
  final pluginPlatforms = <String>[
    if (pubspec.contains('android:')) 'android',
    if (pubspec.contains('ios:')) 'ios',
    if (pubspec.contains('macos:')) 'macos',
  ];
  return {'deps': deps, 'pluginPlatforms': name == 'zuraffa_agent_platform_interface' ? <String>[] : pluginPlatforms};
}

void main() {
  group('U4 (FR-004, FederatedBridge.structure)', () {
    test('U4 — The federated packages MUST ship with correct pubspec', ()  {
      // Assertion-shaped guard: a bad structure fails HERE.
      expect(
        () => subject_u4({
          'zuraffa_agent_android': {'deps': ['flutter'], 'pluginPlatforms': ['android']},
        }),
        returnsNormally,
      );
      final failures = subject_u4(_readPackages());
      expect(failures, isEmpty, reason: 'structure drift: $failures');
    });
  });
}
