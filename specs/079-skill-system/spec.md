# Feature Specification: R1 — Skill System (directory discovery & system-prompt rendering)

**Branch**: `079-skill-system` (off master `29b7fef`) | **Date**: 2026-08-29

## Summary

The engine needs a deterministic way to discover skill declarations on
disk and render them into the system prompt. Today the repo ships a
hand-written `lib/src/skills.dart` that already does the bones of this
(`Skill`, `loadSkills`, `formatSkillsForSystemPrompt`,
`_parseSkillFile`), but it was written before the R1 engine-core
contract was pinned and it carries three contract violations that this
spec closes:

1. **I/O hidden inside the transform.** `_parseSkillFile(File)` reads
   the file, splits lines, and parses the frontmatter all in one
   function — there is no pure entry point a test or another caller can
   reach with a string. The R1 engine-core rule (issue #2: "no I/O
   hidden inside transform logic") requires the parse to be a pure
   string-in / value-out function. Discovery walks the directory (the
   I/O boundary); parsing is a pure transform that takes the file's
   already-read content.
2. **Malformed frontmatter is silently swallowed.** `_parseSkillFile`
   wraps every exception in `catch (_) { return null; }` and
   `loadSkills` skips `null` returns without a trace. The issue brief
   is explicit: "Cover error handling for malformed frontmatter." A
   missing `---` opener, a missing closing `---`, or a missing `name:`
   field must surface as a typed error the caller can react to —
   silently dropping a malformed skill hides configuration bugs from
   the agent operator and from CI.
3. **No metadata surface.** The brief says "parse each SKILL.md
   frontmatter (name, description, metadata)". The current parser
   extracts `name` and `description` and silently drops every other
   frontmatter key. The engine has no way to see a skill's
   `metadata.*` block (version, author, source, compatibility) and so
   cannot reason about the skills it loaded.

This spec closes all three. It does NOT change the on-disk skill file
format (still YAML frontmatter + markdown body), does NOT change the
rendered prompt block shape (still `## Skill: {name}`), and does NOT
add a new file location — `lib/src/skills.dart` is edited in place and
its public surface grows additively (one new exception type, one new
function, the `Skill` gains a `metadata` field). The existing call
sites (`loadSkills`, `formatSkillsForSystemPrompt`) keep their
signatures so engine integration does not move.

**Out of scope, documented deviation**: skill *selection* — picking
which discovered skills are relevant to a given turn — is the engine
loop's job (spec 002). This spec only discovers and renders; the
caller decides what to inject.

## Files

- `lib/src/skills.dart` — EDIT (additive):
  - `SkillFormatException` (new typed exception for malformed
    frontmatter).
  - `Skill.metadata` field (new — parsed YAML frontmatter keys beyond
    `name`/`description`; empty map when none are present).
  - `Skill parseSkill(String content, {required String sourcePath})`
    (new — pure transform; replaces the body of `_parseSkillFile`).
  - `_parseSkillFile(File)` rewritten to read the file and delegate
    to `parseSkill(content, sourcePath: file.path)` — I/O at the
    boundary, pure transform inside.
  - `loadSkills(String directoryPath)` keeps its signature but now
    propagates `SkillFormatException` from a malformed file instead of
    swallowing it. Non-existent directory still returns `const []`
    (a missing skills directory is the engine's empty case, not an
    error).
  - `formatSkillsForSystemPrompt` is unchanged.
- `test/skills/skills_test.dart` — NEW: covers the pure parse surface
  (happy path, malformed frontmatter variants, metadata extraction,
  edge cases) and the discovery wiring (directory walk → list of
  parsed skills; malformed file in a directory surfaces the typed
  error).
- `lib/zuraffa_agent.dart` — EDIT: export `SkillFormatException` so
  engine integration can catch it.

## User scenarios

### US1 — Render discovered skills into the system prompt (P1)

As the engine integration owner, I point `loadSkills` at a directory
of `SKILL.md` / `*.skill.md` files and get back a list of `Skill`
values I can hand to `formatSkillsForSystemPrompt`. The rendered
string is the system-prompt block: each skill as `## Skill: {name}` +
description + instructions, separated by blank lines. Empty directory
or no skill files → empty string (the engine's no-skills case).

**Independent test**: a temp directory with two well-formed skill
files → `loadSkills` returns two `Skill`s in the order the directory
listed them → `formatSkillsForSystemPrompt` produces the documented
block shape with both skills present.

### US2 — Malformed frontmatter surfaces as a typed error (P1)

As the engine integration owner, when a skill file in the configured
directory has malformed frontmatter (missing opening `---`, missing
closing `---`, missing `name:` field), `loadSkills` throws
`SkillFormatException` naming the file and the reason — instead of
silently dropping the file or returning `null`. The typed error lets
CI fail loudly and lets the operator see exactly which file is broken.

**Independent test**: a temp directory with one well-formed file and
one malformed file (missing `name:`) → `loadSkills` throws
`SkillFormatException` whose `message` names the malformed file's
path and the missing field.

### US3 — Parse is a pure transform (P2)

As an engine-core maintainer following the R1 contract (no I/O hidden
inside transform logic), I can call `parseSkill(content,
sourcePath: ...)` directly with a string and get back a `Skill` — no
file system access, no `dart:io`, no async. This lets the engine reuse
the parser on content from any source (in-memory, network, test
fixtures) and lets tests drive the parser without touching disk.

**Independent test**: `parseSkill` with a string literal containing
well-formed frontmatter returns a `Skill` whose `name`, `description`,
`instructions`, and `metadata` are populated from the string — no
file involved.

### US4 — Metadata frontmatter is preserved (P2)

As an engine integration owner, the `metadata.*` keys in a skill
file's frontmatter (anything beyond `name` and `description`) are
preserved on the parsed `Skill` as a `Map<String, Object?>` — the
engine can read `skill.metadata['version']`, `skill.metadata['author']`,
`skill.metadata['source']` to reason about provenance.

**Independent test**: a skill file with frontmatter `name`, `description`,
plus `version: '1.0.0'`, `author: someone`, and a nested
`metadata: {source: foo}` block parses into a `Skill` whose `metadata`
map contains the extra keys.

## Requirements

### Functional requirements

- **FR-001**: `loadSkills(String directoryPath)` MUST return the
  list of `Skill`s discovered in the directory, walking only files
  named exactly `SKILL.md` or matching `*.skill.md`. Subdirectories
  are NOT recursed (one level — engine integration composes multiple
  directories itself). Non-existent directory → returns `const []`.
- **FR-002**: `loadSkills` MUST throw `SkillFormatException` when any
  discovered file has malformed frontmatter — never silently drops
  the file. The exception's `message` names the offending file path
  and the reason (missing opening `---`, missing closing `---`, missing
  `name:` field, ill-formed YAML).
- **FR-003**: `parseSkill(String content, {required String sourcePath})`
  MUST be a pure function: no `dart:io`, no `Future`, no side effects.
  Same content + sourcePath → same `Skill` (modulo the sourcePath
  field, which is echoed back on the result).
- **FR-004**: `parseSkill` MUST parse YAML frontmatter between `---`
  delimiters and extract at minimum `name` and `description` as
  strings. Missing `name` → `SkillFormatException` naming the field.
  Missing `description` → empty string (description is optional in
  practice; many skill files omit it).
- **FR-005**: `parseSkill` MUST preserve every additional frontmatter
  key on `Skill.metadata` (a `Map<String, Object?>`). Nested maps,
  lists, numbers, booleans, and null are preserved as-is. The
  top-level `name` and `description` are NOT duplicated into
  `metadata`.
- **FR-006**: `parseSkill` MUST treat the markdown body after the
  closing `---` as `Skill.instructions`, stripped of leading/trailing
  whitespace. Empty body → empty string (a skill with no instructions
  is unusual but not malformed).
- **FR-007**: `parseSkill` MUST throw `SkillFormatException` when:
  - the content does not start with `---` (no opening delimiter);
  - the opening `---` has no matching closing `---`;
  - the YAML between the delimiters cannot be parsed.
- **FR-008**: `formatSkillsForSystemPrompt(List<Skill>)` MUST return
  a string with each skill rendered as `## Skill: {name}\n{description}\n\n{instructions}`,
  skills separated by a blank line, and return the empty string when
  the list is empty. Unchanged from current behavior — pinned.
- **FR-009** (gates): `dart analyze --fatal-infos` exit 0 on the
  changed files; full `dart test` green (baseline 1073/2 + new).
  Pre-existing analyzer findings on unrelated files (1 warning +
  2 info at HEAD `29b7fef`) are out of scope and explicitly NOT
  regressed.

### Key entities

- `Skill` — value object: `name`, `description`, `instructions`,
  `sourcePath`, `metadata` (Map<String, Object?>). Plain Dart class
  (constitution IX exemption — same precedent as `AgentSession` PR
  #50, `ToolResult` PR #49, `StopPolicy` PR #47; skills are engine
  glue, not model-layer entities, and the file ships without a
  build_runner run).
- `SkillFormatException` — typed exception: `final String sourcePath;
  final String reason;` and a `message` getter that composes both.
  Implements `FormatException` so it slots into Dart's standard
  exception hierarchy for malformed textual input.
- `loadSkills(String directoryPath) → Future<List<Skill>>` — directory
  walk + parse; throws `SkillFormatException` on malformed files.
- `parseSkill(String content, {required String sourcePath}) → Skill`
  — pure transform; throws `SkillFormatException` on malformed input.
- `formatSkillsForSystemPrompt(List<Skill> skills) → String` — pure
  render; unchanged.

## Success criteria

- **SC-001**: `loadSkills` over a directory of well-formed skill files
  returns the parsed `Skill`s in directory-listing order; the rendered
  system-prompt block matches the documented shape (US1).
- **SC-002**: every malformed-frontmatter variant (no opening `---`,
  no closing `---`, missing `name:`, ill-formed YAML) produces a
  `SkillFormatException` whose message names the file and the reason
  (US2 / FR-002 / FR-007).
- **SC-003**: `parseSkill` is a pure function — callable with a
  string and no file system access, returns a `Skill` (US3 / FR-003).
- **SC-004**: `Skill.metadata` preserves every extra frontmatter key,
  including nested maps, lists, scalars (US4 / FR-005).
- **SC-005**: every pinned behavior (FR-001..FR-008) is guarded by a
  test that a deliberate mutant kills (mutation evidence in
  `tdd/verification.md`).

## Dependencies

- Builds on: master `29b7fef` — `lib/src/skills.dart` already exists
  (hand-written; this spec refactors it to expose the pure parse
  surface and to surface typed errors).
- Independent of: every other spec in flight (engine event bus, memory
  arc, request/response) — different file, different tests.
- yaml package: `pubspec.lock` resolves `yaml ^3.1.4` transitively
  (via `zuraffa`); used to parse the frontmatter block. No new
  dependency declaration needed.
