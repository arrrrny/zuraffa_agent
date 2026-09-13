# Traceability: 079-skill-system

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:720522c633abeef4f8053323121292aed92d3a5db8547d022e7839885006a012
statements: 25
automated: 25
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 141 | - **FR-001**: `loadSkills(String directoryPath)` MUST return the | U1 | automated |
| FR-002 | 146 | - **FR-002**: `loadSkills` MUST throw `SkillFormatException` when any | U2 | automated |
| FR-003 | 151 | - **FR-003**: The system MUST satisfy this requirement: `parseSkill(String content, {required String sourcePath})` | U3 | automated |
| FR-004 | 155 | - **FR-004**: `parseSkill` MUST parse YAML frontmatter between `---` | U4 | automated |
| FR-005 | 160 | - **FR-005**: `parseSkill` MUST preserve every additional frontmatter | U5 | automated |
| FR-006 | 165 | - **FR-006**: `parseSkill` MUST treat the markdown body after the | U6 | automated |
| FR-007 | 169 | - **FR-007**: `parseSkill` MUST throw `SkillFormatException` when: | U7 | automated |
| FR-008 | 173 | - **FR-008**: `formatSkillsForSystemPrompt(List<Skill>)` MUST return | U8 | automated |
| FR-009 | 177 | - **FR-009**: The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the | U9 | automated |
| AC-1 | 235 | 1. **Given** the feature implementation under its clean-architecture seams **When** U1: well-formed input returns a fully-populated Skill **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A1 | automated |
| AC-2 | 236 | 2. **Given** the feature implementation under its clean-architecture seams **When** U2: missing description field is tolerated (empty string) **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A2 | automated |
| AC-3 | 237 | 3. **Given** the feature implementation under its clean-architecture seams **When** U3: empty body after closing delimiter is tolerated **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A3 | automated |
| AC-4 | 238 | 4. **Given** the feature implementation under its clean-architecture seams **When** U4: extra frontmatter keys are preserved on Skill.metadata **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A4 | automated |
| AC-5 | 239 | 5. **Given** the feature implementation under its clean-architecture seams **When** U5: metadata is a defensive copy and values are coerced to plain Dart types **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A5 | automated |
| AC-6 | 240 | 6. **Given** the feature implementation under its clean-architecture seams **When** U6: missing opening --- throws missing-opening-delimiter **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A6 | automated |
| AC-7 | 241 | 7. **Given** the feature implementation under its clean-architecture seams **When** U7: missing closing --- throws missing-closing-delimiter **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A7 | automated |
| AC-8 | 242 | 8. **Given** the feature implementation under its clean-architecture seams **When** U8: missing name field throws missing-name **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A8 | automated |
| AC-9 | 243 | 9. **Given** the feature implementation under its clean-architecture seams **When** U9: ill-formed YAML throws yaml-parse-error **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A9 | automated |
| AC-10 | 244 | 10. **Given** the feature implementation under its clean-architecture seams **When** U10: non-existent directory returns an empty list **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A10 | automated |
| AC-11 | 245 | 11. **Given** the feature implementation under its clean-architecture seams **When** A1 / U-load: well-formed directory returns parsed skills in order **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A11 | automated |
| AC-12 | 246 | 12. **Given** the feature implementation under its clean-architecture seams **When** U11: malformed file surfaces as SkillFormatException **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A12 | automated |
| AC-13 | 247 | 13. **Given** the feature implementation under its clean-architecture seams **When** U12: filename rules — SKILL.md and *.skill.md match, README.md ignored **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A13 | automated |
| AC-14 | 248 | 14. **Given** the feature implementation under its clean-architecture seams **When** U13: does NOT recurse into subdirectories **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A14 | automated |
| AC-15 | 249 | 15. **Given** the feature implementation under its clean-architecture seams **When** U14: empty list renders as the empty string **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A15 | automated |
| AC-16 | 250 | 16. **Given** the feature implementation under its clean-architecture seams **When** U15: two skills render as two ## Skill: blocks separated by a blank line **Then** the pinned regression test passes (`test/skills/skills_test.dart`). | A16 | automated |

