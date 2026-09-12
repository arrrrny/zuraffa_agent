# Traceability: 108-mcp-resilience

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:b8a800a1d1a4328d4a47798ab90ffd5ed600707c6eb5bcf3edc92b65f4c8cbe6
statements: 9
automated: 9
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 74 | 1. **Given** a never-responding MCP server with a configured call timeout, **When** a call is made, **Then** the typed timeout error returns after roughly the configured duration (not 30s when 50ms is configured), the 30s default applies without an override, and a fast server is unaffected. | A1 | automated |
| AC-2 | 90 | 2. **Given** a failure threshold of N, **When** consecutive failures accumulate, **Then** the Nth failure opens the breaker, call N+1 returns `circuit-open` without touching the wire, after the cooldown the next call probes, a successful probe closes the breaker, a failing probe re-opens it, and a success in closed state resets the consecutive-failure count. | A2 | automated |
| AC-3 | 104 | 3. **Given** a read-only tool whose first attempt fails transiently and second succeeds (and a non-read-only tool in the same situation), **When** each is called, **Then** the read-only tool is called exactly twice and the non-read-only tool exactly once, and a timeout is never retried regardless of the read-only mark. | A3 | automated |
| FR-001 | 119 | - **FR-001**: `callTool` accepts a per-call timeout; on expiry it | U7 | automated |
| FR-002 | 122 | - **FR-002**: a timed-out call is never retried, whatever the | U10 | automated |
| FR-003 | 125 | - **FR-003**: with a breaker configured, N consecutive call failures | U5 | automated |
| FR-004 | 130 | - **FR-004**: with a retry config supplied for a read-only call, | U11 | automated |
| FR-005 | 135 | - **FR-005**: the `McpClient` contract documentation states the timeout, | U5 | automated |
| FR-006 | 138 | - **FR-006**: `readOnly` is an additive, default-false descriptor flag. | U12 | automated |

