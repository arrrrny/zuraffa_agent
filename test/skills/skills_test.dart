// Spec 079 (issue arrrrny/zuraffa_agent#90) — R1 Skill System:
// directory discovery & system-prompt rendering. TDD cycle: RED →
// GREEN → MUTATIONS → GATES → verification.md.
//
// Coverage (specs/079-skill-system/tdd/test-list.md):
// - Group A (U1–U5):  `parseSkill` pure transform — happy path +
//   optional fields + metadata preservation + defensive copy.
// - Group B (U6–U9):  `parseSkill` error paths — every malformed
//   frontmatter variant surfaces a typed `SkillFormatException`.
// - Group C (U10–U13): `loadSkills` wiring — directory walk,
//   filename rules, non-existent dir, malformed-file propagation,
//   no recursion.
// - Group D (U14–U15): `formatSkillsForSystemPrompt` pin — empty
//   list → empty string; two skills → two `## Skill:` blocks
//   separated by a blank line.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/skills.dart';

void main() {
  const groupName = 'spec 079 — Skill System';

  group(groupName, () {
    // ----------------------------------------------------------------
    // Group A — `parseSkill` happy path & metadata (US3 / US4 / FR-003..FR-006)
    // ----------------------------------------------------------------
    group('parseSkill happy path', () {
      test('U1: well-formed input returns a fully-populated Skill', () {
        const content = '---\n'
            'name: my-skill\n'
            'description: A useful skill.\n'
            '---\n'
            '\n'
            'Do the thing.\n';
        final skill = parseSkill(content, sourcePath: '/tmp/x/SKILL.md');

        expect(skill.name, 'my-skill');
        expect(skill.description, 'A useful skill.');
        expect(skill.instructions, 'Do the thing.');
        expect(skill.sourcePath, '/tmp/x/SKILL.md');
        expect(skill.metadata, isEmpty);
      });

      test('U2: missing description field is tolerated (empty string)', () {
        const content = '---\n'
            'name: no-desc\n'
            '---\n'
            'body text\n';
        final skill = parseSkill(content, sourcePath: '/tmp/x/SKILL.md');

        expect(skill.name, 'no-desc');
        expect(skill.description, '');
        expect(skill.instructions, 'body text');
      });

      test('U3: empty body after closing delimiter is tolerated', () {
        const content = '---\n'
            'name: empty-body\n'
            '---\n';
        final skill = parseSkill(content, sourcePath: '/tmp/x/SKILL.md');

        expect(skill.name, 'empty-body');
        expect(skill.instructions, '');
      });

      test('U4: extra frontmatter keys are preserved on Skill.metadata', () {
        const content = '---\n'
            'name: with-meta\n'
            'description: has metadata\n'
            'version: 1.0.0\n'
            'author: someone\n'
            'metadata:\n'
            '  source: foo\n'
            '---\n'
            'body\n';
        final skill = parseSkill(content, sourcePath: '/tmp/x/SKILL.md');

        expect(skill.name, 'with-meta');
        expect(skill.description, 'has metadata');
        expect(skill.metadata['version'], '1.0.0');
        expect(skill.metadata['author'], 'someone');
        // Nested map preserved as a Map.
        final nested = skill.metadata['metadata'];
        expect(nested, isA<Map<String, Object?>>());
        expect((nested as Map)['source'], 'foo');
        // name and description are NOT duplicated into metadata.
        expect(skill.metadata.containsKey('name'), isFalse);
        expect(skill.metadata.containsKey('description'), isFalse);
      });

      test('U5: metadata is a defensive copy and values are coerced to plain Dart types', () {
        const content = '---\n'
            'name: defensive\n'
            'version: 1.0.0\n'
            'metadata:\n'
            '  source: foo\n'
            '---\n'
            'body\n';
        final first = parseSkill(content, sourcePath: '/tmp/x/SKILL.md');
        // Mutate the returned map — must not affect a second parse.
        first.metadata['version'] = 'tampered';
        final second = parseSkill(content, sourcePath: '/tmp/x/SKILL.md');

        expect(second.metadata['version'], '1.0.0');

        // The nested value must be a plain Dart Map (not a YamlMap node),
        // so callers don't accidentally depend on the yaml package's
        // internal node types.
        expect(
          second.metadata['metadata'],
          isA<Map<String, Object?>>(),
        );
        expect(
          (second.metadata['metadata'] as Map)['source'],
          'foo',
        );
        // And the top-level metadata map itself is a plain Dart Map.
        expect(second.metadata, isA<Map<String, Object?>>());
      });
    });

    // ----------------------------------------------------------------
    // Group B — `parseSkill` error paths (US2 / FR-007)
    // ----------------------------------------------------------------
    group('parseSkill error paths', () {
      test('U6: missing opening --- throws missing-opening-delimiter', () {
        const content = 'name: no-delimiters\n---\nbody\n';
        expect(
          () => parseSkill(content, sourcePath: '/tmp/x/SKILL.md'),
          throwsA(
            isA<SkillFormatException>()
                .having((e) => e.sourcePath, 'sourcePath', '/tmp/x/SKILL.md')
                .having((e) => e.reason, 'reason', 'missing-opening-delimiter'),
          ),
        );
      });

      test('U7: missing closing --- throws missing-closing-delimiter', () {
        const content = '---\nname: never-closed\ndescription: x\n';
        expect(
          () => parseSkill(content, sourcePath: '/tmp/x/SKILL.md'),
          throwsA(
            isA<SkillFormatException>()
                .having((e) => e.sourcePath, 'sourcePath', '/tmp/x/SKILL.md')
                .having((e) => e.reason, 'reason', 'missing-closing-delimiter'),
          ),
        );
      });

      test('U8: missing name field throws missing-name', () {
        const content = '---\ndescription: no name here\n---\nbody\n';
        expect(
          () => parseSkill(content, sourcePath: '/tmp/x/SKILL.md'),
          throwsA(
            isA<SkillFormatException>()
                .having((e) => e.sourcePath, 'sourcePath', '/tmp/x/SKILL.md')
                .having((e) => e.reason, 'reason', 'missing-name'),
          ),
        );
      });

      test('U9: ill-formed YAML throws yaml-parse-error', () {
        // Unterminated quoted string — yaml.loadYaml will reject this.
        const content = '---\nname: "unterminated\n---\nbody\n';
        expect(
          () => parseSkill(content, sourcePath: '/tmp/x/SKILL.md'),
          throwsA(
            isA<SkillFormatException>()
                .having((e) => e.sourcePath, 'sourcePath', '/tmp/x/SKILL.md')
                .having((e) => e.reason, 'reason', 'yaml-parse-error'),
          ),
        );
      });
    });

    // ----------------------------------------------------------------
    // Group C — `loadSkills` wiring (US1 / FR-001 / FR-002)
    // ----------------------------------------------------------------
    group('loadSkills wiring', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('skills_test_');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      Future<File> writeSkill(String relPath, String content) async {
        final file = File(p.join(tempDir.path, relPath));
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
        return file;
      }

      test('U10: non-existent directory returns an empty list', () async {
        final skills = await loadSkills(p.join(tempDir.path, 'does-not-exist'));
        expect(skills, isEmpty);
      });

      test(
        'A1 / U-load: well-formed directory returns parsed skills in order',
        () async {
          await writeSkill('SKILL.md', '---\nname: first\ndescription: a\n---\nbody-1\n');
          // tiny delay so the second file's mtime/listing is after the first
          await Future<void>.delayed(const Duration(milliseconds: 5));
          await writeSkill('second.skill.md', '---\nname: second\ndescription: b\n---\nbody-2\n');

          final skills = await loadSkills(tempDir.path);
          expect(skills, hasLength(2));

          final names = skills.map((s) => s.name).toList();
          // The directory listing is OS-dependent; assert both are present.
          expect(names.toSet(), {'first', 'second'});

          // Rendered block contains both ## Skill: headers.
          final rendered = formatSkillsForSystemPrompt(skills);
          expect(rendered, contains('## Skill: first'));
          expect(rendered, contains('## Skill: second'));
          expect(rendered, contains('body-1'));
          expect(rendered, contains('body-2'));
        },
      );

      test('U11: malformed file surfaces as SkillFormatException', () async {
        await writeSkill('SKILL.md', '---\nname: ok\ndescription: good\n---\ngood body\n');
        await writeSkill(
          'broken.skill.md',
          '---\ndescription: missing name field\n---\nbody\n',
        );

        expect(
          () => loadSkills(tempDir.path),
          throwsA(
            isA<SkillFormatException>()
                .having((e) => e.sourcePath, 'sourcePath', contains('broken.skill.md'))
                .having((e) => e.reason, 'reason', 'missing-name'),
          ),
        );
      });

      test('U12: filename rules — SKILL.md and *.skill.md match, README.md ignored', () async {
        await writeSkill('SKILL.md', '---\nname: alpha\n---\nbody-a\n');
        await writeSkill('beta.skill.md', '---\nname: beta\n---\nbody-b\n');
        await writeSkill('README.md', '# not a skill file\n');

        final skills = await loadSkills(tempDir.path);
        final names = skills.map((s) => s.name).toSet();
        expect(names, {'alpha', 'beta'});
        expect(skills, hasLength(2));
      });

      test('U13: does NOT recurse into subdirectories', () async {
        await writeSkill('SKILL.md', '---\nname: top\n---\ntop body\n');
        // Nested skill file in a subdirectory — must be ignored.
        await writeSkill('nested/SKILL.md', '---\nname: nested\n---\nnested body\n');

        final skills = await loadSkills(tempDir.path);
        expect(skills, hasLength(1));
        expect(skills.single.name, 'top');
      });
    });

    // ----------------------------------------------------------------
    // Group D — `formatSkillsForSystemPrompt` pin (FR-008)
    // ----------------------------------------------------------------
    group('formatSkillsForSystemPrompt pin', () {
      test('U14: empty list renders as the empty string', () {
        expect(formatSkillsForSystemPrompt(const <Skill>[]), '');
      });

      test('U15: two skills render as two ## Skill: blocks separated by a blank line', () {
        final skills = <Skill>[
          const Skill(
            name: 'first',
            description: 'desc-1',
            instructions: 'body-1',
            sourcePath: '/a/SKILL.md',
            metadata: {},
          ),
          const Skill(
            name: 'second',
            description: 'desc-2',
            instructions: 'body-2',
            sourcePath: '/b/SKILL.md',
            metadata: {},
          ),
        ];
        final rendered = formatSkillsForSystemPrompt(skills);

        // Block 1 then a blank line then block 2.
        expect(
          rendered,
          '## Skill: first\n'
          'desc-1\n'
          '\n'
          'body-1\n'
          '\n'
          '## Skill: second\n'
          'desc-2\n'
          '\n'
          'body-2\n',
        );
      });
    });
  });
}
