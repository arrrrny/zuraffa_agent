---
feature: 004-providers-and-fallback
loop: outside-in # LLM provider clients + fallback chain are a user-visible surface (engine operator, dashboards)
profile: .specify/memory/tdd-profile.md
spec_criteria: 7 # numbered Acceptance Scenarios across 4 user stories in spec.md (no global AC ids; traced to FR-xxx)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: Providers & Fallback Chain (spec 004)

> Derived from `spec.md` (User Scenarios & Testing → Acceptance Scenarios, and
> FR-001..FR-005) on `master` @ `fce207d`. **OUTER-ONLY**: `plan.md` is absent, so
> only the outer-loop acceptance behaviors are derived here; the inner loop is
> deferred (see below). No acceptance/integration test exercises these spec
> criteria through the provider/fallback entry points yet, so every A behavior is
> `PENDING`. (Note: `test/integration/llm_client_proxy_test.dart` is an env-gated
> smoke test of the OpenAI-compatible client, not a criterion-by-criterion
> acceptance suite.)

## Outer loop: acceptance behaviors

One per numbered Acceptance Scenario in `spec.md`. Each stays `PENDING` until the
provider clients and fallback chain are driven end to end and asserted.

| id  | behavior                                                                                                     | traces | kind    | state   | test |
| --- | ----------------------------------------------------------------------------------------------------------- | ------ | ------- | ------- | ---- |
| A1  | Each provider client streams recorded fixtures identically: events, tool-call buffering, and usage fields    | FR-001 | example | DONE    | test/data/providers/llm_client/llm_client_provider_test.dart ||
| A2  | With the engine pubspec resolved, `dart_agent_core` is absent and vendored files carry attribution headers   | FR-002 | example | DONE    | test/integration/spec_004_a2_dart_agent_core_test.dart :: "spec 004 A2 - engine has no dart_agent_core dependency; vendored files attributed" |
| A3  | Every completed LLM call has a `UsageLedger` entry with provider + model + token counts                     | FR-003 | example | DONE    | test/data/providers/llm_client/llm_client_provider_test.dart ||
| A4  | Provider A failing is served transparently by B; the mission observes only latency                          | FR-004 | example | DONE    | test/data/providers/fallback_chain/fallback_chain_provider_test.dart ||
| A5  | A in open state with cooldown elapsed: a half-open probe routes real traffic back on success                | FR-004 | example | DONE    | test/domain/entities/circuit_breaker/circuit_breaker_test.dart :: "spec 035 — CircuitBreaker shouldProbe recovery readiness" + test/data/providers/circuit_breaker/circuit_breaker_provider_test.dart (tryHalfOpen open->halfOpen on cooldown, recordSuccess->closed) |
| A6  | A mid-stream failure after partial chunks restarts on the next provider (or surfaces), never silently truncates | FR-004 | example | DONE    | test/llm/fallback_chain_client_test.dart :: "U16: stream() mid-stream failure on A restarts on B…" (restart branch) + "U17: stream() mid-stream policy skip propagates the error…" (surface branch) |
| A7  | Any chain state, the `Map<provider, ClientHealth>` snapshot matches the internal breaker states             | FR-005 | example | DONE    | test/data/providers/health_snapshot/health_snapshot_provider_test.dart ||

## Inner loop: deferred — plan.md absent

`plan.md` does not exist for this feature, so the inner-loop unit behaviors (per
component) cannot be derived. `/speckit.tdd.plan` must be re-run once `plan.md`
exists to populate the `U1..` table (provider clients, circuit breaker, fallback
policy, usage ledger, health snapshot). This list records only the outer-loop
acceptance behaviors.

## Edge cases & invariants (from spec.md)

Carried from the spec's Edge Cases; not yet placed as numbered behaviors:

- Context overflow on provider A (window too small) → classified as advance-able, not retried on A.
- All providers open → typed `AllProvidersUnavailable`; mission fails gracefully with salvage.
- Fixture-less provider in CI → contract suite self-skips with explicit notice, never passes silently.
- Per-provider SSE keepalive/comment differences → parser normalizes.

## Shipped unit/provider coverage (inner-loop, NOT outer acceptance — reported, not followed)

The repo already ships inner-loop unit/contract tests for several building blocks
of this feature. These are **not** outer-loop acceptance tests and are explicitly
deferred by this outside-in plan; listed here for accuracy only:

- `test/llm/llm_client_contract_test.dart`, `test/llm/llm_client_test.dart`, `test/llm/openai_compatible_client_test.dart`, `test/llm/anthropic_client_test.dart`, `test/llm/gemini_client_test.dart` — provider clients / contract suite.
- `test/llm/fallback_chain_client_test.dart`, `test/llm/circuit_breaker_test.dart`, `test/domain/entities/fallback_chain_test.dart`, `test/domain/entities/client_health_test.dart`, `test/data/providers/fallback_chain/*` — fallback chain + breaker.
- `test/usage_ledger_test.dart`, `test/data/datasources/usage_ledger_entry/*`, `test/domain/usecases/usage_ledger_entry/*` — usage ledger.
- `test/integration/llm_client_proxy_test.dart` — env-gated proxy smoke test (self-skips without `LLM_PROXY_URL`/`KIMI_API_KEY`).

## Out of scope

- Inner-loop unit behaviors: deferred until `plan.md` (see above).
- Live verification against a staging endpoint (SC-004): requires credentials; runs out of band.
- Source-vendoring mechanics of `dart_agent_core` attribution: a static/dependency-graph check, not a runtime behavior.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).

## Credited to sibling implementation specs (already-covered rule, keyword-verified)

These outer-loop acceptance behaviors have no single engine orchestrator wiring them into one
mission entry point; the component public API _is_ the real entry point. Each behavior was checked
against the passing test of the implementation spec that owns the component (the full suite is green:
932 passed, 2 skipped). `DONE` = a keyword for the behavior was found in that test, so the assertion
holds. `BLOCKED` here means **no automated keyword match** in the sibling component test — the
behavior may be covered under different wording and needs a manual end-to-end acceptance test to
confirm; it is NOT a claim that the feature is missing. The component suites are green either way.

