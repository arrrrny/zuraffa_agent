# Feature Specification: Sub-agents & Declarative Agent Specs

**Feature Branch**: `005-subagents-and-declarative`

**Created**: 2026-08-18

**Status**: Draft

**Input**: Epic arrrrny/zuraffa_agent#1 §R5 — converted from issue #6. Kimi LaborMarket pattern for dispatch; declarative YAML specs with inheritance.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sub-agent dispatch with isolated contexts (Priority: P1)

As a parent agent, I dispatch sub-agents by type (e.g., explore / compose / verify) that run in their own context windows with their own tool allowlists and budgets; their internal chatter never pollutes my context — only their results return (Kimi LaborMarket pattern).

**Why this priority**: Context isolation is what makes sub-agents worth having; without it they're just more turns.

**Independent Test**: A parent dispatches an `explore` sub-agent whose 20-tool-call transcript never appears in the parent's context; only the result message does.

**Acceptance Scenarios**:

1. **Given** a registered sub-agent type, **When** dispatched, **Then** it runs with its own session (spec 002 tree), allowlist, and budget.
2. **Given** a completed sub-agent, **When** results return, **Then** the parent context receives the result summary only.
3. **Given** a sub-agent that fails, **Then** the parent receives a typed failure result and continues.

### User Story 2 - Resumable sub-agent instances (Priority: P2)

As a parent, I can resume a prior sub-agent instance (its session persists) to continue where it left off.

**Why this priority**: Long-horizon missions checkpoint work; Kimi persists instances under `session/subagents/<id>/`.

**Independent Test**: A sub-agent interrupted at step 5 resumes at step 5 with intact context after engine restart.

**Acceptance Scenarios**:

1. **Given** a persisted sub-agent instance id, **When** resumed, **Then** its session tree continues from the stored leaf.

### User Story 3 - Declarative agent specs (Priority: P1)

As an operator, I define agents declaratively in YAML — `extends` inheritance, tools, sub-agents, budgets, system prompt, risk tier — and the engine instantiates agents from specs; specs are data, not code.

**Why this priority**: Specs-as-data is the strategic pattern: ZikZak per-country playbooks (zik_zak architecture §9) become instances of agent specs — one mechanism, two uses.

**Independent Test**: A child spec inheriting from a base overrides tools+budgets; invalid specs are rejected with actionable diagnostics.

**Acceptance Scenarios**:

1. **Given** spec B `extends` spec A, **When** resolved, **Then** B inherits unspecified fields and overrides specified ones.
2. **Given** a spec referencing an unknown tool or cyclic inheritance, **When** loaded, **Then** it fails validation with a precise error.
3. **Given** a country playbook YAML, **When** loaded as a spec, **Then** agent behavior changes with no code change.

### User Story 4 - Built-in dispatch tool (Priority: P2)

As the model, I delegate via a first-class dispatch tool (Kimi's `Agent` tool analog) — the loop sees one tool; the engine handles instance lifecycle.

**Why this priority**: Model-usable delegation without custom wiring per app.

**Independent Test**: A mission whose model calls the dispatch tool spawns the right sub-agent type from tool arguments.

**Acceptance Scenarios**:

1. **Given** dispatch tool call with type + task, **Then** the engine creates/resumes the instance and awaits its result.

### Edge Cases

- Sub-agent dispatch from within a sub-agent → allowed, depth-capped (config), cycle-free by construction (new instance ids).
- Spec file hot-reload → validated before swap; running missions keep their resolved spec.
- Budget exhaustion inside sub-agent → typed budget outcome returned to parent (no hang).
- Parallel dispatch of N sub-agents → results collected in dispatch order.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST support named sub-agent types with isolated contexts, tool allowlists, and budgets.
- **FR-002**: Sub-agent instances MUST persist and be resumable across engine restarts.
- **FR-003**: Agent definitions MUST be expressible as declarative YAML specs with `extends` inheritance and validation diagnostics.
- **FR-004**: A built-in dispatch tool MUST expose sub-agent delegation to the model.
- **FR-005**: Context isolation MUST guarantee parent receives result summaries only.

### Key Entities

- **SubAgentType**: name, spec reference, allowlist, budget profile.
- **AgentSpec**: YAML document — tools, sub-agents, budgets, system prompt, risk tier, `extends`.
- **DispatchTool**: built-in delegation tool with instance lifecycle management.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Parent dispatches explore-type sub-agent; its context never pollutes the parent's (issue #6 AC).
- **SC-002**: Spec inheritance resolves; invalid specs rejected with diagnostics (AC).
- **SC-003**: Sub-agent instances persist + resume across engine restarts (AC).
- **SC-004**: A country playbook loaded as a spec changes agent behavior without code change (AC).

## Assumptions

- Specs resolve against the tool registry (spec 003) and budget profiles (plugin policy shell).
- Playbook serving (`raptorr.playbook_get`, arrrrny/raptorr#126) is upstream; this spec defines the loading side.

## Dependencies

- Issue: arrrrny/zuraffa_agent#6 · Epic: #1 · After: specs 001 (loop), 002 (sessions), 003 (tools) · Feeds: raptorr playbook_get (arrrrny/raptorr#126), zik_zak playbooks (arrrrny/zik_zak#175)
