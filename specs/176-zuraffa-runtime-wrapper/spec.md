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
consumes pi's runtime (conversations, submissions, watches, tasks, outcomes,
extensions) and contributes only generic Zuraffa ecosystem integration — DI,
governance, MCP adaptation, observability, artifacts, evaluation, and host
injection. pi alone owns agent loops, provider/model calls, transcript/session
format, compaction, and durable execution; the wrapper carries no parallel
result models.

**Out of scope**: implementing any agent loop, provider client, transcript
store, compaction, or durable scheduler in this package; browser behavior
(`zuraffa_browser_core` / `zuraffa_browser_agent` own that); host application
composition (apps own the final wiring, credentials, and lifecycle); a
`zik_zak`-specific order agent; any new `pi` API — this package consumes the
public pi contracts named in FR-005 and keeps unstable details behind
interfaces. **Dependency**: this feature is born locked — it depends on
`arrrrny/pi#12` (the durable agent runtime slice) and cannot be implemented
until that lands.

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

1. **Given** injected in-memory host adapters, **When** the host opens a
   runtime and submits a prompt, **Then** it receives a pi conversation and a
   pi submission outcome without the wrapper re-implementing the agent loop.
2. **Given** a host that never registered credentials, **When** the runtime is
   opened, **Then** the wrapper fails with a typed configuration outcome
   naming the missing port — it never reads a global `GetIt.instance` behind
   the host's back.

---

### User Story 2 - Install Zuraffa extensions and governance (Priority: P2)

The host wants Zuraffa governance (tool allowlists, argument guards, risk
tiers, result minimization, PII scrubbing, audit, artifacts) applied to a pi
runtime. The wrapper installs generic Zuraffa extensions over pi's extension
registry and hooks (`beforeTool` / `afterTool` / provider-request hooks) and
host-provided extensions, without forking pi.

**Why this priority**: governance is the generic value this package adds on
top of pi; it is what makes the wrapper more than a passthrough.

**Independent Test**: register a deny-list governance policy and a scrubbing
policy through the wrapper, run a scripted conversation that attempts a
denied tool and returns PII, and assert the denial and redaction outcomes.

**Acceptance Scenarios**:

1. **Given** a deny-list policy, **When** the agent attempts a denied tool,
   **Then** the pi hook rejects it with a typed outcome before execution.
2. **Given** a scrubbing policy and content containing PII, **When** a tool
   result passes through `afterTool`, **Then** the model never receives the
   unredacted content, and a failed sanitizer fails closed with a typed
   outcome.
3. **Given** a host-provided extension, **When** the runtime is opened,
   **Then** the extension is installed into pi's registry without the wrapper
   re-implementing pi's extension system.

---

### User Story 3 - Host injection and lifecycle through DI (Priority: P2)

A host composes the wrapper through explicit dependency injection
(credentials/secure store, storage/environment, egress, telemetry, artifacts,
approval presentation, lifecycle) following the `zuraffa_permissions` /
`zuraffa_notifications` pattern: technology-agnostic ports, pure-Dart
in-memory adapters for tests, generated zfa entities/use cases where they
apply, and a `PackageModule`-style registration seam that is optional.

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
   wrapper registers them, **Then** registration is a thin optional seam —
   not a second agent system or module framework.
3. **Given** no browser package or host application is a dependency, **When**
   the package is analyzed, **Then** it imports neither.

---

### Edge Cases

- What happens when pi#12 has not landed? The wrapper cannot open a durable
  runtime — it fails with a typed "pi durable runtime unavailable" outcome at
  factory call time, and the package's public contracts still compile against
  the pi interfaces they name.
- How does the wrapper handle a host that injects a production adapter for
  one port and an in-memory adapter for another? Each port is independently
  injectable; the contract suite runs per-adapter.
- What happens when a pi API the wrapper consumes is unstable (pre-#12)?
  The wrapper isolates it behind a wrapper-owned interface so a pi signature
  change touches one adapter, not every host.
- What happens when a sanitizer or governance hook throws?
  It fails closed (typed outcome, no unredacted content reaches the model).
- What happens when a host registers `PackageModule` tools that overlap pi
  built-in tools? The wrapper's governance policy decides; the wrapper does
  not silently drop either.

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
  opens the appropriate pi runtime, installs extensions, and returns pi
  conversations, submissions, watches, tasks, and outcomes — with no parallel
  wrapper result models.
- **FR-004**: pi MUST own every agent loop, provider/model call,
  transcript/session format, compaction, and durable scheduler.
  `LlmToolLoop`, `MissionRunner`, and duplicate session/message models MUST NOT
  be carried into the new runtime.
- **FR-005**: The wrapper MUST consume the upstream/public pi contracts it
  needs (agent/conversation runtime, submission and outcome types, watch/task
  types, extension registry and hooks, storage and telemetry contracts) and
  MUST keep unstable or not-yet-landed details (pi#12 durable surface) behind
  wrapper-owned interfaces so a pi signature change touches one adapter. It
  MUST NOT invent pi#12 APIs as already implemented.
- **FR-006**: Host injection MUST cover credentials/secure storage,
  storage/environment, egress, telemetry, artifacts, approval presentation,
  and lifecycle; business logic MUST NOT read global `GetIt.instance` — it
  depends on the injected contracts.
- **FR-007**: Optional `PackageModule` integration MUST remain a registration
  seam, not an alternative module or agent system.
- **FR-008**: Pure-Dart in-memory ports MUST pass the same contract tests as
  production adapters, and the package MUST NOT import any browser package or
  host application.
- **FR-009**: Governance (allowlists, argument guards, risk classification,
  result minimization, PII scrubbing, audit) MUST be implemented through pi
  hook/extension primitives (`beforeTool`, `afterTool`, provider-request
  hooks), not a second policy engine; a failed sanitizer fails closed with a
  typed outcome.
- **FR-010**: The dependency on `arrrrny/pi#12` MUST be preserved; this
  feature is locked until pi#12 lands, and the package MUST NOT claim durable
  runtime behavior pi#12 does not yet provide.

### Key Entities *(include if feature involves data)*

- **Runtime factory/facade** (`ZuraffaAgent`/`AgentRuntimeFactory`): builds
  and opens the pi runtime from injected configuration; installs extensions;
  returns pi conversations/submissions/outcomes.
- **Host-injection ports**: credentials/secure store, storage/environment,
  egress, telemetry, artifacts, approval presentation, lifecycle — each
  technology-agnostic with a pure-Dart in-memory adapter.
- **Governance policy entities** (zfa-generated where applicable): allowlists,
  risk tiers, argument guards, minimization/redaction rules — consumed by pi
  hooks, not a separate execution engine.
- **Zuraffa extensions**: generic extensions (audit, telemetry, artifacts,
  MCP adaptation, evaluation) installed into pi's registry; host extensions
  passed through unchanged.

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
- **SC-005**: A denied tool and a PII-bearing tool result are handled by
  governance hooks with typed outcomes (denial before execution; redaction
  before the model sees content; fail-closed on sanitizer error).
- **SC-006**: The feature remains correctly blocked on `arrrrny/pi#12` — the
  wrapper's durable behavior is stated as available only once pi#12 lands.

## Assumptions

- The next-major version may make breaking API changes; repository and history
  are preserved but the public API is allowed a clean break (architecture plan
  §7.2).
- `zik_zak`'s existing order-agent code is a scratchpad, not a compatibility
  requirement; no behavior is preserved for its sake (plan §1, §7).
- pi publishes focused entry libraries (e.g. `package:pi/pi.dart`,
  `package:pi/durable.dart`) per plan §6.2; the wrapper imports the public
  pi contracts it needs and isolates pre-#12 instability behind its own
  interfaces (FR-005).
- `zuraffa_permissions` and `zuraffa_notifications` are read-only structural
  references; this package does not modify them.
- Generic Zuraffa governance/telemetry/MCP/eval extensions are product-neutral;
  browser-specific policy belongs to `zuraffa_browser_agent`, not here.