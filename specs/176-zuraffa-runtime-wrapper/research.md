# Phase 0 Research: Zuraffa runtime wrapper around pi

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

All Technical Context entries were resolved from the normative architecture
plan, the issue, and read-only inspection of the reference packages and the
`pi` checkout at `arrrrny/pi` `master`. No entry required a NEEDS
CLARIFICATION guess.

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

- **Decision**: The wrapper consumes pi's real public contracts from
  `package:pi/pi.dart`: `Agent` and `Conversation` (`src/harness.dart` —
  `Conversation.create`/`resume`/`prompt`/`fork`/`compact`, `Stream<AgentEvent>
  get events`), `SessionStorage`, `AgentTool`, the `BeforeToolCall`/
  `AfterToolCall` hook typedefs, the `AgentOptions` seams
  `beforeToolCall`/`afterToolCall`/`transformContext`/`convertToLlm`, and the
  `Model`/`Usage`/`AgentMessage` family plus `CompactionSettings`/
  `CompactionResult`. The pi#12 surface (submissions, watches, tasks,
  outcomes, scheduler, approvals, signals) does not exist yet; those types are
  consumed *when they land*, and until then the package declares no stand-in
  for them (FR-010) — implementation starts after pi#12.
- **Rationale**: FR-005 / issue constraint "do not invent pi#12 APIs as
  already implemented."
- **Verified against `arrrrny/pi` `master`** (`pi_agent/lib/`): `pi.dart`
  exports `agent`, `agent_loop`, `harness`, `subagent`, `tools`, `session`,
  `session_storage`, `skills`, `prompt_templates`, `execution_env`,
  `compaction`, `sse_parser`, `llm_client`, `conversion`. `harness.dart`
  declares `class Conversation` (line 37) with the lifecycle methods above.
  Greps for `ExtensionRegistry`, `AgentExtension`, `onProviderRequest`,
  `ProviderRequestHook`, `beforeProvider` return **zero** matches, and no
  `Submission`/`Watch`/`Task`/`Outcome` class exists.
- **Alternatives considered**: Declaring pi#12 types as available now —
  rejected (would not compile and violates FR-005); creating parallel wrapper
  result models — rejected by the operator's blocking review and FR-003.

### D3b — The seams pi actually has (design consequence)

Because pi's only configuration seam is `AgentOptions`, the wrapper's
extension mechanism cannot be "install into pi's extension registry" — there
is none. It is instead a composition step: the wrapper builds
`beforeToolCall`, `afterToolCall`, `transformContext`, and `convertToLlm` from
the installed `ZuraffaExtension`s and hands them to `AgentOptions`. This is the
`ZuraffaExtension` seam in spec FR-009 / `contracts/governance-hooks.md`.

## D4 — Governance placement

- **Decision**: This feature ships the **seam only**: one composition point
  that turns `ZuraffaExtension` hook bodies into `AgentOptions`. Governance
  policy — allowlists, argument guards, risk tiers, minimization, PII
  scrubbing, audit — is issue #205 and arrives as one such extension. Where
  #205 needs to scrub *model-bound* content it uses `transformContext` (the
  last thing to touch `List<AgentMessage>` before the provider call), not a
  provider-request hook, which pi does not have.
- **Rationale**: Operator's blocking review item 3 ("keep governance behavior
  in #205"); FR-009.
- **Alternatives considered**: Implementing the policy in this package —
  rejected (out of scope per the operator, and it would make the "generic
  wrapper" a policy engine); naming a provider-request hook — rejected (no
  such seam exists in pi).

## D5 — Host injection and DI

- **Decision**: Ports for credentials/secure store, storage/environment,
  egress, telemetry, artifacts, approval presentation, lifecycle; pure-Dart
  in-memory adapters for tests; explicit DI registration following
  `setupDependencies(GetIt)` / `registerXxxDependencies` pattern from
  `zuraffa_permissions`. Business logic never reads `GetIt.instance`. Ports
  are required non-nullable constructor arguments, so omission is a compile
  error.
- **Rationale**: FR-006; plan §5.4, §7.3. Verified: `zuraffa_permissions`
  uses `setupDependencies(GetIt)` in generated `lib/src/di/index.dart` and
  exports `GetIt` only from the generated service_locator.
- **Alternatives considered**: Global service-locator reads inside the
  wrapper — rejected (FR-006); a nullable port registry validated at `open()`
  — rejected (it converts a compile-time guarantee into a runtime check the
  contract then has to advertise, and produces a `missingPort` outcome no test
  can reach); per-port ad-hoc wiring — rejected (plan §7.1 explicit injectable
  DI).

## D6 — Dependency and locking

- **Decision**: Preserve `Depends on: arrrrny/pi#12` (issue body line) and
  implement after it lands. Before pi#12 there is nothing to run: no durable
  surface is claimed, emulated, or stubbed, and the package's public API names
  pi types rather than wrapper aliases of them.
- **Rationale**: Issue 204 acceptance; fleet dependency rule; FR-010; the
  operator's blocking review item 2 ("no pre-parity fallback to design").
- **Alternatives considered**: A non-durable fallback that opens a
  conversation and degrades the durable verbs — rejected by the operator (it
  claims a durable surface that does not exist and forces pre-parity
  substitute types); implementing durable behavior in the wrapper — rejected
  (FR-004); dropping the dependency — rejected (issue requirement).

## D7 — Testing strategy

- **Decision**: Pure-Dart contract tests; in-memory adapters run the same
  suite as production adapters; `dart test -j 2` (fleet test-concurrency
  guard, deliberately over the repo's `dart_test.yaml` `concurrency: 4`).
  Extension-seam tests assert two things only: an installed extension's hooks
  reach the opened runtime's `AgentOptions`, and with no extension the wrapper
  installs none.
- **Rationale**: FR-008, SC-002, SC-005; plan §6.4.
- **Alternatives considered**: Live provider tests — rejected (paid live
  providers never unit-test dependencies, plan §6.4); per-adapter test
  branching — rejected (SC-002).

## D8 — Out-of-scope confirmations

- **Decision**: No browser package or host app imports (FR-008/SC-004); no
  `zik_zak` order-agent behavior preserved (plan §1); no Flutter dependency
  (constitution VII); no new agent loop/provider/transcript/compaction/
  durable scheduler (FR-004/SC-003); no governance policy (#205); no
  performance claim beyond pass-through scope.
- **Rationale**: Issue 204 acceptance criteria; plan §5, §7.2, §9.2;
  operator's blocking review items 3 and 5.
- **Alternatives considered**: Carrying `LlmToolLoop`/`MissionRunner` forward
  — rejected (FR-004 explicitly forbids).
