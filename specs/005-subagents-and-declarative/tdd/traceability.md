# Traceability: 005-subagents-and-declarative

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:38534e500e724b1aef55cbfd706b9dc35b81c68cba1a70f5a35457c92f79fdb1
statements: 13
automated: 13
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a registered sub-agent type, **When** dispatched, **Then** it runs with its own session (spec 002 tree), allowlist, and budget. | A1 | automated |
| AC-2 | 27 | 2. **Given** a completed sub-agent, **When** results return, **Then** the parent context receives the result summary only. | A2 | automated |
| AC-3 | 29 | 3. **Given** a sub-agent that fails, **Then** the parent receives a typed failure result and continues. | A3 | automated |
| AC-4 | 42 | 4. **Given** a persisted sub-agent instance id, **When** resumed, **Then** its session tree continues from the stored leaf. | A4 | automated |
| AC-5 | 55 | 5. **Given** spec B `extends` spec A, **When** resolved, **Then** B inherits unspecified fields and overrides specified ones. | A5 | automated |
| AC-6 | 57 | 6. **Given** a spec referencing an unknown tool or cyclic inheritance, **When** loaded, **Then** it fails validation with a precise error. | A6 | automated |
| AC-7 | 59 | 7. **Given** a country playbook YAML, **When** loaded as a spec, **Then** agent behavior changes with no code change. | A7 | automated |
| AC-8 | 72 | 8. **Given** dispatch tool call with type + task, **Then** the engine creates/resumes the instance and awaits its result. | A8 | automated |
| FR-001 | 86 | - **FR-001**: The engine MUST support named sub-agent types with isolated contexts, tool allowlists, and budgets. | U1 | automated |
| FR-002 | 87 | - **FR-002**: Sub-agent instances MUST persist and be resumable across engine restarts. | U2 | automated |
| FR-003 | 88 | - **FR-003**: Agent definitions MUST be expressible as declarative YAML specs with `extends` inheritance and validation diagnostics. | U3 | automated |
| FR-004 | 89 | - **FR-004**: A built-in dispatch tool MUST expose sub-agent delegation to the model. | U4 | automated |
| FR-005 | 90 | - **FR-005**: Context isolation MUST guarantee parent receives result summaries only. | U5 | automated |

