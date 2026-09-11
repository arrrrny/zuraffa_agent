# Traceability: 115-agent-platform-packages

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:c17e8c0d2d5281bd09a76ff39a48b8704cdac4d3ce884b5276dc2367df985496
statements: 11
automated: 11
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 72 | 1. **Given** a platform that reports home `/support`, **When** the | A1 | automated |
| AC-2 | 77 | 2. **Given** a platform that reports an empty home, **When** the resolver | A2 | automated |
| AC-3 | 96 | 3. **Given** a fake secure store, **When** a key is written then read, | A3 | automated |
| AC-4 | 99 | 4. **Given** an empty or whitespace key, **When** a secure operation is | A4 | automated |
| AC-5 | 120 | 5. **Given** the repo tree, **When** the four packages are inspected, | A5 | automated |
| AC-6 | 126 | 6. **Given** a certified channel fake replaying host responses, **When** | A6 | automated |
| FR-001 | 136 | - **FR-001**: `AgentPlatform` MUST define the host seam — | U1 | automated |
| FR-002 | 142 | - **FR-002**: `AgentHomeResolver` MUST compose | U2 | automated |
| FR-003 | 146 | - **FR-003**: Secure-store operations MUST validate keys (non-empty, | U3 | automated |
| FR-004 | 151 | - **FR-004**: The federated packages MUST ship with correct pubspec | U4 | automated |
| FR-005 | 158 | - **FR-005**: The channel contract MUST be exactly: channel | U5 | automated |

