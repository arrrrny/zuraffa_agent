// Third-party notices generator — issue #139 ("Generate
// `THIRD-PARTY-NOTICES` + write privacy policy / data residency docs").
//
// Parses the COMMITTED `pubspec.lock`, downloads every locked package's
// archive from its hosted URL (pub.dev), extracts the license file(s)
// from the tar.gz, and renders a deterministic, alphabetically sorted
// `THIRD_PARTY_NOTICES.txt` at the repo root.
//
// The output file is GENERATED — never hand-edit it. CI
// (`.github/workflows/pipeline.yml`, job `third-party-notices`)
// regenerates it on every pull request and fails when the committed file
// has drifted from the lockfile, so a dependency bump that forgets the
// notices cannot merge.
//
// Scope note: the file covers EVERY entry in `pubspec.lock` — direct
// main, direct dev and transitive alike. The lock alone cannot separate
// dev-only transitive closures from runtime ones, and over-inclusion is
// the legally safe direction for a notices file.
//
// Usage:
//   dart run tool/generate_third_party_notices.dart
//
// Exit codes: 0 = `THIRD_PARTY_NOTICES.txt` written; 1 = pubspec.lock
// missing or produced no packages; 2 = at least one license fetch failed
// after retries (nothing is written, so a partial notices file can never
// be committed — rerun the tool).
//
// Determinism: no timestamps, stable sort, stable wording — two runs over
// the same lockfile produce byte-identical output. Packages whose archive
// ships no license file render with an explicit UNKNOWN marker instead of
// being dropped silently.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

/// One entry of `pubspec.lock` as the generator consumes it.
class LockedPackage {
  const LockedPackage({
    required this.name,
    required this.version,
    required this.source,
    required this.hostedUrl,
    required this.dependency,
  });

  final String name;
  final String version;
  final String source; // hosted | git | path | sdk
  final String? hostedUrl; // e.g. https://pub.dev (hosted entries only)
  final String dependency; // direct main | direct dev | transitive
}

/// A package paired with its resolved license text (`null` = unresolved).
typedef PackageNotice = ({LockedPackage package, String? licenseText});

/// Parses the lockfile subset Dart's `pub` writes (2-space package keys,
/// 4-space fields, 6-space description children). Ignores comments, the
/// `sdks:` section and any unknown fields, and returns entries sorted by
/// package name.
List<LockedPackage> parseLock(String content) {
  final result = <LockedPackage>[];
  var name = '';
  var dependency = '';
  var source = '';
  var version = '';
  String? url;
  var inPackages = false;

  void flush() {
    if (name.isNotEmpty) {
      result.add(
        LockedPackage(
          name: name,
          version: version,
          source: source,
          hostedUrl: url,
          dependency: dependency.isEmpty ? 'transitive' : dependency,
        ),
      );
    }
    name = '';
    dependency = '';
    source = '';
    version = '';
    url = null;
  }

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trimRight();
    if (line.isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    if (indent == 0) {
      inPackages = line.trim() == 'packages:';
      if (!inPackages) flush();
      continue;
    }
    if (!inPackages) continue;
    final key = line.trim();
    if (indent == 2) {
      flush();
      name = key.endsWith(':') ? key.substring(0, key.length - 1) : key;
    } else if (indent == 4) {
      if (key.startsWith('dependency:')) {
        dependency = _unquote(key.substring('dependency:'.length).trim());
      } else if (key.startsWith('source:')) {
        source = key.substring('source:'.length).trim();
      } else if (key.startsWith('version:')) {
        version = _unquote(key.substring('version:'.length).trim());
      }
    } else if (indent == 6 && key.startsWith('url:')) {
      url = _unquote(key.substring('url:'.length).trim());
    }
  }
  flush();
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}

/// The pub archive endpoint of [hostedUrl] for [name] at [version].
String archiveUrlFor(String hostedUrl, String name, String version) {
  final base = hostedUrl.endsWith('/')
      ? hostedUrl.substring(0, hostedUrl.length - 1)
      : hostedUrl;
  return '$base/api/archives/$name-$version.tar.gz';
}

/// Extracts license files from a pub package archive (gzip-compressed tar).
///
/// Handles ustar (with prefix field), GNU longname (`typeflag L`) and pax
/// extended headers (`typeflag x`) so deep paths survive. Returns archive
/// path → text for every entry whose basename looks like a license file;
/// non-license files are ignored. Paths are kept whole (not basenames)
/// so a subpackage's auxiliary LICENSE cannot collide with the canonical
/// root one — [pickLicenseText] resolves the winner by path depth.
Future<Map<String, String>> extractLicenseFiles(List<int> tarGzBytes) async {
  final tarBytes = Uint8List.fromList(GZipCodec().decode(tarGzBytes));
  final licenses = <String, String>{};
  String? pendingName;
  var offset = 0;

  while (offset + 512 <= tarBytes.length) {
    final header = Uint8List.sublistView(tarBytes, offset, offset + 512);
    if (header.every((byte) => byte == 0)) break; // end-of-archive blocks

    final nameField = _tarString(header, 0, 100);
    final magic = _tarString(header, 257, 6);
    var fullName = nameField;
    if (magic.startsWith('ustar')) {
      final prefix = _tarString(header, 345, 155);
      if (prefix.isNotEmpty && nameField.isNotEmpty) {
        fullName = '$prefix/$nameField';
      }
    }
    final size =
        int.tryParse(_tarString(header, 124, 12).trim(), radix: 8) ?? 0;
    final typeflag = header.length > 156
        ? String.fromCharCode(header[156])
        : '0';
    final dataStart = offset + 512;
    final data = Uint8List.sublistView(
      tarBytes,
      dataStart,
      min(dataStart + size, tarBytes.length),
    );

    if (typeflag == 'L') {
      pendingName = _tarString(data, 0, data.length);
    } else if (typeflag == 'x' || typeflag == 'X') {
      final paxPath = _paxPathValue(utf8.decode(data, allowMalformed: true));
      if (paxPath != null) pendingName = paxPath;
    } else if (typeflag == '0' ||
        typeflag == '\x00' ||
        typeflag == ' ' ||
        typeflag.isEmpty) {
      final filePath = pendingName ?? fullName;
      pendingName = null;
      final basename = filePath.split('/').last;
      if (size > 0 && _isLicenseFileName(basename)) {
        licenses[filePath] = utf8.decode(data, allowMalformed: true);
      }
    } else {
      pendingName = null;
    }

    final paddedSize = ((size + 511) ~/ 512) * 512;
    offset = dataStart + paddedSize;
  }
  return licenses;
}

/// Priority order for choosing ONE canonical license file out of an
/// archive. Exact basenames win, then `startsWith` variants, then
/// alphabetical order as the final tie-break.
const _licensePriority = <String>[
  'LICENSE',
  'LICENSE.TXT',
  'LICENSE.MD',
  'LICENCE',
  'LICENCE.TXT',
  'LICENCE.MD',
  'COPYING',
  'COPYING.TXT',
  'COPYRIGHT',
  'NOTICE',
  'NOTICE.TXT',
  'UNLICENSE',
];

/// Picks the canonical license text out of [files] (an
/// `extractLicenseFiles` result keyed by archive path), or null when the
/// archive ships none. Ties are broken toward the SHALLOWEST path so a
/// vendored subpackage's auxiliary LICENSE cannot override the package's
/// root one, then alphabetically for determinism.
String? pickLicenseText(Map<String, String> files) {
  if (files.isEmpty) return null;
  bool scoreable(String path) => _isLicenseFileName(path.split('/').last);
  final candidates = files.keys.where(scoreable).toList();
  if (candidates.isEmpty) return null; // no license-named file → UNKNOWN
  int score(String path) {
    final upper = path.split('/').last.toUpperCase();
    final exact = _licensePriority.indexOf(upper);
    if (exact >= 0) return exact;
    for (var i = 0; i < _licensePriority.length; i++) {
      if (upper.startsWith(_licensePriority[i])) {
        return _licensePriority.length + i;
      }
    }
    return 2 * _licensePriority.length;
  }

  int depth(String path) => path.split('/').length;
  candidates.sort((a, b) {
    final byScore = score(a).compareTo(score(b));
    if (byScore != 0) return byScore;
    final byDepth = depth(a).compareTo(depth(b));
    if (byDepth != 0) return byDepth;
    return a.compareTo(b);
  });
  return files[candidates.first];
}

/// Best-effort SPDX-style label for a license body. Falls back to an
/// explicit `Custom (see text below)` — the verbatim text always ships
/// alongside the label, so a mislabel can be corrected by reading.
String licenseLabel(String text) {
  final t = text.toLowerCase();
  if (t.contains('gnu lesser general public license')) return 'LGPL';
  if (t.contains('apache license') || t.contains('apache 2.0')) {
    return 'Apache-2.0';
  }
  if (t.contains('boost software license')) return 'BSL-1.0';
  if (t.contains('gnu general public license')) {
    if (t.contains('version 3') || t.contains('gpl-3')) return 'GPL-3.0';
    if (t.contains('version 2') || t.contains('gpl-2')) return 'GPL-2.0';
    return 'GPL';
  }
  if (t.contains('mozilla public license')) return 'MPL-2.0';
  if (t.contains('permission is hereby granted, free of charge')) return 'MIT';
  if (t.contains('redistribution and use in source and binary forms')) {
    return t.contains('neither the name') ? 'BSD-3-Clause' : 'BSD-2-Clause';
  }
  if (t.contains('isc license') || t.contains('isc license (isc)')) {
    return 'ISC';
  }
  return 'Custom (see text below)';
}

/// Renders one package's notice block. [licenseText] == null renders an
/// explicit UNKNOWN marker with a resolution pointer — never a silent
/// omission.
String packageBlock(LockedPackage package, {String? licenseText}) {
  final separator = '-' * 80;
  final buffer = StringBuffer();
  buffer.writeln(separator);
  buffer.writeln('Package:  ${package.name} ${package.version}');
  if (package.source == 'hosted' && package.hostedUrl != null) {
    final packageUrl =
        '${_trimSlashes(package.hostedUrl!)}/packages/${package.name}';
    buffer.writeln('Source:   $packageUrl');
    if (licenseText != null && licenseText.isNotEmpty) {
      buffer.writeln(
        'License:  ${licenseLabel(licenseText)} — verbatim text from the package archive:',
      );
    } else {
      buffer.writeln(
        'License:  UNKNOWN — no license file resolved from the published archive.',
      );
      buffer.writeln('          Resolve manually: $packageUrl/license');
    }
  } else {
    buffer.writeln(
      'Source:   ${package.source} dependency (see pubspec.lock; archive not fetched)',
    );
    buffer.writeln(
      'License:  UNKNOWN — non-hosted dependency; resolve from its source repository.',
    );
  }
  buffer.writeln(separator);
  if (licenseText != null && licenseText.isNotEmpty) {
    buffer.writeln(licenseText.trimRight());
    buffer.writeln();
  }
  return buffer.toString();
}

/// Renders the whole notices document. [notices] must already be sorted
/// (parseLock sorts); no timestamps so runs are byte-identical.
String renderDocument(List<PackageNotice> notices) {
  final buffer = StringBuffer();
  buffer
    ..writeln('THIRD-PARTY NOTICES')
    ..writeln('===================')
    ..writeln()
    ..writeln('zuraffa_agent — https://github.com/arrrrny/zuraffa_agent')
    ..writeln()
    ..writeln(
      'This file bundles the license notices of every package pinned in',
    )
    ..writeln(
      '`pubspec.lock` (direct, dev-only and transitive). It is GENERATED —',
    )
    ..writeln(
      'DO NOT EDIT BY HAND. Regenerate after any dependency change with:',
    )
    ..writeln()
    ..writeln('    dart run tool/generate_third_party_notices.dart')
    ..writeln()
    ..writeln(
      'CI (`.github/workflows/pipeline.yml`, job `third-party-notices`)',
    )
    ..writeln(
      'regenerates this file and fails the build when it has drifted from',
    )
    ..writeln(
      'the lockfile. Entries are sorted alphabetically; license texts come',
    )
    ..writeln(
      'verbatim from the package archive published on pub.dev. Packages',
    )
    ..writeln(
      'whose license could not be resolved are marked UNKNOWN — treat them',
    )
    ..writeln('as unlicensed third-party code and resolve before distributing.')
    ..writeln();
  for (final notice in notices) {
    buffer.write(packageBlock(notice.package, licenseText: notice.licenseText));
  }
  return buffer.toString();
}

Future<void> main() async {
  final root = _repoRoot();
  final lockFile = File('$root/pubspec.lock');
  if (!lockFile.existsSync()) {
    stderr.writeln(
      'generate_third_party_notices: pubspec.lock not found under ${Directory.current.path} — run from the package root.',
    );
    exitCode = 1;
    return;
  }
  final packages = parseLock(lockFile.readAsStringSync());
  if (packages.isEmpty) {
    stderr.writeln(
      'generate_third_party_notices: pubspec.lock parsed to zero packages.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'generate_third_party_notices: fetching licenses for ${packages.length} locked packages...',
  );
  final licenses = <String, String?>{};
  final failures = <String, String>{};
  var cursor = 0;
  Future<void> worker() async {
    while (cursor < packages.length) {
      final package = packages[cursor++];
      try {
        licenses[package.name] = package.source == 'hosted'
            ? await _fetchLicenseText(package)
            : null;
      } catch (error) {
        failures[package.name] = '$error';
      }
    }
  }

  await Future.wait(List.generate(6, (_) => worker()));
  if (failures.isNotEmpty) {
    stderr.writeln('generate_third_party_notices: license fetch failed for:');
    for (final entry in failures.entries) {
      stderr.writeln('  ${entry.key}: ${entry.value}');
    }
    stderr.writeln(
      'Nothing written — rerun the tool (transient pub.dev errors happen).',
    );
    exitCode = 2;
    return;
  }

  final notices = <PackageNotice>[
    for (final package in packages)
      (package: package, licenseText: licenses[package.name]),
  ];
  final unknown = notices.where((n) => n.licenseText == null).toList();
  final target = File('$root/THIRD_PARTY_NOTICES.txt');
  target.writeAsStringSync(renderDocument(notices));
  stdout.writeln(
    'generate_third_party_notices: wrote ${target.path} — ${notices.length} packages '
    '(${notices.length - unknown.length} with license text, ${unknown.length} UNKNOWN).',
  );
  for (final notice in unknown) {
    stdout.writeln(
      '  UNKNOWN license: ${notice.package.name} ${notice.package.version} — resolve manually.',
    );
  }
}

String _repoRoot() {
  if (File('pubspec.lock').existsSync()) return Directory.current.path;
  final scriptFile = File.fromUri(Platform.script);
  return scriptFile.parent.parent.path;
}

Future<String?> _fetchLicenseText(LockedPackage package) async {
  final url = archiveUrlFor(
    package.hostedUrl ?? 'https://pub.dev',
    package.name,
    package.version,
  );
  for (var attempt = 1; attempt <= 3; attempt++) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 90),
      );
      if (response.statusCode == 200) {
        final builder = BytesBuilder(copy: false);
        // Stream.timeout mirrors the 90s close() timeout above: a connection
        // that stalls mid-body throws instead of holding the worker until the
        // CI job's timeout-minutes kills the run (review of PR #168).
        await for (final chunk in response.timeout(
          const Duration(seconds: 90),
        )) {
          builder.add(chunk);
        }
        return pickLicenseText(await extractLicenseFiles(builder.takeBytes()));
      }
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode} for $url');
    } catch (error) {
      if (attempt == 3) rethrow;
      await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
    } finally {
      client.close();
    }
  }
  throw StateError('_fetchLicenseText: unreachable');
}

String _tarString(Uint8List bytes, int start, int length) {
  final end = min(start + length, bytes.length);
  var stop = end;
  for (var i = start; i < end; i++) {
    if (bytes[i] == 0) {
      stop = i;
      break;
    }
  }
  return utf8.decode(bytes.sublist(start, stop), allowMalformed: true);
}

/// `path=` value out of a pax extended header record stream
/// (`<len> <key>=<value>\n` records).
String? _paxPathValue(String pax) {
  var i = 0;
  while (i < pax.length) {
    final space = pax.indexOf(' ', i);
    if (space < 0) return null;
    final len = int.tryParse(pax.substring(i, space));
    if (len == null || len <= space - i) return null;
    final record = pax.substring(space + 1, min(i + len, pax.length));
    if (record.startsWith('path=')) {
      return record.substring('path='.length).trimRight();
    }
    i += len;
  }
  return null;
}

bool _isLicenseFileName(String basename) {
  final upper = basename.toUpperCase();
  return upper.startsWith('LICENSE') ||
      upper.startsWith('LICENCE') ||
      upper.startsWith('COPYING') ||
      upper.startsWith('COPYRIGHT') ||
      upper == 'NOTICE' ||
      upper.startsWith('NOTICE.') ||
      upper.startsWith('UNLICENSE');
}

String _unquote(String value) => value.startsWith('"')
    ? value.substring(
        1,
        value.length > 1 && value.endsWith('"')
            ? value.length - 1
            : value.length,
      )
    : value;

String _trimSlashes(String url) =>
    url.endsWith('/') ? url.substring(0, url.length - 1) : url;
