# Traceability: 015-mcp-client

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:beb33d53e461fd3a52d9c95aeedd6cf7c056f4adb059eb333886b47ef01603fc
statements: 11
automated: 11
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** an in-proc MCP server, **When** a tool is called, **Then** it executes without serialization overhead. | A1 | automated |
| AC-2 | 38 | 2. **Given** an SSE connection that drops mid-mission, **When** connectivity returns, **Then** the client reconnects and resumes. | A2 | automated |
| AC-3 | 40 | 3. **Given** an expiring token, **When** the auth callback rotates it, **Then** calls continue without rebuild. | A3 | automated |
| AC-4 | 53 | 4. **Given** a stdio server that crashes, **When** it restarts, **Then** the client reconnects automatically. | A4 | automated |
| AC-5 | 66 | 5. **Given** an MCP server, **When** tools are listed, **Then** they are registered in the tool registry. | A5 | automated |
| AC-6 | 68 | 6. **Given** a tools-changed notification, **When** received, **Then** the cache is invalidated and tools are re-listed. | A6 | automated |
| FR-001 | 75 | - **FR-001**: The MCP client MUST implement in-proc, SSE+Bearer, and stdio transports. | U1 | automated |
| FR-002 | 76 | - **FR-002**: SSE transport MUST support automatic reconnect with exponential backoff. | U2 | automated |
| FR-003 | 77 | - **FR-003**: SSE transport MUST support auth callback for token rotation. | U3 | automated |
| FR-004 | 78 | - **FR-004**: stdio transport MUST handle process crashes with bounded retries. | U4 | automated |
| FR-005 | 79 | - **FR-005**: Tool listing MUST be cached and invalidated on change notifications. | U5 | automated |

