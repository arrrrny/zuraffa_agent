# Traceability: 003-tools-and-mcp

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:f190c515581309dade880b42b10fc824ceee9c2cc30213a38a244c09b60a3c7d
statements: 14
automated: 14
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** tools registered from any source, **When** the loop emits a call, **Then** the registry resolves it regardless of origin. | A1 | automated |
| AC-2 | 27 | 2. **Given** arguments violating a tool's JSON Schema, **When** dispatched, **Then** a validation error returns as the tool result (mission continues). | A2 | automated |
| AC-3 | 29 | 3. **Given** a parallel-execution batch, **When** dispatched, **Then** tools run concurrently with results collected in call order. | A3 | automated |
| AC-4 | 42 | 4. **Given** risk `confirm`, **When** dispatched, **Then** execution awaits the approval callback; denial or timeout yields a denied tool result. | A4 | automated |
| AC-5 | 44 | 5. **Given** risk `admin` on a non-internal mission, **When** dispatched, **Then** it is denied without invoking the implementation. | A5 | automated |
| AC-6 | 57 | 6. **Given** an SSE connection that drops mid-mission, **When** connectivity returns, **Then** the client reconnects (backoff) and resumes tool listing/calls. | A6 | automated |
| AC-7 | 59 | 7. **Given** an expiring token, **When** the auth callback rotates it, **Then** calls continue without manager rebuild. | A7 | automated |
| AC-8 | 61 | 8. **Given** in-proc tools, **When** called in a tight loop, **Then** no serialization boundary exists (pass-by-reference with defensive arg copy). | A8 | automated |
| AC-9 | 74 | 9. **Given** an oversized tool result, **When** returned to the loop, **Then** the model sees summary + artifactRef only. | A9 | automated |
| FR-001 | 88 | - **FR-001**: One tool registry MUST serve DDA, generated, and remote-MCP tools in a single namespace. | U1 | automated |
| FR-002 | 89 | - **FR-002**: Tool dispatch MUST validate arguments against JSON Schema and support sequential/parallel modes. | U2 | automated |
| FR-003 | 90 | - **FR-003**: `safe\|confirm\|admin` risk MUST be first-class tool metadata; dispatch MUST enforce approval/permission semantics. | U3 | automated |
| FR-004 | 91 | - **FR-004**: The MCP client MUST implement in-proc, SSE+Bearer (reconnect, auth callback), and stdio transports. | U4 | automated |
| FR-005 | 92 | - **FR-005**: Oversized results MUST be summarized + artifactRef'd before entering model context. | U5 | automated |

