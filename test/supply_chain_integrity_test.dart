// Supply-chain integrity acceptance tests for the dependency graph
// (issue #109 — pin `zuraffa`, commit `pubspec.lock`, enforce both in CI).
//
// These are meta-tests: they assert on the repository's dependency
// surface (pubspec.yaml, pubspec.lock, .gitignore, CI workflows,
// ARCHITECTURE.md) rather than on runtime behavior, so the #109
// acceptance criteria are executable and cannot silently regress:
//
//   1. `zuraffa` resolves through an auditable channel — hosted on
//      pub.dev behind a caret range (the issue's preferred end state
//      now that the package is published), or a git ref pinned to a
//      full commit SHA / release tag (never a moving branch).
//   2. `pubspec.lock` is committed: present, not git-ignored, and it
//      carries the resolved `zuraffa` entry (version + sha256).
//   3. The committed lockfile actually satisfies the pubspec
//      constraint — the check that catches a phantom floor like
//      `^7.3.2` before that version exists on the host.
//   4. Every CI `pub get` runs with `--enforce-lockfile`, so a
//      pubspec.yaml/lockfile drift fails the build instead of
//      silently re-resolving.
//   5. ARCHITECTURE.md documents the dependency strategy.
import 'dart:io';

import 'package:test/test.dart';

/// `dart test` runs with the package root as CWD.
final String repoRoot = Directory.current.path;

List<String> _readLines(String relativePath) =>
    File('$repoRoot/$relativePath').readAsStringSync().split('\n');

/// Returns the raw YAML block of `  child:` under the top-level
/// `parent:` key (two-space indentation level), or null when absent.
///
/// Works for both pubspec.yaml sections (`dependencies:` → `zuraffa:`)
/// and pubspec.lock sections (`packages:` → `zuraffa:`).
String? _yamlEntryBlock(List<String> lines, String parent, String child) {
  final parentRe = RegExp('^$parent:\$');
  final childRe = RegExp('^  $child:');
  final nextKeyRe = RegExp('^  \\S');
  var inParent = false;
  final block = <String>[];
  for (final line in lines) {
    if (parentRe.hasMatch(line)) {
      inParent = true;
      continue;
    }
    if (!inParent) continue;
    if (line.isNotEmpty && !line.startsWith(' ')) break; // left `parent`
    if (childRe.hasMatch(line)) {
      block.add(line);
      continue;
    }
    if (block.isNotEmpty) {
      if (nextKeyRe.hasMatch(line)) break; // reached the next sibling
      block.add(line);
    }
  }
  return block.isEmpty ? null : block.join('\n');
}

List<int>? _parseVersion(String input) {
  final m = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(input);
  if (m == null) return null;
  return [int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!)];
}

int _compare(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

/// Minimal caret/exact constraint check (`^a.b.c` or `a.b.c`).
bool _versionSatisfies(String version, String constraint) {
  final v = _parseVersion(version);
  if (v == null) return false;
  final c = constraint.trim();
  if (c.startsWith('^')) {
    final floor = _parseVersion(c.substring(1));
    if (floor == null) return false;
    if (_compare(v, floor) < 0) return false;
    // Dart caret semantics: ^0.y.z admits only 0.y.*, ^0.0.z only 0.0.z.
    if (floor[0] > 0) return v[0] == floor[0];
    if (floor[1] > 0) return v[0] == 0 && v[1] == floor[1];
    return v[0] == 0 && v[1] == 0 && v[2] == floor[2];
  }
  final exact = _parseVersion(c);
  return exact != null && _compare(v, exact) == 0;
}

void main() {
  group('supply-chain integrity (issue #109)', () {
        test('zuraffa is resolved through an auditable channel', () {
          final block = _yamlEntryBlock(_readLines('pubspec.yaml'), 'dependencies', 'zuraffa');
          expect(
            block,
            isNotNull,
            reason: 'pubspec.yaml must declare zuraffa under dependencies:',
          );
          final b = block!;
          if (b.contains('git:')) {
            // Unpublished-dependency fallback: full SHA or release tag only.
            final ref = RegExp(r'ref:\s*(\S+)').firstMatch(b)?.group(1);
            expect(ref, isNotNull,
                reason: 'a git dependency must pin a ref (issue #109)');
            final isFullSha = RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(ref!);
            final isReleaseTag = RegExp(r'^v\d').hasMatch(ref);
            expect(
              isFullSha || isReleaseTag,
              isTrue,
              reason:
                  'git ref must be a full commit SHA or a release tag, '
                  'never a moving branch tip (got: $ref)',
            );
          } else {
            // Preferred end state: published on pub.dev behind a caret
            // range (or an exact pin — also auditable).
            final constraint =
                RegExp(r'^\s*zuraffa:\s*(\S+)\s*$', multiLine: true)
                    .firstMatch(b)
                    ?.group(1);
            expect(
              constraint,
              isNotNull,
              reason: 'hosted zuraffa entry must carry a version constraint',
            );
            expect(
              RegExp(r'^(\^\d+\.\d+\.\d+|\d+\.\d+\.\d+)$').hasMatch(constraint!),
              isTrue,
              reason:
                  'zuraffa constraint "$constraint" must be a caret range '
                  'or an exact version, not a loose range (issue #109)',
            );
          }
        });

    test('pubspec.lock is committed, not git-ignored, and resolves zuraffa',
        () {
      final offenders = _readLines('.gitignore')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .where((line) =>
              line == 'pubspec.lock' ||
              line == '/pubspec.lock' ||
              line == '**/pubspec.lock' ||
              line == '*.lock')
          .toList();
      expect(
        offenders,
        isEmpty,
        reason:
            'pubspec.lock must not be git-ignored (issue #109): an '
            'uncommitted lockfile means non-reproducible builds and no '
            'auditable resolved graph',
      );

      final lockFile = File('$repoRoot/pubspec.lock');
      expect(
        lockFile.existsSync(),
        isTrue,
        reason: 'pubspec.lock must be committed to the repository',
      );

      final block = _yamlEntryBlock(_readLines('pubspec.lock'), 'packages', 'zuraffa');
      expect(
        block,
        isNotNull,
        reason: 'the committed pubspec.lock must contain a resolved zuraffa entry',
      );
      expect(block!, contains('source: hosted'),
          reason: 'zuraffa must resolve from the published host');
      expect(
        RegExp(r'sha256:\s*"[0-9a-f]{64}"').hasMatch(block),
        isTrue,
        reason:
            'the lockfile zuraffa entry must carry the content sha256 — '
            'that checksum is the auditable supply-chain pin (issue #109)',
      );
    });

    test('committed lockfile satisfies the pubspec constraint', () {
      final depBlock = _yamlEntryBlock(_readLines('pubspec.yaml'), 'dependencies', 'zuraffa')!;
      final constraint =
          RegExp(r'^\s*zuraffa:\s*(\S+)\s*$', multiLine: true)
              .firstMatch(depBlock)
              ?.group(1);
      if (constraint == null || !constraint.startsWith('^')) {
        // Git-pinned or exact-pinned variant: version fit is enforced by
        // the pub resolver itself; nothing extra to check here.
        return;
      }
      final lockBlock =
          _yamlEntryBlock(_readLines('pubspec.lock'), 'packages', 'zuraffa')!;
      final resolved =
          RegExp(r'version:\s*"([^"]+)"').firstMatch(lockBlock)?.group(1);
      expect(resolved, isNotNull,
          reason: 'lockfile zuraffa entry must record a version');
      expect(
        _versionSatisfies(resolved!, constraint),
        isTrue,
        reason:
            'pubspec.lock resolves zuraffa $resolved, which does not '
            'satisfy the pubspec constraint "$constraint" — pubspec.yaml '
            'and pubspec.lock are out of sync (or the constraint floor '
            'has no published version yet)',
      );
    });

    test('every CI pub get runs with --enforce-lockfile', () {
      final workflows = Directory('$repoRoot/.github/workflows')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'))
          .toList();
      expect(workflows, isNotEmpty, reason: 'expected CI workflow files');

      var pubGetSteps = 0;
      final offenders = <String>[];
      for (final workflow in workflows) {
        final lines = workflow.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('pub get')) continue;
          // Comments that merely mention `pub get` are not steps.
          if (lines[i].trim().startsWith('#')) continue;
          pubGetSteps++;
          if (!lines[i].contains('--enforce-lockfile')) {
            offenders.add(
                '${workflow.uri.pathSegments.last}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      expect(
        pubGetSteps,
        greaterThan(0),
        reason: 'expected at least one `pub get` step across CI workflows',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'every CI `pub get` must run with --enforce-lockfile so a '
            'pubspec.yaml/lockfile drift fails the build instead of '
            'silently re-resolving (issue #109)\n  '
            '${offenders.join('\n  ')}',
      );
    });

    test('ARCHITECTURE.md documents the dependency strategy', () {
      final arch = File('$repoRoot/ARCHITECTURE.md').readAsStringSync();
      expect(
        RegExp('^#+.*dependenc', multiLine: true, caseSensitive: false)
            .hasMatch(arch),
        isTrue,
        reason:
            'ARCHITECTURE.md must carry a dependency-strategy section '
            '(issue #109)',
      );
      expect(arch, contains('pubspec.lock'),
          reason: 'the strategy must cover the committed lockfile');
      expect(arch, contains('--enforce-lockfile'),
          reason: 'the strategy must cover CI lockfile enforcement');
    });
  });
}
