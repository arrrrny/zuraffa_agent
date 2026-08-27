# Feature Specification: MCP Client

**Feature Branch**: `015-mcp-client`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has MCP client entities but no runtime; dart_agent_core uses direct tool injection (no MCP). This spec fills the MCP gap defined in Spec 003.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - In-proc transport (Priority: P1)

As the engine, I call MCP tools directly via in-process transport (zero IPC) for tools registered in the local tool registry.

**Why this priority**: In-proc is the fastest transport for local tools.

**Independent Test**: A tool registered in-proc is called via MCP protocol with identical results to direct dispatch.

**Acceptance Scenarios**:

1. **Given** an in-proc MCP server, **When** a tool is called, **Then** it executes without serialization overhead.

### User Story 2 - SSE + Bearer transport (Priority: P1)

As the engine, I connect to remote MCP servers via SSE with Bearer auth, automatic reconnect, and token rotation.

**Why this priority**: Cloud tools (raptorr) ride SSE; this is the primary remote transport.

**Independent Test**: A connection drop triggers automatic reconnect with exponential backoff.

**Acceptance Scenarios**:

1. **Given** an SSE connection that drops mid-mission, **When** connectivity returns, **Then** the client reconnects and resumes.
2. **Given** an expiring token, **When** the auth callback rotates it, **Then** calls continue without rebuild.

### User Story 3 - stdio transport (Priority: P2)

As the engine, I connect to local MCP servers via stdio for dev tooling.

**Why this priority**: stdio is the standard for local MCP servers.

**Independent Test**: A stdio server crash triggers process restart with bounded retries.

**Acceptance Scenarios**:

1. **Given** a stdio server that crashes, **When** it restarts, **Then** the client reconnects automatically.

### User Story 4 - Tool listing and caching (Priority: P1)

As the engine, I list tools from MCP servers and cache the results, with invalidation on server-reported changes.

**Why this priority**: Tool listing must be efficient and up-to-date.

**Independent Test**: After listing, tools are available in the registry; on change notification, the cache is invalidated.

**Acceptance Scenarios**:

1. **Given** an MCP server, **When** tools are listed, **Then** they are registered in the tool registry.
2. **Given** a tools-changed notification, **When** received, **Then** the cache is invalidated and tools are re-listed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The MCP client MUST implement in-proc, SSE+Bearer, and stdio transports.
- **FR-002**: SSE transport MUST support automatic reconnect with exponential backoff.
- **FR-003**: SSE transport MUST support auth callback for token rotation.
- **FR-004**: stdio transport MUST handle process crashes with bounded retries.
- **FR-005**: Tool listing MUST be cached and invalidated on change notifications.

### Key Entities

- **McpClient**: facade with transport abstraction
- **McpTransport** (interface): connect, disconnect, listTools, callTool, onToolsChanged
- **InProcTransport**: zero-IPC registry calls
- **SseTransport**: SSE + Bearer with reconnect
- **StdioTransport**: process management with restart

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In-proc round-trip works with zero serialization.
- **SC-002**: SSE reconnects after connection drop within 5s.
- **SC-003**: stdio restarts after crash within 10s.

## Dependencies

- After: spec 003 (tool registry), spec 007 (LLM clients for auth)
- Feeds: remote tool access for the engine
