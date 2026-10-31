// Dependency freshness gate — issue #114 AC-1 ("Weekly cron job:
// `dart pub outdated --no-dev-dependencies` failing on majors-behind").
//
// Wraps `dart pub outdated --no-dev-dependencies --json` and turns the
// report into a policy verdict:
//
//   DIRECT dependency behind a MAJOR version  → exit 1. The package
//   declares it, so widening the constraint is this repo's job.
//
//   TRANSITIVE dependency behind a MAJOR      → ::warning annotation
//   only. A weekly alarm that is permanently red gets ignored;
//   transitive majors surface here and via Dependabot / osv-scanner
//   advisories without blocking.
//
//   Current version affected by a pub advisory → ::warning annotation.
//
// The weekly cron (`.github/workflows/dependency-freshness.yml`) runs
// this tool; the majors-behind policy is unit-tested in
// test/dependency_hygiene_test.dart.
//
// Usage:
//   dart run tool/check_dependency_freshness.dart
//
// Exit codes: 0 = no direct dependency is majors-behind, 1 = at least
// one direct dependency is behind its latest major, 2 = the underlying
// `dart pub outdated` invocation itself failed.
library;

import 'dart:convert';
import 'dart:io';

/// The MAJOR component of [version] (build/prerelease metadata ignored).
int majorOf(String version) {
  final core = version.split('+').first.split('-').first;
  return int.tryParse(core.split('.').first) ?? 0;
}

/// True when [latest] is a higher MAJOR version than [current]. Null or
/// empty inputs (package not locked / no latest release) are never
/// "behind".
bool isMajorBehind(String? current, String? latest) {
  if (current == null || latest == null) return false;
  if (current.isEmpty || latest.isEmpty) return false;
  return majorOf(latest) > majorOf(current);
}

/// The `{"version": ...}` payload of an outdated entry, or null.
String? _versionOf(dynamic ver) {
  if (ver is Map<String, dynamic>) {
    final v = ver['version'];
    if (v is String) return v;
  }
  return null;
}

/// Package entries in the `dart pub outdated --json` [report] that are
/// majors-behind, formatted `name: current -> latest` and filtered to
/// [kinds] (`direct`, `transitive`). Discontinued packages are skipped:
/// their `latest` is frozen upstream, the bump is not actionable.
List<String> majorsBehind(
  Map<String, dynamic> report, {
  List<String> kinds = const ['direct', 'transitive'],
}) {
  final packages = report['packages'];
  if (packages is! List<Object?>) return const [];
  final failing = <String>[];
  for (final entry in packages) {
    if (entry is! Map<String, dynamic>) continue;
    if (entry['isDiscontinued'] == true) continue;
    final kind = entry['kind'];
    if (kind is! String || !kinds.contains(kind)) continue;
    final name = entry['package'];
    if (name is! String) continue;
    final current = _versionOf(entry['current']);
    final latest = _versionOf(entry['latest']);
    if (!isMajorBehind(current, latest)) continue;
    failing.add('$name: $current -> $latest');
  }
  return failing;
}

/// Package names in the [report] whose CURRENT locked version pub flags
/// as affected by an advisory.
List<String> advisoryAffected(Map<String, dynamic> report) {
  final packages = report['packages'];
  if (packages is! List<Object?>) return const [];
  final flagged = <String>[];
  for (final entry in packages) {
    if (entry is! Map<String, dynamic>) continue;
    if (entry['isCurrentAffectedByAdvisory'] != true) continue;
    final name = entry['package'];
    if (name is! String) continue;
    flagged.add(name);
  }
  return flagged;
}

Future<void> main() async {
  final proc = await Process.run('dart', const [
    'pub',
    'outdated',
    '--no-dev-dependencies',
    '--json',
  ]);
  if (proc.exitCode != 0) {
    stderr.write(proc.stderr);
    exit(2);
  }
  final report = jsonDecode(proc.stdout as String) as Map<String, dynamic>;

  final direct = majorsBehind(report, kinds: ['direct']);
  final transitive = majorsBehind(report, kinds: ['transitive']);
  final advisories = advisoryAffected(report);

  for (final line in transitive) {
    stdout.writeln('::warning::transitive dependency majors-behind: $line');
  }
  for (final line in advisories) {
    stdout.writeln(
      '::warning::current version affected by a pub advisory: $line',
    );
  }

  if (direct.isEmpty) {
    stdout.writeln(
      'dependency freshness: OK — no direct dependency is behind its '
      'latest major version '
      '(${transitive.length} transitive majors-behind reported as '
      'warnings)',
    );
    return;
  }
  stderr.writeln(
    'dependency freshness: ${direct.length} direct dependency(ies) '
    'behind the latest MAJOR:',
  );
  for (final line in direct) {
    stderr.writeln('  - $line');
  }
  exit(1);
}
