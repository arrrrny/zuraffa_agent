# Traceability: 106-fail-closed-config

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:0f59d42fa0c7726d981c75f8ae96eec78dacb3af843603e20dfb25985d0817c4
statements: 8
automated: 8
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 79 | 1. **Given** construction of the provider-configuration service without an injected configuration, **When** the constructor runs, **Then** it throws immediately naming the missing configuration, the same holds for the agent-spec service, and a configured service returns exactly the injected configuration. | A1 | automated |
| AC-2 | 93 | 2. **Given** the library and the fallback chain defaults, **When** a case-insensitive search runs for the gateway host and the model id, **Then** it returns zero hits, the fallback chain's default ids contain no vendor-specific id, and the integration test's vendor defaults are gone (env-required instead). | A2 | automated |
| AC-3 | 106 | 3. **Given** an explicitly configured provider, **When** the same interface is queried, **Then** it returns the injected configuration and the count surface reports the configured set without invention. | A3 | automated |
| FR-001 | 122 | - **FR-001**: constructing the provider-configuration service without | U1 | automated |
| FR-002 | 126 | - **FR-002**: constructing the agent-spec service without an injected | U3 | automated |
| FR-003 | 129 | - **FR-003**: a configured service returns the injected configuration | U4 | automated |
| FR-004 | 132 | - **FR-004**: after this spec, a case-insensitive search for the | U5 | automated |
| FR-005 | 139 | - **FR-005**: the integration test requires explicit environment | U5 | automated |

