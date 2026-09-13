# Tasks: Tool-result sanitization (issue #118)

**Tests**: TDD-driven — every behavior on `tdd/test-list.md` (A1–A2, U1–U10)
is observed failing before its implementation.

- [x] T001 Create `specs/109-tool-result-sanitizer/` with spec.md seeded
  from issue #118 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, this tasks.md,
  tdd/test-list.md, cycle-log baseline

## Phase 2: The sanitizer (pure core)

- [x] T003 [P] Test `test/security/tool_result_sanitizer_test.dart` —
  [U1]–[U6] each default rule's fixture redacts with its marker, [U7] benign
  corpus unchanged, [U8] disable / custom pattern / custom marker.
- [x] T004 Implement `lib/src/security/tool_result_sanitizer.dart`
  (interface, `SanitizedToolResult`, `SanitizerConfig`,
  `RegexToolResultSanitizer` with the six rules) — makes [U1]–[U8] green.

## Phase 3: Runner wiring (US4)

- [x] T005 [P] Test `test/engine/mission_runner_sanitizer_test.dart` — [U9]
  secret-bearing tool result joins the transcript redacted, [U10] no
  sanitizer = verbatim.
- [x] T006 Implement the optional `toolResultSanitizer` on `MissionRunner`,
  applied at the transcript join (success content + error text) — makes
  [U9]/[U10] green and closes [A1].

## Phase 4: Gates + verify

- [x] T007 Acceptance [A2] gates: analyze zero, suite green, purity
  unchanged.
- [x] T008 Run `/speckit.tdd.verify` → `tdd/verification.md`; commit
  (`feat(109):`), push, open PR closing #118.
