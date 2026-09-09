# Tasks: Grader diversity (issue #125)

**Tests**: TDD-driven — every behavior on `tdd/test-list.md` (A1–A2, U1–U9)
is observed failing before its implementation.

- [x] T001 Create `specs/111-grader-diversity/` with spec.md seeded from
  issue #125 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, this tasks.md,
  tdd/test-list.md, cycle-log baseline

## Phase 2: Graders

- [x] T003 [P] Test `test/eval/graders/graders_test.dart` (exact + regex
  group) — [U1] exact match trim/equality + reason, [U2] regex match +
  pattern-naming reason.
- [x] T004 [P] Implement `lib/src/eval/graders/grader.dart` (interface +
  result), `exact_match_grader.dart`, `regex_grader.dart` — makes [U1]/[U2]
  green.
- [x] T005 [P] Test (json-path group) — [U3] resolved-path pass, [U4]
  missing path / mismatch / malformed JSON fail with reasons.
- [x] T006 Implement `json_path_grader.dart` (documented subset) — makes
  [U3]/[U4] green.

## Phase 3: LLM judge + registry

- [x] T007 [P] Test (llm-judge group) — [U5] PASS parse + prompt/output in
  judge message, [U6] FAIL reason, [U7] unparsable response quoted.
- [x] T008 Implement `llm_judge_grader.dart` (injected completion seam) —
  makes [U5]–[U7] green.
- [x] T009 [P] Test (registry group) — [U8] bind/resolve/unknown-id, [U9]
  bulk evaluation.
- [x] T010 Implement `grader_registry.dart` — makes [U8]/[U9] green.

## Phase 4: Acceptance + verify

- [x] T011 Acceptance [A1]: the composed four-family registry evaluation.
- [x] T012 Acceptance [A2] gates: analyze zero, suite green, purity
  unchanged.
- [x] T013 Run `/speckit.tdd.verify` → `tdd/verification.md`; commit
  (`feat(111):`), push, open PR closing #125.
