// Spec: issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI) —
// AC-5: Engine core imports no Flutter/UI packages.
//
// Agnostism gate: scans lib/ for `package:flutter*` imports and
// fails the suite if any are introduced. The engine stays
// UI-framework-agnostic (issue #8 §6: "rendering belongs to the
// plugin/app"); this test is the mechanical guardrail that catches a
// future regression the moment a `package:flutter` import lands in lib/.
//
// The test also scans lib/src/eval/ui_graders/ specifically — the new
// UI graders must operate on UiTreePayload value objects, never on
// Flutter widgets or rendered pixels (issue #8 §4: "golden missions can
// assert on rendered-intent (tree shape/props) without pixels").

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('issue #8 AC-5 — no Flutter imports under lib/', () {
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      fail('lib/ directory not found — run from repo root.');
    }
    final offenders = <String>[];
    final pattern = RegExp("^\\s*import\\s+['\"]package:flutter");
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'lib/ must not import package:flutter* — the engine stays '
          'UI-framework-agnostic (issue #8 §6 + AC-5). Offending imports:\n'
          '${offenders.join('\n')}',
    );
  });

  test('issue #8 AC-5 — pubspec.yaml has no Flutter SDK dependency', () {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      fail('pubspec.yaml not found — run from repo root.');
    }
    final contents = pubspec.readAsStringSync();
    // The pubspec must not declare flutter as a dependency. We check for
    // the `flutter:` SDK marker, which would appear as
    // `  flutter:\n    sdk: flutter` under dependencies.
    final flutterSdkPattern = RegExp(
      r'^\s*flutter:\s*\n\s*sdk:\s*flutter\s*$',
      multiLine: true,
    );
    expect(
      flutterSdkPattern.hasMatch(contents),
      isFalse,
      reason:
          'pubspec.yaml must not declare `flutter: sdk: flutter` — the '
          'engine stays UI-framework-agnostic (issue #8 §6 + AC-5).',
    );
  });

  test('issue #8 AC-5 — UI graders operate on UiTreePayload, not widgets', () {
    // The UI graders (UiSchemaGrader + UiSnapshotGrader) must import
    // UiTreePayload and must NOT import any flutter widget types. This
    // test scans the graders directory directly.
    final gradersDir = Directory('lib/src/eval/ui_graders');
    if (!gradersDir.existsSync()) {
      fail('lib/src/eval/ui_graders/ directory not found.');
    }
    final dartFiles = gradersDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(dartFiles, isNotEmpty, reason: 'UI graders directory is empty.');

    for (final file in dartFiles) {
      final contents = file.readAsStringSync();
      // Must import the UiTreePayload value object.
      expect(
        contents,
        contains('ui_tree_payload'),
        reason:
            '${file.path} must import UiTreePayload — graders operate on '
            'the value object, not rendered pixels (issue #8 §4).',
      );
      // Must not import Flutter widgets.
      expect(
        RegExp("import\\s+['\"]package:flutter").hasMatch(contents),
        isFalse,
        reason:
            '${file.path} must not import package:flutter — graders are '
            'UI-framework-agnostic (issue #8 §6).',
      );
    }
  });
}
