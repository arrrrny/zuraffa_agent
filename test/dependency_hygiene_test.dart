// Dependency-hygiene guarantees — issue #114 ("Dependency freshness +
// advisory scanning + Dependabot").
//
// These tests encode the acceptance criteria as executable checks so the
// CI/dependabot wiring cannot silently regress:
//
//   1. pubspec.lock is committed — Dependabot and osv-scanner advisories
//      are only meaningful against a fixed, reviewable resolution.
//   2. `.github/dependabot.yml` keeps the `pub` ecosystem on a weekly
//      schedule.
//   3. A weekly cron runs `dart pub outdated --no-dev-dependencies` and
//      FAILS when a direct dependency is behind its latest major version
//      (the gate lives in `tool/check_dependency_freshness.dart`).
//   4. `pana` runs on pull requests as a NON-BLOCKING advisory so the
//      pub.dev score is visible without gating merges.
//   5. `osv-scanner` scans the committed `pubspec.lock` (advisory).
//   6. `dartdoc: ^8.x` sits in dev_dependencies.
//
// File-shape tests only here — they read the committed repo state, not the
// network, so they stay fast and hermetic under `dart test -j 2`.

import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_dependency_freshness.dart'
    show isMajorBehind, majorsBehind;

/// All committed workflow files under `.github/workflows/`.
List<File> workflowFiles() {
  final dir = Directory('.github/workflows');
  if (!dir.existsSync()) return const [];
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'))
      .toList();
}

/// The `dev_dependencies:` section body of [pubspec], or null when the
/// section is absent. Tolerates blank lines inside the section.
String? devDependenciesSection(String pubspec) {
  final lines = pubspec.split('\n');
  final start = lines.indexWhere((l) => l.trim() == 'dev_dependencies:');
  if (start < 0) return null;
  final body = <String>[];
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.isEmpty) {
      body.add(line);
      continue;
    }
    if (line.startsWith(' ') || line.startsWith('\t')) {
      body.add(line);
    } else {
      break;
    }
  }
  return body.join('\n');
}

/// Every cron expression declared in [content] (5 space-separated fields).
List<String> cronsOf(String content) {
  final crons = <String>[];
  for (final line in content.split('\n')) {
    final idx = line.indexOf('cron:');
    if (idx < 0) continue;
    var expr = line.substring(idx + 'cron:'.length).trim();
    while (expr.isNotEmpty && (expr.startsWith('"') || expr.startsWith("'"))) {
      expr = expr.substring(1);
    }
    while (expr.isNotEmpty && (expr.endsWith('"') || expr.endsWith("'"))) {
      expr = expr.substring(0, expr.length - 1);
    }
    if (expr.split(RegExp(r'\s+')).length == 5) crons.add(expr);
  }
  return crons;
}

/// A 5-field cron is weekly when the day-of-week field is pinned
/// (`*` in the last field means "every day", i.e. daily at most).
bool isWeeklyCron(String expr) {
  final fields = expr.split(RegExp(r'\s+'));
  if (fields.length != 5) return false;
  // exactly one day-of-week token: a single 0-7 digit (no list/range/step)
  return RegExp(r'^[0-7]$').hasMatch(fields[4]);
}

void main() {
  group('issue #114 — dependency freshness + advisory scanning', () {
    test('pubspec.lock is committed (advisories need a lockfile)', () {
      final lock = File('pubspec.lock');
      expect(
        lock.existsSync(),
        isTrue,
        reason:
            'pubspec.lock must be committed so Dependabot and osv-scanner '
            'advisories resolve against a fixed, reviewable version set',
      );
      final ignore = File('.gitignore').readAsStringSync();
      expect(
        ignore,
        isNot(matches(RegExp(r'^/?pubspec\.lock\s*$', multiLine: true))),
        reason: '.gitignore must not exclude pubspec.lock',
      );
    });

    test('dependabot keeps the pub ecosystem fresh weekly', () {
      final file = File('.github/dependabot.yml');
      expect(
        file.existsSync(),
        isTrue,
        reason: '.github/dependabot.yml is missing',
      );
      final config = file.readAsStringSync();
      expect(config, contains('version: 2'));
      expect(
        config,
        matches(RegExp(r'package-ecosystem:\s*"?pub"?\s*$', multiLine: true)),
        reason: 'dependabot must target the pub ecosystem',
      );
      expect(
        config,
        matches(RegExp(r'interval:\s*"?weekly"?\s*$', multiLine: true)),
        reason: 'dependabot schedule must be weekly',
      );
    });

    test('weekly cron runs dart pub outdated --no-dev-dependencies', () {
      final freshness = workflowFiles().where((f) {
        final c = f.readAsStringSync();
        return c.contains('pub outdated') &&
            c.contains('--no-dev-dependencies') &&
            c.contains('schedule:');
      }).toList();
      expect(
        freshness,
        isNotEmpty,
        reason:
            'no scheduled workflow runs '
            '`dart pub outdated --no-dev-dependencies`',
      );
      final weekly = freshness.any(
        (f) => cronsOf(f.readAsStringSync()).any(isWeeklyCron),
      );
      expect(
        weekly,
        isTrue,
        reason:
            'the pub-outdated workflow must carry a weekly cron '
            '(day-of-week field pinned), not a daily or monthly one',
      );
    });

    test('majors-behind gate tool exists and fails on majors-behind', () {
      final tool = File('tool/check_dependency_freshness.dart');
      expect(
        tool.existsSync(),
        isTrue,
        reason:
            'tool/check_dependency_freshness.dart is missing — the '
            'pub-outdated cron has no majors-behind gate',
      );
      final source = tool.readAsStringSync();
      expect(source, contains('--no-dev-dependencies'));
      expect(source, contains('major'));
    });

    test('pana runs as a non-blocking advisory on pull requests', () {
      final advisory = workflowFiles().where((f) {
        final c = f.readAsStringSync();
        return c.contains('pull_request') &&
            c.contains('pana') &&
            c.contains('continue-on-error: true');
      }).toList();
      expect(
        advisory,
        isNotEmpty,
        reason:
            'expected a pull_request workflow running pana with '
            'continue-on-error: true (pub.dev scoring parity, advisory)',
      );
    });

    test('osv-scanner scans the committed pubspec.lock', () {
      final scanners = workflowFiles().where((f) {
        final c = f.readAsStringSync();
        return c.contains('osv-scanner') && c.contains('pubspec.lock');
      }).toList();
      expect(
        scanners,
        isNotEmpty,
        reason: 'expected an osv-scanner step over pubspec.lock',
      );
    });

    test('dartdoc is a dev dependency (issue #114 asked for ^8.x)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final dev = devDependenciesSection(pubspec);
      expect(dev, isNotNull, reason: 'no dev_dependencies section found');
      expect(
        dev!,
        matches(RegExp(r'^\s*dartdoc:\s*\^(8|9)\.\d', multiLine: true)),
        reason:
            'dartdoc missing from dev_dependencies. The issue asked '
            'for ^8.x, but no dartdoc <=8.x resolves here: dartdoc <=8.x '
            'needs analyzer <=7.x while zuraffa 7.3.0 pins analyzer '
            '^14.4.0 — ^9.0.11 is the documented deviation.',
      );
    });
  });

  group('majors-behind policy (tool/check_dependency_freshness.dart)', () {
    test('isMajorBehind compares MAJOR components only', () {
      expect(isMajorBehind('1.2.3', '2.0.0'), isTrue);
      expect(isMajorBehind('2.0.0', '2.1.0'), isFalse);
      expect(isMajorBehind('1.9.9', '1.10.0'), isFalse);
      expect(isMajorBehind('7.3.0', '7.3.0'), isFalse);
      expect(isMajorBehind('3.0.0+hotfix2', '4.0.0'), isTrue);
      expect(isMajorBehind('1.0.0-beta', '2.0.0'), isTrue);
    });

    test('null or empty versions are never majors-behind', () {
      expect(isMajorBehind(null, '2.0.0'), isFalse);
      expect(isMajorBehind('1.0.0', null), isFalse);
      expect(isMajorBehind('', '2.0.0'), isFalse);
      expect(isMajorBehind('1.0.0', ''), isFalse);
    });

    test('majorsBehind filters by kind and skips discontinued', () {
      final report = <String, dynamic>{
        'packages': [
          {
            'package': 'a_direct',
            'kind': 'direct',
            'current': {'version': '1.0.0'},
            'latest': {'version': '2.0.0'},
          },
          {
            'package': 'b_transitive',
            'kind': 'transitive',
            'current': {'version': '1.0.0'},
            'latest': {'version': '2.0.0'},
          },
          {
            'package': 'c_discontinued',
            'kind': 'direct',
            'isDiscontinued': true,
            'current': {'version': '1.0.0'},
            'latest': {'version': '2.0.0'},
          },
          {
            'package': 'd_current',
            'kind': 'direct',
            'current': {'version': '2.0.0'},
            'latest': {'version': '2.0.0'},
          },
        ],
      };
      expect(majorsBehind(report, kinds: ['direct']), [
        'a_direct: 1.0.0 -> 2.0.0',
      ]);
      expect(majorsBehind(report, kinds: ['transitive']), [
        'b_transitive: 1.0.0 -> 2.0.0',
      ]);
      expect(majorsBehind(report), hasLength(2));
    });

    test('majorsBehind tolerates malformed report shapes', () {
      expect(majorsBehind(<String, dynamic>{}), isEmpty);
      expect(majorsBehind(<String, dynamic>{'packages': null}), isEmpty);
      expect(
        majorsBehind(<String, dynamic>{
          'packages': ['nope'],
        }),
        isEmpty,
      );
    });
  });
}
