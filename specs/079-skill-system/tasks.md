# Tasks: R1 — Skill System (spec 079)

- [x] 1. RED — wrote `test/skills/skills_test.dart` (16 tests across
       four groups: pure parse happy path + metadata, parse error
       paths, `loadSkills` wiring, `formatSkillsForSystemPrompt` pin).
       Initial run failed to compile against the missing `parseSkill`,
       `SkillFormatException`, and `Skill.metadata` surfaces — RED
       evidence captured in `tdd/verification.md`.
- [x] 2. GREEN — additive edits to `lib/src/skills.dart`:
       (a) added `SkillFormatException` (extends `FormatException`,
       fields `sourcePath` + `reason` + message composition);
       (b) added `Skill.metadata` field (Map<String, Object?>,
       defaults to `const {}`);
       (c) added `parseSkill(String content, {required String sourcePath})`
       as a pure function (split on `---` delimiters, parse YAML via
       the `yaml` package, extract `name`/`description`/`metadata`,
       throw typed errors on every malformed-input variant);
       (d) rewrote `_parseSkillFile(File)` to read the file and
       delegate to `parseSkill(content, sourcePath: file.path)`,
       re-throwing `SkillFormatException` and wrapping genuine I/O
       errors in the same type;
       (e) tightened `loadSkills` to `await` `_parseSkillFile` directly
       (no `null` skipping), so malformed files surface to the caller.
- [x] 3. EXPORT — `SkillFormatException`, `parseSkill`, and
       `Skill.metadata` are reachable through the existing
       `export 'src/skills.dart';` in `lib/zuraffa_agent.dart`; no
       new export line needed.
- [x] 4. MUTATIONS — M1 hardcoded-skill return (killed 13/16);
       M2 swallow missing-name (killed U8, U11); M3 swallow
       malformed-file in loadSkills (killed U11); M4 recurse
       subdirectories (killed U13); M5 drop blank-line separator in
       formatter (killed U15); M6 leak live YAML map in `metadata`
       (killed U5 after strengthening U5 to assert plain-Dart type
       coercion). One at a time, `cp`-restored, each KILLED.
- [x] 5. GATES — `dart analyze lib/src/skills.dart lib/zuraffa_agent.dart
       test/skills/skills_test.dart` → "No issues found!" (clean).
       Full `dart test` green: baseline 1073/2 + 16 new = 1089/2.
       Pre-existing analyzer findings on unrelated files (1 warning +
       2 info at HEAD `29b7fef`) explicitly NOT regressed.
- [x] 6. `tdd/verification.md` — verdict PASS, full FR coverage table,
       mutation evidence verbatim, test-first evidence, gates, findings.
- [x] 7. COMMIT (artifacts + code together) and open PR with base
       `master` titled `feat(079): skill system — directory discovery
       & system-prompt rendering` closing #90.
