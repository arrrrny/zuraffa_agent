# Test List: 079-skill-system

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-10 | PENDING |
| A11 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-11 | PENDING |
| A12 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-12 | PENDING |
| A13 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-13 | PENDING |
| A14 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-14 | PENDING |
| A15 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-15 | PENDING |
| A16 | the pinned regression test passes (`test/skills/skills_test.dart`). | AC-16 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `loadSkills(String directoryPath)` MUST return the | FR-001 | PENDING |
| U2 | `loadSkills` MUST throw `SkillFormatException` when any | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: `parseSkill(String content, {required String sourcePath})` | FR-003 | PENDING |
| U4 | `parseSkill` MUST parse YAML frontmatter between `---` | FR-004 | PENDING |
| U5 | `parseSkill` MUST preserve every additional frontmatter | FR-005 | PENDING |
| U6 | `parseSkill` MUST treat the markdown body after the | FR-006 | PENDING |
| U7 | `parseSkill` MUST throw `SkillFormatException` when: | FR-007 | PENDING |
| U8 | `formatSkillsForSystemPrompt(List<Skill>)` MUST return | FR-008 | PENDING |
| U9 | The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the | FR-009 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A2 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A3 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A4 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A5 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A6 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A7 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A8 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A9 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A10 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A11 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A12 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A13 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A14 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A15 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A16 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U9 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

