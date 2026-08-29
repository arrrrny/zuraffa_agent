# Implementation Plan: R1 — Skill System (spec 079)

## Approach

Three additive changes to `lib/src/skills.dart`, each driven by a
failing test, then a small set of mutations to prove the pins hold.
The file already compiles and is exercised in production; this plan
extracts the pure transform, surfaces the typed error, and grows the
metadata surface without changing the file's role or location.

The yaml package is already available transitively (via `zuraffa`'s
dev/build chain — `pubspec.lock` resolves `yaml ^3.1.4`). We import it
in `skills.dart` and let the analyzer confirm. If the transitive
resolution ever regresses, the YAML-frontmatter parsing falls back to
the line-based heuristic the file already ships — but for the metadata
extraction (FR-005, nested maps/lists) we need a real YAML parser, so
yaml is the chosen tool.

## Components

### 1. `SkillFormatException` (`lib/src/skills.dart`)

```dart
/// Thrown when a skill file's frontmatter is malformed.
class SkillFormatException extends FormatException {
  /// Path of the offending file (or the `sourcePath` passed to
  /// [parseSkill]).
  final String sourcePath;

  /// Short machine-readable reason code (e.g. `'missing-name'`,
  /// `'missing-opening-delimiter'`, `'missing-closing-delimiter'`,
  /// `'yaml-parse-error'`).
  final String reason;

  SkillFormatException(this.sourcePath, this.reason, [Object? parsed])
      : super(
          'Skill file at "$sourcePath" has malformed frontmatter: $reason'
          '${parsed != null ? ' (near: $parsed)' : ''}',
        );
}
```

`FormatException` is the right base — Dart's standard type for
malformed textual input. Engine integration can catch
`SkillFormatException` specifically or fall through to
`FormatException`.

### 2. `Skill.metadata` + `parseSkill` (pure transform)

```dart
class Skill {
  final String name;
  final String description;
  final String instructions;
  final String sourcePath;
  /// Every frontmatter key other than `name` and `description`,
  /// preserved as-is from the YAML parse. Empty map when the
  /// frontmatter declares only `name`/`description`.
  final Map<String, Object?> metadata;
  // ...
}

Skill parseSkill(String content, {required String sourcePath}) {
  // 1. Split frontmatter from body on `---` delimiters.
  // 2. Missing opening `---` → SkillFormatException(sourcePath, 'missing-opening-delimiter').
  // 3. Missing closing `---` → SkillFormatException(sourcePath, 'missing-closing-delimiter').
  // 4. Parse the frontmatter YAML via `yaml.loadYaml`.
  //    - Parse error → SkillFormatException(sourcePath, 'yaml-parse-error', error).
  //    - Result must be a Map; otherwise SkillFormatException(sourcePath, 'frontmatter-not-a-map').
  // 5. Extract `name` (required, must be a String); missing/wrong type → SkillFormatException(sourcePath, 'missing-name').
  // 6. Extract `description` (optional; non-string or absent → '').
  // 7. `metadata` = the YAML map with `name` and `description` keys removed.
  //    Defensive copy: a `Map<String, Object?>.from(...)` so the Skill's
  //    field cannot be mutated by callers holding the YAML node.
  // 8. `instructions` = body after closing `---`, trimmed.
  // 9. Return Skill(...).
}
```

Pure: no `dart:io`, no `Future`, no `await`. Synchronous string-in →
value-out.

### 3. `_parseSkillFile` becomes a thin I/O wrapper

```dart
Future<Skill?> _parseSkillFile(File file) async {
  try {
    final content = await file.readAsString();
    return parseSkill(content, sourcePath: file.path);
  } on SkillFormatException {
    // Re-throw so loadSkills surfaces it (FR-002).
    rethrow;
  } catch (e) {
    // Genuine I/O error (file vanished mid-walk, permission denied).
    // The contract is silent on this — wrap as SkillFormatException so
    // callers have a single typed exception to catch.
    throw SkillFormatException(file.path, 'io-error', e);
  }
}
```

The old `catch (_) { return null; }` is gone. Malformed frontmatter
propagates as `SkillFormatException`; genuine I/O errors are wrapped
in the same type for a single catch surface. `loadSkills` no longer
swallows `null`s — every parsed file either yields a `Skill` or
throws.

### 4. `loadSkills` wiring

```dart
Future<List<Skill>> loadSkills(String directoryPath) async {
  final dir = Directory(directoryPath);
  if (!await dir.exists()) return const [];
  final skills = <Skill>[];
  await for (final entity in dir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (name == 'SKILL.md' || name.endsWith('.skill.md')) {
      skills.add(await _parseSkillFile(entity));  // propagates SkillFormatException
    }
  }
  return skills;
}
```

Two changes from current: (a) `entity.path.split(Platform.pathSeparator)`
becomes `entity.uri.pathSegments.last` — works the same on POSIX and
Windows and avoids `dart:io`'s `Platform.pathSeparator` from leaking
into the pure transform's test surface; (b) `_parseSkillFile` is
`await`ed directly (no `null` to skip), so a malformed file surfaces
its typed error to the caller.

### 5. Tests (`test/skills/skills_test.dart`)

Three groups, mirroring the four user stories:

**Group A — `parseSkill` (pure transform, US3)**:
- T1: well-formed input (name + description + body) → Skill with all fields populated.
- T2: missing `description` → empty string for description, no throw.
- T3: empty instructions body → empty string, no throw.
- T4: metadata frontmatter (`version`, `author`, nested `metadata: {source: foo}`) → preserved on `Skill.metadata`.

**Group B — `parseSkill` error paths (US2 / FR-007)**:
- T5: no opening `---` → `SkillFormatException` with reason `missing-opening-delimiter`, `sourcePath` echoed.
- T6: opening `---` but no closing → `missing-closing-delimiter`.
- T7: frontmatter present, `name:` missing → `missing-name`.
- T8: frontmatter YAML ill-formed (e.g. `name: unquoted: with: colons`) → `yaml-parse-error`.

**Group C — `loadSkills` wiring (US1 / FR-001 / FR-002)**:
- T9: well-formed directory (two `SKILL.md` files) → list of two Skills in directory-listing order; rendered block has both `## Skill:` headers.
- T10: non-existent directory → `const []`.
- T11: directory with a malformed file alongside a well-formed one → throws `SkillFormatException` naming the malformed file's path.
- T12: directory with `SKILL.md` and `helper.skill.md` → both discovered (filename rules).
- T13: directory with `README.md` (not a skill file) → ignored, no error.

**Group D — `formatSkillsForSystemPrompt` pin (FR-008)**:
- T14: empty list → empty string.
- T15: two skills → string with two `## Skill:` blocks separated by a blank line; the `description` and `instructions` appear in the documented positions.

### 6. Mutations (M1–M6, one at a time, cp-restored)

- **M1**: `parseSkill` returns a hardcoded `Skill(name: 'x', ...)` ignoring input (guards T1/T4).
- **M2**: `parseSkill` returns `null` instead of throwing on missing `name` (guards T7).
- **M3**: `loadSkills` swallows `SkillFormatException` and returns `const []` (guards T11).
- **M4**: `loadSkills` recurses into subdirectories (guards T12/T13 — subdirectories with non-skill files would no longer be ignored cleanly if recursed).
- **M5**: `formatSkillsForSystemPrompt` joins skills without a blank-line separator (guards T15).
- **M6**: `Skill.metadata` returns a reference to the YAML node's live map (mutation leakage — guards T4 by asserting `metadata` is a defensive copy).

## Sequencing

1. RED — write `test/skills/skills_test.dart` (15 tests) against the
   `parseSkill`, `SkillFormatException`, and `Skill.metadata` surfaces
   that don't exist yet. Compile failure: `parseSkill` undefined,
   `SkillFormatException` undefined, `Skill.metadata` undefined.
2. GREEN — land `SkillFormatException`, add `Skill.metadata`, add
   `parseSkill`, rewrite `_parseSkillFile` to delegate, tighten
   `loadSkills` to propagate. Tests 15/15 green.
3. MUTATIONS — M1–M6, one at a time, `cp`-restored between runs.
   Each must KILL (i.e. at least one test fails when the mutant is
   applied; the test passes again when the mutant is retracted).
4. GATES — `dart analyze --fatal-infos` exit 0 on the changed files;
   full `dart test` green (baseline 1073/2 + 15 new = 1088/2).
5. ARTIFACTS — `tdd/verification.md` records the cycle integrity,
   mutation evidence verbatim, the FR table, and the verdict.
6. COMMIT (spec.md + plan.md + tasks.md + tdd/test-list.md +
   tdd/verification.md + skills.dart + skills_test.dart + the
   zuraffa_agent.dart export edit) and open PR with base `master`.
