# Feature Specification: Skill System (discovery & system-prompt rendering)

**Feature Branch**: `079-skill-system`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for the Skill System feature — directory-based skill discovery and system-prompt rendering — that is not yet covered by an existing spec (R1 engine core)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discover skills in a directory (Priority: P1)

An engine assembles its system prompt by scanning a skills directory for `SKILL.md` / `*.skill.md` files, parsing each file's YAML frontmatter (`name`, `description`) and treating the remaining markdown as instructions.

**Why this priority**: Skill discovery is the entry point that feeds model-facing instructions; without it the engine cannot load authored skills.

**Independent Test**: Can be fully tested by pointing discovery at a temp directory with a known set of `SKILL.md` files and asserting the returned `Skill` list (name/description/instructions/sourcePath) — delivers a loadable skill set.

**Acceptance Scenarios**:

1. **Given** a directory containing two valid `SKILL.md` files, **When** skills are loaded, **Then** exactly two `Skill` objects are returned with `name`/`description` taken from frontmatter and `instructions` taken from the body.
2. **Given** an empty or non-existent directory, **When** skills are loaded, **Then** an empty list is returned (no exception).

---

### User Story 2 - Render skills into system-prompt blocks (Priority: P2)

The discovered skills are rendered into a single string of `## Skill: {name}` blocks, one per skill, separated by a blank line, ready to be concatenated into the system prompt.

**Why this priority**: Rendering is the consumer side of discovery; it must be deterministic and order-stable.

**Independent Test**: Can be fully tested by formatting a fixed list of `Skill` objects and asserting the exact multi-block layout.

**Acceptance Scenarios**:

1. **Given** a list of N skills, **When** they are formatted, **Then** the output contains exactly N `## Skill:` blocks in input order, each followed by its description then instructions.
2. **Given** an empty list, **When** formatted, **Then** an empty string is returned.

---

### Edge Cases

- A file with no leading `---` frontmatter delimiter returns no skill (skipped, not parsed).
- A file whose frontmatter has no `name` returns no skill (name is required).
- A malformed file (unreadable, bad UTF-8) is skipped via try/catch without aborting the whole scan.
- `*.skill.md` glob matches `foo.skill.md` but not `SKILL.md` (which is matched by the exact name).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST discover skill definitions in a directory by scanning for files named exactly `SKILL.md` or ending in `.skill.md`.
- **FR-002**: System MUST parse a YAML frontmatter block delimited by `---` lines, reading at least `name` and `description`, and treat everything after the closing `---` as the skill `instructions`.
- **FR-003**: System MUST skip (not include) any file that lacks valid frontmatter or whose `name` field is empty.
- **FR-004**: System MUST render a list of `Skill` instances into system-prompt blocks of the form `## Skill: {name}\n{description}\n\n{instructions}`, one block per skill separated by a blank line, in input order.
- **FR-005**: System MUST return an empty list when the directory does not exist and an empty string when formatting an empty list.

### Key Entities

- **Skill**: `{ name: String, description: String, instructions: String, sourcePath: String }` — a discovered skill with its origin path.
- **SkillFile**: the on-disk `SKILL.md` / `*.skill.md` artifact (untrusted input; parsed defensively).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A directory with N valid skill files yields exactly N `Skill` objects (no duplicates, no drops).
- **SC-002**: `formatSkillsForSystemPrompt` produces one block per skill, in order, separated by a single blank line.
- **SC-003**: Malformed or missing-frontmatter files are skipped without throwing; a single bad file never aborts the scan.

## Assumptions

- Skills are authored as markdown files with YAML frontmatter; the engine consumes them read-only (no write-back).
- `name` and `description` may be quoted; surrounding quotes are stripped on parse.
- Discovery is synchronous filesystem scanning; large skill dirs are out of scope for v1 streaming.
- This feature maps to **R1 (engine core, issue #2)**: skill instructions are injected into the engine system prompt.
