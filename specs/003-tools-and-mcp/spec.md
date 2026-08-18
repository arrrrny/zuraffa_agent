# Feature Specification: Tools & MCP Client

**Feature Branch**: `003-tools-and-mcp`

**Created**: 2026-08-18

**Status**: Draft

**Input**: Epic arrrrny/zuraffa_agent#1 §R3 — converted from issue #4. Makes zuraffa MCP-native in both directions (server side already exists: arrrrny/zuraffa#384).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registry-backed tool model (Priority: P1)

As the engine, I resolve tools from one registry: DDA-registered tools, AgentPlugin-generated usecase tools (arrrrny/zuraffa#385), and remote MCP tools — single namespace, seeded by pi_agent's tool model (typed params, JSON-Schema validation at dispatch, sequential/parallel execution modes).

**Why this priority**: The registry is the seam between engine and plugin; every mission depends on it.

**Independent Test**: A mission calls one in-proc tool, one generated-usecase tool, and one remote-MCP tool in a single turn — dispatched correctly from one namespace.

**Acceptance Scenarios**:

1. **Given** tools registered from any source, **When** the loop emits a call, **Then** the registry resolves it regardless of origin.
2. **Given** arguments violating a tool's JSON Schema, **When** dispatched, **Then** a validation error returns as the tool result (mission continues).
3. **Given** a parallel-execution batch, **When** dispatched, **Then** tools run concurrently with results collected in call order.

### User Story 2 - Risk tiers first-class (Priority: P1)

As the policy shell, I read each tool's risk tier — `safe | confirm | admin` — from the tool itself (supersedes arrrrny/dart_agent_core#3): `confirm` defers to an approval callback before dispatch; `admin` requires an internal mission.

**Why this priority**: Gating is a hard safety requirement for on-device agents (injection-facing tool surface).

**Independent Test**: A `confirm` tool is not executed until the approval future resolves; timeout denies; `admin` tool denied on a user mission.

**Acceptance Scenarios**:

1. **Given** risk `confirm`, **When** dispatched, **Then** execution awaits the approval callback; denial or timeout yields a denied tool result.
2. **Given** risk `admin` on a non-internal mission, **When** dispatched, **Then** it is denied without invoking the implementation.

### User Story 3 - Native MCP client, three transports (Priority: P1)

As the engine, I act as MCP client over: **in-proc** (registry-direct, zero IPC — supersedes arrrrny/dart_agent_core#2), **SSE + Bearer** with reconnect and auth callback (supersedes #4), and **stdio** for dev tooling.

**Why this priority**: Cloud tools (raptorr) ride SSE; device tools ride in-proc; parity with zuraffa's own server (#384) gives full client/server symmetry.

**Independent Test**: Round-trip list + call against zuraffa's `McpSseServer` (arrrrny/zuraffa#384) with Bearer auth, plus an in-proc host, plus a stdio server.

**Acceptance Scenarios**:

1. **Given** an SSE connection that drops mid-mission, **When** connectivity returns, **Then** the client reconnects (backoff) and resumes tool listing/calls.
2. **Given** an expiring token, **When** the auth callback rotates it, **Then** calls continue without manager rebuild.
3. **Given** in-proc tools, **When** called in a tight loop, **Then** no serialization boundary exists (pass-by-reference with defensive arg copy).

### User Story 4 - Tool-result size discipline (Priority: P2)

As the engine, results beyond a size threshold are summarized with an `artifactRef`; large bodies never enter model context.

**Why this priority**: A 2 MB scrape must not poison the context window (architecture §4.3 discipline).

**Independent Test**: A tool returning 2 MB yields a structured summary + artifactRef in the model-facing result; the full body is retrievable by artifact id.

**Acceptance Scenarios**:

1. **Given** an oversized tool result, **When** returned to the loop, **Then** the model sees summary + artifactRef only.

### Edge Cases

- Namespace collision across sources (in-proc `webview.browse` vs remote `webview.browse`) → deterministic prefixing, warning event.
- MCP server returns malformed tool result → typed transport error surfaced as tool result.
- Approval callback never resolves → deny on timeout, mission continues.
- stdio server crash mid-call → process restart policy (bounded retries) then transport-level failure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: One tool registry MUST serve DDA, generated, and remote-MCP tools in a single namespace.
- **FR-002**: Tool dispatch MUST validate arguments against JSON Schema and support sequential/parallel modes.
- **FR-003**: `safe|confirm|admin` risk MUST be first-class tool metadata; dispatch MUST enforce approval/permission semantics.
- **FR-004**: The MCP client MUST implement in-proc, SSE+Bearer (reconnect, auth callback), and stdio transports.
- **FR-005**: Oversized results MUST be summarized + artifactRef'd before entering model context.

### Key Entities

- **AgentTool**: name, description, JSON Schema params, risk tier, execution mode, implementation binding.
- **McpTransport** (sealed): InProc, Sse(bearer/reconnect/auth), Stdio.
- **ToolResult**: content + structured payload + optional artifactRef.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In-proc + SSE/Bearer round-trips against zuraffa's own `McpSseServer` (arrrrny/zuraffa#384) — full symmetry (issue #4 AC).
- **SC-002**: Risk tiers flow through dispatch; `confirm` defers; `admin` gates (AC).
- **SC-003**: 2 MB tool result → artifactRef, never in context (AC).
- **SC-004**: Namespace collision safety across sources (AC).

## Assumptions

- zuraffa #384's SSE server is the acceptance counterpart (its landing is tracked there, not here).
- Artifact storage interface is minimal (sink + fetch by ref); concrete stores live in consuming packages.

## Dependencies

- Issue: arrrrny/zuraffa_agent#4 · Epic: #1 · After: spec 001 (loop consumes dispatch) · Pairs: arrrrny/zuraffa#385 (generated tools), #386 (kernel host) · Feeds: webview/scraper tool packages
