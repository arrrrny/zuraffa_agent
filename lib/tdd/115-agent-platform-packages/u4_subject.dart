// GENERATED STUB — hand-stepped (spec 115 U4): the federated structure
// validator. The test reads the real pubspecs and passes them here.
// ignore_for_file: non_constant_identifier_names
library;

/// subject_u4: declared contract `structure(packages) -> StructureReport`.
///
/// [packages]: name -> {'deps': [...], 'pluginPlatforms': [...]}.
/// Returns the names that fail the structure contract.
Map<String, String> subject_u4(Map<String, dynamic> packages) {
  final failures = <String, String>{};
  const expectedPlatforms = {
    'zuraffa_agent_android': ['android'],
    'zuraffa_agent_ios': ['ios'],
    'zuraffa_agent_macos': ['macos'],
  };
  packages.forEach((name, meta) {
    final deps = List<String>.from((meta as Map)['deps'] as List);
    if (!deps.contains('zuraffa_agent')) {
      failures[name] = 'missing zuraffa_agent dependency';
    }
    final platforms = List<String>.from(meta['pluginPlatforms'] as List);
    final expected = expectedPlatforms[name];
    if (expected != null) {
      for (final other in expectedPlatforms.keys) {
        if (other != name && platforms.contains(other)) {
          failures[name] = 'declares foreign platform $other';
        }
      }
      if (platforms.isEmpty) failures[name] = 'declares no platform';
    }
  });
  return failures;
}
