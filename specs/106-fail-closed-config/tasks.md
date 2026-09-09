# Tasks: Fail-closed provider configuration (issue #117)

**Tests**: TDD-driven — every behavior on `tdd/test-list.md` (A1–A3, U1–U5)
is observed failing before its implementation. Behavior ids in brackets are
the load-bearing link `/speckit.tdd.run` ticks against.

- [x] T001 Create `specs/106-fail-closed-config/` with spec.md seeded from
  issue #117 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, research.md, this
  tasks.md, tdd/test-list.md, cycle-log baseline

## Phase 2: Fail-closed construction (US1)

- [x] T003 [P] Test `test/data/providers/provider_config/provider_config_provider_test.dart`
  — [U1] constructing without a configuration throws `ArgumentError` naming
  the missing configuration; [U2] a configured provider serves the injected
  configuration verbatim (current + count).
- [x] T004 [P] Test `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`
  — [U3] constructing without a spec throws `ArgumentError`; [U4] the
  injected-spec pin stays green (no-arg construction removed).
- [x] T005 Implement the fail-closed constructors in
  `lib/src/data/providers/provider_config/provider_config_provider.dart` and
  `lib/src/data/providers/yaml_agent_spec/yaml_agent_spec_provider.dart`
  (required config; `ArgumentError` naming the missing configuration) —
  makes [U1]–[U4] green; closes acceptance [A1].

## Phase 3: De-vendor the defaults (US2)

- [x] T006 [P] Test `test/data/providers/` — [U5] the fallback chain's
  default ids contain no vendor id (neutral client kinds only).
- [x] T007 Implement the neutral fallback default ids in
  `lib/src/data/providers/fallback_chain/fallback_chain_provider.dart` —
  makes [U5] green.
- [x] T008 [P] De-vendor `test/integration/llm_client_proxy_test.dart`:
  `LLM_BASE_URL`/`LLM_MODEL`/API key required, stated-reason skip when
  absent, zero vendor strings — part of acceptance [A2].

## Phase 4: Acceptance gates

- [x] T009 Acceptance [A1]: both services' fail-closed + verbatim contract
  green in their test files.
- [x] T010 Acceptance [A2] gates: `rg -i "kilo\.ai|hy3" lib/ tool/ test/integration/`
  zero hits; `rg "'kilo'" lib/` zero hits; integration file env-required.
- [x] T011 Acceptance [A3] gates: `dart analyze` zero findings; `dart test`
  green; purity gate unchanged.
- [ ] T012 Run `/speckit.tdd.verify` → `tdd/verification.md`; commit artifacts
  + source (`spec(106):`/`feat(106):` convention); push; open PR closing
  #117.
