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
  return [
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  ];
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

/// Whether a `.gitignore` pattern would ignore the repository's ROOT
/// `pubspec.lock` — the #109 violation this suite guards against.
///
/// Nested-scoped patterns (e.g. `packages/**/pubspec.lock`) cannot
/// match the root file and are exempt: they express the documented
/// policy that the federated subpackages' lockfiles stay uncommitted
/// until they get a CI lane (ARCHITECTURE.md).
bool _patternIgnoresRootLockfile(String pattern) {
  // Root-anchored (`/pubspec.lock`) still targets the root file.
  final p = pattern.startsWith('/') ? pattern.substring(1) : pattern;
  // A leading `**/` matches in every directory, the repository root
  // included (`**/pubspec.lock`, `**/*.lock`, …).
  if (p.startsWith('**/')) return _globMatches(p.substring(3), 'pubspec.lock');
  // No directory component: matches at every level — root included
  // (`pubspec.lock`, `*.lock`, …).
  if (!p.contains('/')) return _globMatches(p, 'pubspec.lock');
  // Scoped to subdirectories — cannot match the root lockfile.
  return false;
}

/// Minimal single-segment glob match (`*` and `?`) against a file name.
bool _globMatches(String pattern, String name) {
  final source = RegExp.escape(
    pattern,
  ).replaceAll(r'\*', '.*').replaceAll(r'\?', '.');
  return RegExp('^$source\$').hasMatch(name);
}

/// Matches a workflow's `run:` key — inline form (`run: dart pub get`)
/// and list-item form (`- run: …`).
final RegExp _runLineRe = RegExp(r'^\s*(?:-\s*)?run:\s*(.*)$');

/// Command lines of a workflow file that actually invoke `pub get`,
/// each returned as `'<line>: <command text>'`.
///
/// Only real command lines count: an inline `run:` value, or a line
/// inside a `run: |` / `run: >` block scalar. A `- name: pub get` step
/// label or prose mentioning `pub get` (an `if:` expression, a
/// mid-line comment) is not a command and never becomes a false
/// offender — but every line that IS a `pub get` invocation still has
/// to carry `--enforce-lockfile` on that same line.
List<String> _pubGetRunLines(List<String> lines) {
  final found = <String>[];
  var keyIndent = -1; // indent of a `run: |`/`run: >` key awaiting content
  var contentIndent = -1; // indent of the open block scalar's content
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    final indent = line.length - line.trimLeft().length;

    if (trimmed.isEmpty) {
      // Blank lines never establish or end a block scalar's content.
      if (keyIndent >= 0 || contentIndent >= 0) continue;
    }

    if (keyIndent >= 0) {
      if (indent <= keyIndent) {
        keyIndent = -1; // block scalar had no content — reprocess below
      } else {
        contentIndent = indent; // first content line fixes the block indent
        keyIndent = -1;
      }
    }
    if (contentIndent >= 0) {
      if (indent >= contentIndent) {
        // Command line inside a `run:` block scalar.
        if (!trimmed.startsWith('#') && trimmed.contains('pub get')) {
          found.add('${i + 1}: $trimmed');
        }
        continue;
      }
      contentIndent = -1; // block scalar ended — reprocess below
    }

    if (trimmed.startsWith('#')) continue;
    final run = _runLineRe.firstMatch(line);
    if (run == null) continue; // name:, if:, prose — not a command line
    final value = run.group(1)!.trim();
    if (value.startsWith('|') || value.startsWith('>')) {
      keyIndent = indent; // block scalar: commands follow on deeper lines
      continue;
    }
    if (value.contains('pub get')) found.add('${i + 1}: $value');
  }
  return found;
}

void main() {
  group('supply-chain integrity (issue #109)', () {
    test('zuraffa is resolved through an auditable channel', () {
      final block = _yamlEntryBlock(
        _readLines('pubspec.yaml'),
        'dependencies',
        'zuraffa',
      );
      expect(
        block,
        isNotNull,
        reason: 'pubspec.yaml must declare zuraffa under dependencies:',
      );
      final b = block!;
      if (b.contains('git:')) {
        // Unpublished-dependency fallback: full SHA or release tag only.
        final ref = RegExp(r'ref:\s*(\S+)').firstMatch(b)?.group(1);
        expect(
          ref,
          isNotNull,
          reason: 'a git dependency must pin a ref (issue #109)',
        );
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
        final constraint = RegExp(
          r'^\s*zuraffa:\s*(\S+)\s*$',
          multiLine: true,
        ).firstMatch(b)?.group(1);
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

    test('pubspec.lock is committed, not git-ignored, and resolves '
        'zuraffa', () {
      final offenders = _readLines('.gitignore')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .where(_patternIgnoresRootLockfile)
          .toList();
      expect(
        offenders,
        isEmpty,
        reason:
            'pubspec.lock must not be git-ignored (issue #109): an '
            'uncommitted lockfile means non-reproducible builds and no '
            'auditable resolved graph',
      );
      // The exemption contract: a nested-scoped ignore stays
      // representable (ARCHITECTURE.md: subpackage lockfiles are
      // uncommitted until they get a CI lane), while every pattern
      // that would swallow the ROOT lockfile remains a violation.
      expect(
        _patternIgnoresRootLockfile('packages/**/pubspec.lock'),
        isFalse,
        reason: 'a nested-scoped lockfile ignore must remain expressible',
      );
      for (final rootScoped in [
        'pubspec.lock',
        '/pubspec.lock',
        '**/pubspec.lock',
        '*.lock',
      ]) {
        expect(
          _patternIgnoresRootLockfile(rootScoped),
          isTrue,
          reason:
              '"$rootScoped" matches the root pubspec.lock and must '
              'stay forbidden (issue #109)',
        );
      }

      final lockFile = File('$repoRoot/pubspec.lock');
      expect(
        lockFile.existsSync(),
        isTrue,
        reason: 'pubspec.lock must be committed to the repository',
      );

      final block = _yamlEntryBlock(
        _readLines('pubspec.lock'),
        'packages',
        'zuraffa',
      );
      expect(
        block,
        isNotNull,
        reason:
            'the committed pubspec.lock must contain a resolved zuraffa entry',
      );
      expect(
        block!,
        contains('source: hosted'),
        reason: 'zuraffa must resolve from the published host',
      );
      expect(
        RegExp(r'sha256:\s*"[0-9a-f]{64}"').hasMatch(block),
        isTrue,
        reason:
            'the lockfile zuraffa entry must carry the content sha256 — '
            'that checksum is the auditable supply-chain pin (issue #109)',
      );
    });

    test('committed lockfile satisfies the pubspec constraint', () {
      final depBlock = _yamlEntryBlock(
        _readLines('pubspec.yaml'),
        'dependencies',
        'zuraffa',
      )!;
      final constraint = RegExp(
        r'^\s*zuraffa:\s*(\S+)\s*$',
        multiLine: true,
      ).firstMatch(depBlock)?.group(1);
      if (constraint == null || !constraint.startsWith('^')) {
        // Git-pinned or exact-pinned variant: version fit is enforced by
        // the pub resolver itself; nothing extra to check here.
        return;
      }
      final lockBlock = _yamlEntryBlock(
        _readLines('pubspec.lock'),
        'packages',
        'zuraffa',
      )!;
      final resolved = RegExp(
        r'version:\s*"([^"]+)"',
      ).firstMatch(lockBlock)?.group(1);
      expect(
        resolved,
        isNotNull,
        reason: 'lockfile zuraffa entry must record a version',
      );
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
        for (final command in _pubGetRunLines(workflow.readAsLinesSync())) {
          pubGetSteps++;
          if (!command.contains('--enforce-lockfile')) {
            offenders.add('${workflow.uri.pathSegments.last}:$command');
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
        RegExp(
          '^#+.*dependenc',
          multiLine: true,
          caseSensitive: false,
        ).hasMatch(arch),
        isTrue,
        reason:
            'ARCHITECTURE.md must carry a dependency-strategy section '
            '(issue #109)',
      );
      expect(
        arch,
        contains('pubspec.lock'),
        reason: 'the strategy must cover the committed lockfile',
      );
      expect(
        arch,
        contains('--enforce-lockfile'),
        reason: 'the strategy must cover CI lockfile enforcement',
      );
    });
  });
}
