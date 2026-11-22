**Template Version**: `zuraffa-1.0`

# Feature Specification: Zuraffa runtime wrapper around pi

**Branch**: `176-zuraffa-runtime-wrapper` (off master) | **Date**: 2026-11-22

**Status**: Draft

**Input**: GitHub issue #204 — "Build the Zuraffa runtime wrapper around pi"
(https://github.com/arrrrny/zuraffa_agent/issues/204). Normative architecture:
https://github.com/arrrrny/zuraffa_browser/blob/master/handoffs/2026-11-22-pi-zuraffa-browser-agent-architecture-plan.md
(§7 "Workstream B — rebuild `zuraffa_agent` as a Zuraffa wrapper around pi").

## Summary

`zuraffa_agent` currently ships its own agent loop (`LlmToolLoop`,
`MissionRunner`), its own session/message models, its own provider loop, and
its own compaction — a second agent runtime that duplicates what pi already
owns and drifts semantically from it. This spec rebuilds `zuraffa_agent` as a
**thin, zfa-native generic wrapper around pi**: a next-major package that
consumes pi's runtime (conversations today; submissions, watches, tasks and
outcomes once pi#12 lands) and contributes only the generic Zuraffa ecosystem
integration that is not policy — DI, lifecycle, and the extension-installation
seam that Zuraffa capability extensions (governance, observability, artifacts,
MCP adaptation, evaluation) plug into. pi alone owns agent loops,
provider/model calls, transcript/session format, compaction, and durable
execution; the wrapper carries no parallel result models.

**Out of scope**: implementing any agent loop, provider client, transcript
store, compaction, or durable scheduler in this package; **governance policy
itself** (allowlists, argument guards, risk tiers, result minimization, PII
scrubbing, audit) — that is issue #205, which installs through this feature's
extension seam; browser behavior (`zuraffa_browser_core` /
`zuraffa_browser_agent` own that); host application composition (apps own the
final wiring, credentials, and lifecycle); a `zik_zak`-specific order agent;
any new `pi` API. **Dependency**: this feature is born locked on
`arrrrny/pi#12` (the durable agent runtime slice). Implementation starts after
pi#12 lands; this feature designs no pre-pi#12 substitute runtime, no
non-durable fallback, and no outcome model of its own.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open a pi runtime and run a conversation (Priority: P1)

A host application (e.g. a Zuraffa app) wants to run an agent without
reimplementing one. It calls the wrapper's runtime factory with injected
configuration (credentials, storage, egress, telemetry, artifacts, approvals),
receives a pi runtime opened through the wrapper, submits a prompt, and reads
the returned pi conversation, submission, and outcome objects directly.

**Why this priority**: this is the core value — a working pi runtime behind a
Zuraffa DI seam. Without it nothing else matters.

**Independent Test**: construct the factory with pure-Dart in-memory adapters
(scripted credentials, in-memory storage, in-memory egress), open a runtime,
submit a prompt against a scripted provider, and assert the returned
conversation/submission/outcome are pi types — no wrapper result models.

**Acceptance Scenarios**:

1. **Given** injected in-memory host adapters and a pi#12-capable pi, **When**
   the host opens a runtime and submits a prompt, **Then** it receives pi's
   conversation and submission/outcome objects without the wrapper
   re-implementing the agent loop.
2. **Given** a host that never registered a required port, **Then** the
   package does not compile — `AgentPortRegistry` declares every port as a
   required non-nullable constructor argument, so composition cannot omit one
   and no global `GetIt.instance` lookup exists to fall back to.

---

### User Story 2 - Install extensions through the wrapper seam (Priority: P2)

The host wants Zuraffa capability extensions (governance, observability,
artifacts, MCP adaptation, evaluation) and its own extensions applied to a pi
runtime. The wrapper exposes one extension-installation seam that composes
those extensions into pi's real hook surfaces — `beforeToolCall`,
`afterToolCall`, `transformContext`, `convertToLlm` — without forking pi and
without owning any policy.

**Why this priority**: the seam is the generic value this package adds on top
of pi; every capability extension in the ecosystem installs through it.

**Independent Test**: install one test extension through the seam, open a
runtime, and assert the extension's hooks reached the opened pi runtime;
repeat with no extension and assert the wrapper contributed no hooks of its
own.

**Acceptance Scenarios**:

1. **Given** a host-provided extension, **When** the runtime is opened,
   **Then** the extension's hook bodies are composed into the opened pi
   runtime's `beforeToolCall`/`afterToolCall`/`transformContext`/`convertToLlm`
   options, and the wrapper re-implements none of pi's execution semantics.
2. **Given** no extension, **When** the runtime is opened, **Then** the
   wrapper installs no hook and no policy of its own — the runtime behaves as
   pi behaves.
3. **Given** an extension from the governance workstream (#205), **When** it
   is installed, **Then** it uses this seam unchanged and the wrapper still
   owns no policy engine.

---

### User Story 3 - Host injection and lifecycle through DI (Priority: P2)

A host composes the wrapper through explicit dependency injection
(credentials/secure store, storage/environment, egress, telemetry, artifacts,
approval presentation, lifecycle) following the `zuraffa_permissions` /
`zuraffa_notifications` pattern: technology-agnostic ports, pure-Dart
in-memory adapters for tests, generated zfa entities/use cases where they
apply, and the scaffolded `PackageModule` seam that is optional.

**Why this priority**: this is the structural contract every host depends on;
it mirrors the two reference packages and keeps business logic free of global
service-locator reads.

**Independent Test**: boot the wrapper with only in-memory adapters and run
the full contract suite (same suite production adapters run); assert no
business-logic path reads `GetIt.instance` directly.

**Acceptance Scenarios**:

1. **Given** only pure-Dart in-memory adapters, **When** the host registers
   the wrapper via its DI seam, **Then** the whole package boots and passes
   the same contract tests as production adapters.
2. **Given** a host that also publishes `PackageModule` tools, **When** the
   wrapper registers them, **Then** registration is the scaffolded
   `PackageModule` seam — not a second agent system or module framework.
3. **Given** no browser package or host application is a dependency, **When**
   the package is analyzed, **Then** it imports neither.

---

### Edge Cases

- What happens before pi#12 has landed? Nothing runs: the feature is born
  locked on `arrrrny/pi#12`, and implementation starts after it lands. There
  is no non-durable fallback, no emulated durable verb, and no placeholder
  pi#12 type in this package.
- How does the wrapper handle a host that injects a production adapter for
  one port and an in-memory adapter for another? Each port is independently
  injectable; the contract suite runs per-adapter.
- What happens when a pi API the wrapper constructs changes? The adapter layer
  absorbs the construction/lifecycle drift; pi *type* references elsewhere in
  the package are direct and declare `pi` themselves, so a type change surfaces
  at analyze time instead of being silently masked by a wrapper alias.
- What happens when a host registers `PackageModule` tools that overlap pi
  built-in tools? Not the wrapper's decision and not the wrapper's policy: the
  seam registers both, and governance (#205) decides at tool-call time.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The package MUST be a next-major zfa-native package created with
  `zfa package create`, with domain/application types generated via
  `zfa entity create` and `zfa make` where applicable; generated output is
  never hand-edited.
- **FR-002**: The package MUST follow `zuraffa_permissions` for
  technology-agnostic ports, generated domain/use-case stacks, pure-Dart
  in-memory adapters, and explicit injectable DI; and `zuraffa_notifications`
  for composed capabilities (a service composing ports rather than owning
  lower-level implementations).
- **FR-003**: The package MUST provide a thin runtime factory/facade that
  opens the appropriate pi runtime, installs extensions through the seam, and
  returns pi conversations, submissions, watches, tasks, and outcomes — with
  no parallel wrapper result models, aliases, or pre-parity substitutes.
- **FR-004**: pi MUST own every agent loop, provider/model call,
  transcript/session format, compaction, and durable scheduler.
  `LlmToolLoop`, `MissionRunner`, and duplicate session/message models MUST NOT
  be carried into the new runtime.
- **FR-005**: The wrapper MUST consume the real pi contracts it needs —
  `Agent`/`Conversation` (`package:pi/harness.dart`), the `AgentEvent` stream,
  `SessionStorage`, `AgentTool` and the `BeforeToolCall`/`AfterToolCall` hooks,
  `AgentOptions.transformContext`/`convertToLlm`, `Model`/`Usage`/`AgentMessage`,
  `CompactionSettings`/`CompactionResult` — and MUST name only seams pi
  actually has. It MUST NOT invent a pi seam (there is no extension registry
  and no provider-request hook in the Dart port) and MUST NOT invent pi#12 APIs
  as already implemented. The package declares `pi` directly and MAY reference
  and re-export pi's public types; only pi *runtime construction* is confined to
  the adapter layer.
- **FR-006**: Host injection MUST cover credentials/secure storage,
  storage/environment, egress, telemetry, artifacts, approval presentation,
  and lifecycle; business logic MUST NOT read global `GetIt.instance` — it
  depends on the injected contracts. Every port MUST be a required
  non-nullable constructor argument, so a missing port is a compile error
  rather than a runtime outcome.
- **FR-007**: Optional `PackageModule` integration MUST remain the scaffolded
  registration seam (`PackageModule` subclass emitted by `zfa package create`
  → `registerDependencies(ZuraffaDIContainer)`), not an alternative module or
  agent system.
- **FR-008**: Pure-Dart in-memory ports MUST pass the same contract tests as
  production adapters, and the package MUST NOT import any browser package or
  host application.
- **FR-009**: The package MUST expose exactly one extension-installation seam
  that composes Zuraffa extensions into pi's real hook surfaces
  (`beforeToolCall`, `afterToolCall`, `transformContext`, `convertToLlm`) and
  MUST NOT define a policy engine. Governance policy (allowlists, argument
  guards, risk classification, minimization, PII scrubbing, audit) is issue
  #205 and installs through this seam.
- **FR-010**: The dependency on `arrrrny/pi#12` MUST be preserved and the
  feature is locked until pi#12 lands; implementation starts after it. The
  package MUST NOT claim, emulate, or fall back to any durable runtime
  behavior pi#12 does not provide.

### Key Entities *(include if feature involves data)*

- **Runtime factory/facade** (`ZuraffaAgent`/`AgentRuntimeFactory`): builds
  and opens the pi runtime from injected configuration; installs extensions;
  returns pi conversations/submissions/outcomes.
- **Host-injection ports**: credentials/secure store, storage/environment,
  egress, telemetry, artifacts, approval presentation, lifecycle — each
  technology-agnostic, required at construction, with a pure-Dart in-memory
  adapter.
- **Extension seam** (`ZuraffaExtension`): a wrapper-owned value the bootstrap
  composes down into pi's `AgentOptions` hook surfaces. It carries hook bodies;
  it carries no policy of its own, and #205's governance rules arrive as one
  such extension.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A host can open a pi runtime and complete a scripted conversation
  end-to-end through the wrapper with only pure-Dart in-memory adapters, and
  the returned conversation/submission/outcome are pi types.
- **SC-002**: The full in-memory contract suite passes identically against
  in-memory and production adapters (same tests, no per-adapter branching).
- **SC-003**: The package contains zero re-implementations of agent loop,
  provider call, transcript/session store, compaction, or durable scheduler —
  verified by the absence of `LlmToolLoop`/`MissionRunner`/duplicate session
  models and by import/dependency analysis.
- **SC-004**: The package imports no browser package and no host application;
  `dart analyze` passes with the dependency rule enforced.
- **SC-005**: One extension installed through the seam reaches the opened
  runtime's `AgentOptions` hooks, and with no extension installed the wrapper
  contributes zero hooks — the seam adds wiring, not policy.
- **SC-006**: The feature remains correctly blocked on `arrrrny/pi#12` — no
  durable behavior is claimed anywhere in the spec, plan, contracts, or
  quickstart until that dependency lands.

## Assumptions

- The next-major version may make breaking API changes; repository and history
  are preserved but the public API is allowed a clean break (architecture plan
  §7.2).
- `zik_zak`'s existing order-agent code is a scratchpad, not a compatibility
  requirement; no behavior is preserved for its sake (plan §1, §7).
- pi#12 lands the durable surface (submissions, watches, tasks, outcomes,
  scheduler, approvals, signals) together with whatever extension registry the
  durable port ships; this feature consumes those pi types directly and does
  not define stand-ins for them (FR-005, FR-010).
- `zuraffa_permissions` and `zuraffa_notifications` are read-only structural
  references; this package does not modify them.
- Generic Zuraffa governance/telemetry/MCP/eval extensions are product-neutral;
  browser-specific policy belongs to `zuraffa_browser_agent`, not here.
