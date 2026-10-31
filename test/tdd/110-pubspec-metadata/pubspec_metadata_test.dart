// Issue #110 — pubspec metadata acceptance tests.
//
// Encodes the pub.dev metadata contract agreed in
// https://github.com/arrrrny/zuraffa_agent/issues/110: a versioned package
// that is discoverable (`topics`) and cross-linked (`repository`,
// `issue_tracker`, `homepage`, `documentation`), with an honest
// `executables` audit (no phantom CLI entries).
//
// This test is "honest red" against a pubspec that lacks the metadata: it
// fails through assertions, never through load errors. Turning it green is
// the fix for issue #110.

library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Acceptance criterion "Add `version: 0.x.y` (semver) — required for any
/// future `pub publish`": the version line must exist and be valid semver.
/// (The exact release number is owned by the fleet's mono-release policy,
/// not by this test — pub only requires a valid semver here.)
const String _semver =
    r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$';

/// The exactly-five topics agreed in issue #110 for pub.dev discoverability.
const List<String> _agreedTopics = <String>[
  'agent',
  'llm',
  'mcp',
  'ai',
  'zuraffa',
];

YamlMap _loadPubspec() =>
    loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

void main() {
  final YamlMap pubspec = _loadPubspec();

  test('pubspec declares a semver version (issue #110)', () {
    final version = pubspec['version'];
    expect(
      version,
      isNotNull,
      reason:
          'pubspec.yaml has no version line — the package cannot be '
          'versioned, published, or pinned downstream',
    );
    expect(
      RegExp(_semver).hasMatch(version.toString()),
      isTrue,
      reason: 'version must be valid semver, got: $version',
    );
  });

  test('pubspec cross-links repository and issue_tracker (issue #110)', () {
    expect(
      pubspec['repository'],
      'https://github.com/arrrrny/zuraffa_agent',
      reason: 'repository is required for cross-referencing (issue #110)',
    );
    expect(
      pubspec['issue_tracker'],
      'https://github.com/arrrrny/zuraffa_agent/issues',
      reason: 'issue_tracker is required for cross-referencing (issue #110)',
    );
  });

  test('pubspec declares homepage and documentation (issue #110)', () {
    // Same two-predicate URL-shape check the documentation field gets
    // below — "must be a URL" is hasScheme + hasAuthority, so a future
    // typo like `homepage: zuraffa` cannot pass silently
    // (review finding 3 — symmetry).
    final Uri? homepage = Uri.tryParse(pubspec['homepage'].toString());
    expect(
      homepage?.hasScheme ?? false,
      isTrue,
      reason: 'homepage must be a URL, got: ${pubspec['homepage']}',
    );
    expect(
      homepage?.hasAuthority ?? false,
      isTrue,
      reason: 'homepage must point at a host, got: ${pubspec['homepage']}',
    );
    expect(
      pubspec['homepage'],
      isNotNull,
      reason: 'homepage is required by issue #110',
    );
    expect(
      pubspec['documentation'],
      isNotNull,
      reason:
          'documentation is required by issue #110 — '
          'the zuraffa family convention points it at the repo README',
    );
    // Uri.isAbsolute would be the wrong predicate here: Dart treats any URI
    // carrying a fragment (like the family-convention ".../#readme") as
    // non-absolute. "Must be a URL" is exactly hasScheme + hasAuthority.
    final Uri? documentation = Uri.tryParse(
      pubspec['documentation'].toString(),
    );
    expect(
      documentation?.hasScheme ?? false,
      isTrue,
      reason: 'documentation must be a URL, got: $documentation',
    );
    expect(
      documentation?.hasAuthority ?? false,
      isTrue,
      reason: 'documentation must point at a host, got: $documentation',
    );
  });

  test('pubspec topics carry the agreed discoverability set (issue #110)', () {
    final Set<String> topics =
        (pubspec['topics'] as YamlList?)
            ?.map((final t) => t.toString())
            .toSet() ??
        <String>{};
    expect(
      topics,
      containsAll(_agreedTopics),
      reason: 'every topic agreed in issue #110 must be declared',
    );
    expect(
      topics,
      hasLength(_agreedTopics.length),
      reason:
          'topics must be exactly the agreed issue #110 set '
          '($_agreedTopics), got: $topics',
    );
  });

  test(
    'executables audit: declared entries resolve to bin/ scripts (#110)',
    () {
      final YamlMap? executables = pubspec['executables'] as YamlMap?;
      final Directory binDir = Directory('bin');
      // Test for actual Dart entry points, not the bare directory: an empty
      // bin/ (or one holding only non-Dart files) declares nothing, so it
      // must not fail the audit (review finding 1 — false positive).
      final bool hasDartEntryPoints =
          binDir.existsSync() &&
          binDir.listSync().whereType<File>().any(
            (final f) => f.path.endsWith('.dart'),
          );
      if (executables == null) {
        // Issue #110 audit outcome: no CLI entry points today, so the
        // executables block is correctly absent — but the moment a bin/
        // script lands, it must be declared, otherwise `pub publish` warns
        // and the CLI stays undiscoverable. This keeps the audit honest.
        expect(
          hasDartEntryPoints,
          isFalse,
          reason:
              'bin/ entry points exist but are not declared under '
              'executables: (issue #110 audit)',
        );
        return;
      }
      // executables: is declared, so bin/ must exist too — fail cleanly
      // instead of throwing PathNotFoundException from listSync()
      // (review finding 2 — unhandled load error).
      if (!binDir.existsSync()) {
        fail('executables are declared but bin/ does not exist');
      }
      final Set<String> binScripts = binDir
          .listSync()
          .whereType<File>()
          .map((final f) => f.uri.pathSegments.last)
          .toSet();
      for (final MapEntry<dynamic, dynamic> entry in executables.entries) {
        final String script = (entry.value ?? entry.key).toString();
        expect(
          binScripts,
          contains('$script.dart'),
          reason: 'executables entry <${entry.key}> has no bin/$script.dart',
        );
      }
    },
  );
}
