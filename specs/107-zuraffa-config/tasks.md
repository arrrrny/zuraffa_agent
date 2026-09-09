# Tasks: ZuraffaConfig runtime configuration (issue #121)

**Tests**: TDD-driven — every behavior on `tdd/test-list.md` (A1–A4, U1–U14)
is observed failing before its implementation.

- [x] T001 Create `specs/107-zuraffa-config/` with spec.md seeded from
  issue #121 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, this tasks.md,
  tdd/test-list.md, cycle-log baseline

## Phase 2: The aggregate + typed validation (US3 core)

- [ ] T003 [P] Test `test/config/zuraffa_config_test.dart` — [U1] six
  nullable sections carried verbatim, [U2] fully-populated validates empty,
  [U3] engine-loop-without-provider → missing issue, [U4] out-of-range
  budgets (maxTurns / timeoutMs / negative wall-clock), [U5] session-id
  mismatch → incompatible issue.
- [ ] T004 Implement `lib/src/config/zuraffa_config.dart` (aggregate +
  sealed `ConfigIssue` family + deterministic `validate()`) — makes
  [U1]–[U5] green.

## Phase 3: Loaders (US1, US2)

- [ ] T005 [P] Test `test/config/zuraffa_config_loader_test.dart` — [U6]
  full document round-trip, [U7] partial + unknown keys ignored, [U8]
  wrong-typed field → ArgumentError naming it, [U9] full env map, [U10]
  partial env + unknown vars ignored + unparsable numeric → ArgumentError.
- [ ] T006 Implement `lib/src/config/zuraffa_config_loader.dart` (`fromYaml`
  with spec-104-style diagnostics; `fromEnv` over an injected map with the
  documented `ZFA_*` variables) — makes [U6]–[U10] green.

## Phase 4: Secrets interface (US4)

- [ ] T007 [P] Test `test/config/secret_resolver_test.dart` — [U11] stub
  returns absence for all three sources.
- [ ] T008 Implement `lib/src/config/secret_resolver.dart` — makes [U11]
  green.

## Phase 5: Fail-fast gate + README (US1, US3)

- [ ] T009 [P] Test `test/engine/mission_runner_config_gate_test.dart` —
  [U12] invalid config → StateError listing all issues, zero events,
  executor untouched, [U13] valid config runs unchanged, [U14] no config
  unchanged.
- [ ] T010 Implement the gate: optional `config` on `MissionRunner`;
  `run()` validates first — makes [U12]–[U14] green.
- [ ] T011 [P] Test (loader file) — [A1]/[A3] the README example document
  parses, validates clean, and drives a scripted mission to completion.
- [ ] T012 Write the README "Configuring the engine" section (contract +
  example document) — makes [A1]/[A3] green.

## Phase 6: Acceptance gates + verify

- [ ] T013 Acceptance [A2]: multi-problem config → one issue per problem,
  runner throws before first event.
- [ ] T014 Acceptance [A4] gates: analyze zero, suite green, purity
  unchanged.
- [ ] T015 Run `/speckit.tdd.verify` → `tdd/verification.md`; commit
  (`spec(107):`/`feat(107):`), push, open PR closing #121.
