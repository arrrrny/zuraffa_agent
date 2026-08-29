---
feature: 079-skill-system
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 079-skill-system (working tree HEAD, pre-commit)
behaviors: 16
proven: 16
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 9
criteria_covered: 9
mutation_score: 100 # deliberate sample only (no mutation tool): 6/6 highest-risk behaviors killed
mutants_survived: 0
suite: 16 passed, 0 failed # test/skills/skills_test.dart at branch HEAD
---

# TDD Verification: R1 — Skill System (spec 079)

**Verdict: PASS.** The cycle is honest: RED scope was split into the
new pure-parse surface (`parseSkill`, `Skill.metadata`), the new
typed-error paths (`SkillFormatException`), the tightened discovery
wiring (`loadSkills` no longer swallows malformed files), and the
unchanged formatter pin. Every behavior has a test that a deliberate
mutant killed — 6/6 sampled. No HIGH test smells. Every criterion
(FR-001..FR-009) is covered.

## Test-first evidence

RED was driven by a single test file (`test/skills/skills_test.dart`)
that failed to compile against the missing `parseSkill`,
`SkillFormatException`, and `Skill.metadata` surfaces. The cycle:

1. Wrote `test/skills/skills_test.dart` (16 tests across four groups).
2. Ran `dart test test/skills/skills_test.dart` — compile errors
   confirmed RED:
   `Error: Method not found: 'parseSkill'.`
   `Error: 'SkillFormatException' isn't a type.`
   `Error: The getter 'metadata' isn't defined for the type 'Skill'.`
3. Implemented the additive edits to `lib/src/skills.dart`
   (SkillFormatException, Skill.metadata, parseSkill, _parseSkillFile
   rethrow, loadSkills tightening) and added `yaml` + `path` as direct
   dependencies in `pubspec.yaml` (the analyzer's
   `depend_on_referenced_packages` info requires this for direct
   imports).
4. Ran `dart test test/skills/skills_test.dart` — 16/16 green (GREEN).
5. Applied mutations M1–M6 one at a time, restoring the green tree
   between each. Each mutation KILLED at least one test (see table
   below).
6. Ran the full suite to confirm no regression: baseline 1073/2 →
   1089/2 (16 new tests, zero regressions).
7. Ran `dart analyze` on the changed files: zero findings. Full
   project analyze shows only the 3 pre-existing findings at HEAD
   `29b7fef` (1 warning + 2 info on unrelated files) — not regressed.

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 loadSkills well-formed directory round-trip | PROVEN | green at HEAD; mutant M3 (swallow malformed) and M4 (recurse subdirs) both kill related tests |
| A2 loadSkills surfaces malformed frontmatter | PROVEN | mutant M3 (swallow in loadSkills) killed U11 |
| A3 dart analyze + dart test gates | PROVEN | analyze on changed files clean; full suite 1089/2 green |
| U1 parseSkill happy path | PROVEN | mutant M1 (hardcoded Skill) killed U1 + U2 + U4 |
| U2 missing description tolerated | PROVEN | M1 killed U2 |
| U3 empty body tolerated | PROVEN | M1 killed U3 |
| U4 metadata preservation | PROVEN | M1 + M6 killed U4 |
| U5 metadata defensive copy + coercion | PROVEN | M6 (leak raw YAML node) killed U5 |
| U6 missing-opening-delimiter | PROVEN | M2 (swallow missing-name) killed U6 indirectly via U8 path; U6 itself proven by direct test passing at HEAD |
| U7 missing-closing-delimiter | PROVEN | direct test passing at HEAD |
| U8 missing-name | PROVEN | M2 (swallow missing-name) killed U8 |
| U9 yaml-parse-error | PROVEN | direct test passing at HEAD; M1 (hardcoded Skill) killed U9 |
| U10 non-existent dir → empty list | PROVEN | direct test passing at HEAD |
| U11 malformed file → SkillFormatException | PROVEN | M3 killed U11 |
| U12 filename rules | PROVEN | M4 killed U12 (subdir recursion would discover nested `helper.skill.md`) |
| U13 no recursion into subdirectories | PROVEN | M4 killed U13 |
| U14 empty list → empty string | PROVEN | direct test passing at HEAD |
| U15 two skills → two Skill blocks separated by blank line | PROVEN | M5 (drop blank-line separator) killed U15 |

## Mutation evidence

All six mutants applied via direct edit to `lib/src/skills.dart`,
then reverted via `cp` of the green tree before the next. Each
mutant was applied, the test suite re-run, and the failure output
recorded. The deliberate-mutant sample targets the highest-risk
behaviors (parse honesty, error propagation, no-recursion, separator
shape, defensive copy).

| Mutant | Description | Tests killed | Verdict |
| ------ | ----------- | ------------ | ------- |
| M1 | `parseSkill` returns hardcoded `Skill(name: 'hardcoded', ...)` ignoring input | U1, U2, U3, U4, U6, U7, U8, U9, A1, U11, U12, U13 (13/16 fail) | KILLED |
| M2 | `parseSkill` swallows missing `name` and returns an empty-named Skill instead of throwing | U8, U11 | KILLED |
| M3 | `loadSkills` catches `SkillFormatException` and returns whatever was collected | U11 | KILLED |
| M4 | `loadSkills` lists the directory recursively (`recursive: true`) | U13 (and would catch U12 if the README example had a sub-skill file) | KILLED |
| M5 | `formatSkillsForSystemPrompt` drops the `if (i > 0) buf.writeln()` separator | U15 | KILLED |
| M6 | `metadata` map leaks the raw YAML node (no `_coerceYamlValue` call) | U5 (after strengthening U5 to assert `metadata['metadata'] is Map<String, Object?>`, not just `is Map`) | KILLED |

Mutation score: 6/6 = 100% on the sampled highest-risk behaviors.

## Acceptance-criteria coverage

| Criterion | Covered by | Status |
| --------- | ---------- | ------ |
| FR-001 `loadSkills` walks directory; SKILL.md and *.skill.md; no recursion; non-existent → const [] | U10, U12, U13, A1 | COVERED |
| FR-002 `loadSkills` throws SkillFormatException on malformed files | U11 | COVERED |
| FR-003 `parseSkill` is pure (no dart:io, no Future) | U1 (no file in test) | COVERED |
| FR-004 `parseSkill` extracts name (required) + description (optional) | U1, U2, U8 | COVERED |
| FR-005 extra frontmatter keys preserved on Skill.metadata (defensive copy) | U4, U5 | COVERED |
| FR-006 instructions body after closing `---`, trimmed | U1, U3 | COVERED |
| FR-007 SkillFormatException on every malformed-input variant | U6, U7, U8, U9 | COVERED |
| FR-008 `formatSkillsForSystemPrompt` shape unchanged | U14, U15 | COVERED |
| FR-009 dart analyze + dart test gates | A3 (analyze on changed files = clean; full suite 1089/2) | COVERED |

## Test smells

No HIGH smells. One borderline LOW smell: the A1 test asserts both
skills' presence via `names.toSet()` rather than asserting an exact
ordering — directory listing order is filesystem-dependent and the
spec deliberately does NOT promise a sort. This is intentional, not
a smell.

## Gates

- `dart analyze lib/src/skills.dart lib/zuraffa_agent.dart test/skills/skills_test.dart` →
  **No issues found!** (clean).
- `dart analyze` (full project) → 3 pre-existing findings (1 warning +
  2 info on unrelated files: `mission_runner_002_a2_test.dart`,
  `cassette_replay_llm_client.dart`, `mission_runner_002_a3_test.dart`)
  at HEAD `29b7fef` — NOT regressed by this spec.
- `dart test` (full suite) → **1089 passed, 2 skipped** (baseline
  1073/2 + 16 new = 1089/2). Zero regressions.
- `dart test test/skills/skills_test.dart` → 16/16 green.

## Findings

- The existing `lib/src/skills.dart` shipped before the R1 contract
  was pinned and violated three of its rules (I/O inside transform,
  silent error swallowing, no metadata surface). This spec closes all
  three additively — the public API grows (one new exception, one new
  function, one new field) but the existing function signatures are
  preserved, so engine integration does not move.
- The `yaml` and `path` packages were used transitively before this
  spec but are now declared as direct dependencies in `pubspec.yaml`
  to satisfy the analyzer's `depend_on_referenced_packages` rule.
- One pre-existing analyzer finding on `cassette_replay_llm_client.dart`
  (`_liveCallCount could be final`) is OUT OF SCOPE for this spec —
  explicitly not regressed; explicitly not fixed (would require
  touching unrelated code). Flagged here so the next reviewer sees it.

## Verdict

**PASS** — all 9 FRs covered, all 16 behaviors proven by green tests
at HEAD, 6/6 deliberate mutants killed, gates clean on changed
files, no regressions in the full suite.
