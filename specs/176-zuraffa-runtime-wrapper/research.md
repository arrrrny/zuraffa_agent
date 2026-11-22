# Phase 0 Research: Zuraffa runtime wrapper around pi

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

All Technical Context entries were resolved from the normative architecture
plan, the issue, and read-only inspection of the reference packages and the
current `pi` checkout. No entry required a NEEDS CLARIFICATION guess.

## D1 — Package skeleton (zfa)

- **Decision**: Scaffold with `zfa package create` (standard domain/data
  layout, runtime module, package registrar, test harness), then generate
  applicable domain/application types with `zfa entity create` / `zfa make`.
- **Rationale**: Constitution I (CLI-Built Only) and FR-001; `zfa package
  create --help` confirms it produces a package that "passes analysis and
  codegen with zero manual edits."
- **Alternatives considered**: Hand-rolling the package layout — rejected
  (constitution I); adapting the current dual-stack tree piecemeal — rejected
  (architecture plan §7.2 explicitly wants a clean next-major API).

## D2 — Reference structure

- **Decision**: Follow `zuraffa_permissions` (ports + Zorphy entities +
  generated use cases + pure-Dart in-memory adapters + explicit DI) and
  `zuraffa_notifications` (composed capability service). Both are read-only
  references (verified: `zuraffa_permissions` is a federated
  `packages/zuraffa_permissions/` monorepo with `PermissionPort`,
  `InMemoryPermissionAdapter`, generated `lib/src/di/`, `service_locator.dart`;
  `zuraffa_notifications` composes a port, inbox, persistence, and reporting).
- **Rationale**: FR-002; these are the architecture plan §7.1's named models.
- **Alternatives considered**: `PackageModule`/`PackageAgentTools` as the
  template — rejected (plan §7.1: "optional runtime-registration seam, not
  the architectural template").

## D3 — pi contract surface and the pi#12 boundary

- **Decision**: The wrapper consumes pi's public contracts that exist today
  (`Agent`, `Conversation` via `package:pi/pi.dart` — harness.dart
  `Conversation.create/resume/prompt/fork/compact`, `AgentEvent` stream,
  `SessionStorage`, `AgentTool`, hooks `BeforeToolCallHook`/
  `AfterToolCallHook`, `Model`/`Usage`/`AgentMessage` types) and isolates the
  not-yet-landed durable surface (submissions, watches, tasks, outcomes,
  durable scheduler, approvals, signals — pi#12) behind wrapper-owned
  interfaces in `src/pi/`.
- **Rationale**: FR-005 / issue constraint "do not invent pi#12 APIs as
  already implemented." Verified against the local `pi` checkout
  (`/Users/arrrrny/Developer/pi/pi_agent`): `pi.dart` exports
  agent/harness/subagent/tools/session/session_storage/skills/
  prompt_templates/execution_env/compaction/sse_parser/llm_client/conversion;
  no `Submission`/`Watch`/`Task`/`Outcome` classes exist yet — those are
  pi#12 (issue #12 "dart-port: port the durable agent runtime").
- **Alternatives considered**: Declaring pi#12 types as available now —
  rejected (would break compilation and violate FR-005); creating parallel
  wrapper result models — rejected (FR-003).

## D4 — Governance through pi hooks

- **Decision**: Implement allowlists, argument guards, risk tiers via
  `beforeTool` hooks; minimization, PII scrubbing, artifact refs, redaction via
  `afterTool`/provider-request hooks; approvals via durable `beforeTool` sleep
  gates + signals + memoized deadlines (once pi#12 lands); audit/metrics via
  pi telemetry/hooks bridged to Zuraffa ports. A failed sanitizer fails closed
  with a typed outcome.
- **Rationale**: FR-009; plan §7.4.
- **Alternatives considered**: A second policy engine — rejected (plan §7.4:
  "Governance implemented through pi primitives").

## D5 — Host injection and DI

- **Decision**: Ports for credentials/secure store, storage/environment,
  egress, telemetry, artifacts, approval presentation, lifecycle; pure-Dart
  in-memory adapters for tests; explicit DI registration following
  `setupDependencies(GetIt)` / `registerXxxDependencies` pattern from
  `zuraffa_permissions`. Business logic never reads `GetIt.instance`.
- **Rationale**: FR-006; plan §5.4, §7.3. Verified: `zuraffa_permissions`
  uses `setupDependencies(GetIt)` in generated `lib/src/di/index.dart` and
  exports `GetIt` only from the generated service_locator.
- **Alternatives considered**: Global service-locator reads inside the
  wrapper — rejected (FR-006); per-port ad-hoc wiring — rejected (plan §7.1
  explicit injectable DI).

## D6 — Dependency and locking

- **Decision**: Preserve `Depends on: arrrrny/pi#12` (issue body line).
  The package's durable behavior is stated as available only once pi#12
  lands; the factory fails with a typed "pi durable runtime unavailable"
  outcome before then. The `pubspec.yaml` dependency on `pi` is declared
  but the durable surface is interface-isolated.
- **Rationale**: Issue 204 acceptance + fleet dependency rule; FR-010.
- **Alternatives considered**: Implementing durable behavior in the wrapper —
  rejected (FR-004); dropping the dependency — rejected (issue requirement).

## D7 — Testing strategy

- **Decision**: Pure-Dart contract tests; in-memory adapters run the same
  suite as production adapters; `dart test -j 2` (fleet test-concurrency
  guard). Governance tests assert deny-before-execution and
  redact-before-model with fail-closed sanitizer behavior.
- **Rationale**: FR-008, SC-002, SC-005; plan §6.4.
- **Alternatives considered**: Live provider tests — rejected (paid live
  providers never unit-test dependencies, plan §6.4); per-adapter test
  branching — rejected (SC-002).

## D8 — Out-of-scope confirmations

- **Decision**: No browser package or host app imports (FR-008/SC-004); no
  `zik_zak` order-agent behavior preserved (plan §1); no Flutter dependency
  (constitution VII); no new agent loop/provider/transcript/compaction/
  durable scheduler (FR-004/SC-003).
- **Rationale**: Issue 204 acceptance criteria; plan §5, §7.2, §9.2.
- **Alternatives considered**: Carrying `LlmToolLoop`/`MissionRunner` forward
  — rejected (FR-004 explicitly forbids).