# Test List: R1 — Skill System (spec 079)

---
feature: 079-skill-system
loop: outside-in
profile: .specify/memory/tdd-profile.md # file absent at HEAD — rubric graded against the tdd-test-quality-rubric template + constitution.md Principles II/V/VII
spec_criteria: 9 # FR-001..FR-009 in spec.md
planned_at: master (29b7fef)
updated_at: 079-skill-system (planned)
suite_baseline: 1073 passed / 2 skipped at 29b7fef (master)
suite_after: 1089 passed / 2 skipped at 079-skill-system HEAD (+16 new, 0 regressions)
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `loadSkills` over a directory of two well-formed `SKILL.md` files returns the two `Skill`s in directory-listing order; `formatSkillsForSystemPrompt` renders both as `## Skill:` blocks separated by a blank line | FR-001, FR-008, US1 | example | PASSING | `test/skills/skills_test.dart::spec 079 — Skill System::loadSkills over a well-formed directory returns parsed skills in order` |
| A2  | `loadSkills` over a directory with a malformed file (missing `name:`) throws `SkillFormatException` whose message names the offending file path and the reason — never silently drops the file | FR-002, US2 | example | PASSING | `test/skills/skills_test.dart::spec 079 — Skill System::loadSkills surfaces malformed frontmatter as a typed SkillFormatException` |
| A3  | Gates: `dart analyze --fatal-infos` exit 0 on the changed files; full `dart test` green (baseline 1073/2 + 16 new) | FR-009 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `parseSkill` (pure transform — RED via missing function)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Well-formed input (`---\nname: x\ndescription: y\n---\nbody`) returns a `Skill` with `name`, `description`, `instructions`, and `sourcePath` all populated from the input | FR-003, FR-004, US3 | unit | PASSING | `…::parseSkill happy path returns a fully-populated Skill` |
| U2  | Missing `description` field → `description` is the empty string; `name` and `instructions` are still parsed | FR-004 | unit | PASSING | `…::parseSkill tolerates a missing description field` |
| U3  | Empty body after the closing `---` → `instructions` is the empty string; no throw | FR-006 | unit | PASSING | `…::parseSkill tolerates an empty instructions body` |
| U4  | Frontmatter declaring extra keys (`version`, `author`, nested `metadata: {source: foo}`) preserves them on `Skill.metadata`; `name` and `description` are NOT duplicated into `metadata` | FR-005, US4 | unit | PASSING | `…::parseSkill preserves extra frontmatter keys on metadata` |
| U5  | `metadata` is a defensive copy AND values are coerced to plain Dart types (not YamlMap/YamlList nodes); mutating the returned `Skill.metadata` does not affect a second `parseSkill` call on the same input | FR-005 | unit | PASSING | `…::parseSkill metadata is a defensive copy and values are coerced to plain Dart types` |

### `parseSkill` error paths (RED via missing function)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U6  | Content that does not start with `---` throws `SkillFormatException` with `reason = 'missing-opening-delimiter'` and `sourcePath` echoed | FR-007 | unit | PASSING | `…::parseSkill throws on missing opening delimiter` |
| U7  | Opening `---` with no matching closing `---` throws `SkillFormatException` with `reason = 'missing-closing-delimiter'` | FR-007 | unit | PASSING | `…::parseSkill throws on missing closing delimiter` |
| U8  | Frontmatter YAML parses but the `name:` field is missing throws `SkillFormatException` with `reason = 'missing-name'` | FR-004, FR-007 | unit | PASSING | `…::parseSkill throws on missing name field` |
| U9  | Frontmatter YAML is ill-formed (`name: "unterminated quote`) throws `SkillFormatException` with `reason = 'yaml-parse-error'` | FR-007 | unit | PASSING | `…::parseSkill throws on ill-formed YAML` |

### `loadSkills` wiring (FR-001 / FR-002)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U10 | Non-existent directory → returns `const []` (engine's empty case); no throw | FR-001 | unit | PASSING | `…::loadSkills on a non-existent directory returns an empty list` |
| U11 | Directory with one malformed file alongside a well-formed one → throws `SkillFormatException` naming the malformed file's path | FR-002 | unit | PASSING | `…::loadSkills surfaces the first malformed file as a SkillFormatException` |
| U12 | Directory containing `SKILL.md` and `helper.skill.md` → both discovered; `README.md` ignored | FR-001 | unit | PASSING | `…::loadSkills applies the filename rules (SKILL.md and *.skill.md)` |
| U13 | Subdirectories inside the skills directory are NOT recursed — a directory containing a subdirectory with a `SKILL.md` does NOT include the nested skill | FR-001 | unit | PASSING | `…::loadSkills does not recurse into subdirectories` |

### `formatSkillsForSystemPrompt` pin (FR-008)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U14 | Empty list → empty string (the engine's no-skills case) | FR-008 | pin | PASSING | `…::formatSkillsForSystemPrompt renders an empty list as the empty string` |
| U15 | Two skills → string with two `## Skill:` blocks separated by a single blank line; description first, then a blank line, then instructions | FR-008, US1 | pin | PASSING | `…::formatSkillsForSystemPrompt renders two skills as separated Skill blocks` |

## Edge cases & invariants

- A skill file with Windows line endings (`\r\n`) parses identically
  to the Unix (`\n`) form (the YAML parser handles both).
- A skill file with BOM (`\uFEFF`) at the start — frontmatter opening
  `---` does not match. Caller responsibility to strip BOM; this spec
  does not paper over upstream encoding bugs (documented deviation).
- A directory path that exists but is unreadable (permission denied)
  — `loadSkills` lets `dart:io`'s `Directory.list` throw as it
  normally would; only the parse path produces `SkillFormatException`.
  The I/O layer's own exceptions are out of scope for typing.
- Unicode in `name`, `description`, `instructions`, and `metadata`
  values is preserved byte-for-byte (YAML parser is unicode-aware).

## Out of scope

- Skill *selection* (which discovered skills are relevant to a turn) —
  engine loop (spec 002) responsibility.
- Recursive directory walk — caller composes multiple directories.
- Hot-reload of skill files at runtime.
- Network-backed skill sources — `loadSkills` takes a directory path;
  HTTP / S3 / GCS sources are a later engine-integration concern.
- BOM stripping on input.

## Verification commands

- Single test: `dart test test/skills/skills_test.dart -N 'spec 079 — Skill System'`
- Full suite: `dart test`
- Analyze: `dart analyze --fatal-infos lib/src/skills.dart lib/zuraffa_agent.dart test/skills/skills_test.dart`
