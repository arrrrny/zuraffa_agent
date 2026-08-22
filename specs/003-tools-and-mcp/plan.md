# Implementation Plan: Tools & MCP Client

**Branch**: `003-tools-and-mcp` | **Date**: 2026-08-19 | **Spec**: /specs/003-tools-and-mcp/spec.md

**Input**: Feature specification from `/specs/003-tools-and-mcp/spec.md`

**Note**: This template is filled in by the `/skill:speckit-plan` command; its definition describes the execution workflow.

## Summary

Implements a unified tool registry and MCP client for zuraffa_agent. The feature provides:

1. **Unified Tool Registry** (`AgentToolRegistry`): Single namespace serving DDA-registered tools, AgentPlugin-generated usecase tools, and remote MCP tools with JSON-Schema validation and sequential/parallel execution modes.

2. **Risk Tier System**: First-class `safe | confirm | admin` risk metadata on tools; dispatch enforces approval callbacks for `confirm` and gates `admin` tools to internal missions only.

3. **MCP Client with Three Transports**: In-proc (registry-direct, zero IPC), SSE + Bearer with reconnect and auth callback, and stdio for dev tooling — achieving full client/server symmetry with zuraffa's McpSseServer.

4. **Tool Result Size Discipline**: Oversized results (> threshold) summarized with `artifactRef`; full body retrievable by artifact ID, never enters model context.

Technical approach: Extend existing `tools.dart` with registry, risk tiers, and artifact handling; add new `mcp_client.dart` with transport abstraction; all entities via Zorphy; tests against zuraffa's McpSseServer.

## Technical Context

**Language/Version**: Dart SDK ^3.8.0 (pure Dart package, no Flutter)

**Primary Dependencies**: 
- `zorphy` ^2.0.0 (model layer, code generation via build_runner)
- `zorphy_annotation` ^2.0.0 (annotations)
- `json_annotation` ^4.12.0 (JSON serialization)
- `zuraffa` (from git: https://github.com/arrrrny/zuraffa, ref: development) — for McpSseServer interop types
- `hive_ce` ^2.19.0 (local storage for artifacts if needed)
- `test` ^1.25.0, `mocktail` ^1.0.5 (testing)
- `build_runner` ^2.16.0 (code generation)

**Storage**: Artifact storage via minimal interface (sink + fetch by ref); concrete implementation delegated to consuming packages. In-memory map for dev/test; Hive CE for persistence if needed.

**Testing**: Dart `test` package with `mocktail` for mocking; contract tests for MCP transport compliance; integration tests against zuraffa's McpSseServer (arrrrny/zuraffa#384).

**Target Platform**: Cross-platform Dart (VM, AOT, JS/WASM via dart2js/dart2wasm); no platform-specific code; `dart:io`-free runtime paths per Constitution Article VII.

**Project Type**: Pure Dart library package (engine core).

**Performance Goals**: 
- In-proc tool dispatch: < 1ms overhead (pass-by-reference with defensive copy)
- SSE reconnect: < 500ms backoff recovery
- 2 MB result summarization: < 10ms
- Parallel batch dispatch: scales with isolate/workers (future)

**Constraints**: 
- No Flutter dependencies (Constitution Article VII)
- All entities/enums via Zorphy (Constitution Article IX)
- Ported code carries attribution headers (Constitution Article VIII)
- Zero analyzer warnings after build (Constitution Article X)

**Scale/Scope**: 
- ~10-15 Zorphy entities
- 3 transport implementations
- Registry + dispatcher + artifact service
- ~20 unit + contract tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| I | CLI-Built Only | ✅ Pass | Plan generated via speckit-plan skill |
| II | Stop on First Misfire | ✅ Pass | Gates will enforce |
| III | Escalate Upstream and Wait | ✅ Pass | MCP types from zuraffa#384; will wait if needed |
| IV | Postmortem Every Misfire | ✅ Pass | Process documented |
| V | Gates Are Non-Negotiable | ✅ Pass | CI + human review |
| VI | Probes Must Retain Evidence | ✅ Pass | Test outputs persisted |
| VII | Engine Purity | ✅ Pass | No Flutter deps; `dart:io`-free runtime |
| VIII | Attributed Ports | ✅ Pass | pi_agent/dart_agent_core ports attributed in tools.dart |
| IX | Zorphy Is the Model Layer | ✅ Pass | All new entities via @Zorphy annotations |
| X | Post-Build Analysis Pristine | ✅ Pass | `dart analyze` zero errors/warnings gate |

**No violations — all gates pass.**

## Project Structure

### Documentation (this feature)

```text
specs/003-tools-and-mcp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── tool_registry.json
│   ├── mcp_transport.json
│   └── artifact_service.json
└── tasks.md             # Phase 2 output (speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── src/
│   ├── tools.dart                    # Existing — extended with registry, risk tiers, artifacts
│   ├── mcp_client.dart               # NEW — MCP client with transport abstraction
│   ├── mcp/
│   │   ├── transport.dart            # NEW — McpTransport sealed class + InProc/Sse/Stdio
│   │   ├── sse_transport.dart        # NEW — SSE + Bearer with reconnect/auth
│   │   ├── stdio_transport.dart      # NEW — stdio transport with restart policy
│   │   └── inproc_transport.dart     # NEW — in-proc transport (zero IPC)
│   ├── artifact/
│   │   ├── artifact_ref.zorphy.dart  # NEW — Zorphy entity for artifact reference
│   │   ├── artifact_ref.dart
│   │   ├── artifact_ref.g.dart
│   │   ├── artifact_service.dart     # NEW — sink/fetch interface
│   │   └── in_memory_artifact_store.dart  # NEW — dev/test impl
│   └── engine/
│       └── tool_dispatcher.dart      # NEW — registry-backed dispatcher with risk/parallel
└── zuraffa_agent.dart                # Exports
```

**Structure Decision**: Single-project library structure (Option 1). All new code under `lib/src/` following existing patterns: domain entities in `lib/src/domain/entities/`, usecases in `lib/src/domain/usecases/`, repositories in `lib/src/domain/repositories/`, DI in `lib/src/di/`. New `mcp/` and `artifact/` subdirectories for feature-scoped modules.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | — | — |

---

## Phase 0: Research

### Unknowns to Resolve

1. **MCP Protocol Version**: Which MCP spec version does zuraffa's McpSseServer (#384) implement? Need exact JSON-RPC method names for `tools/list`, `tools/call`, `initialize`.

2. **SSE Reconnect/Backoff Strategy**: What backoff algorithm (exponential, linear, jitter)? Max retries? Connection state machine?

3. **Auth Callback Contract**: Exact signature for Bearer token rotation callback — async function returning `Future<String>`? Error handling?

4. **Stdio Process Management**: Process restart policy — bounded retries? Exponential backoff? Health check mechanism?

5. **Artifact Size Threshold**: What byte threshold triggers artifactRef? (Spec says "beyond a size threshold" — need concrete number, e.g., 64 KB, 256 KB, 1 MB?)

6. **Parallel Execution Model**: Use Dart isolates? `Compute`? Simple `Future.wait`? How to handle shared state safely?

7. **Namespace Collision Prefixing**: Deterministic prefix scheme — source-based (e.g., `dda:`, `generated:`, `mcp:<server_id>:`)? Warning event format?

8. **Approval Callback Timeout**: Default timeout for `confirm` risk tier? Configurable?

### Research Tasks

- [ ] Research MCP protocol version and method names used by zuraffa McpSseServer
- [ ] Research SSE reconnect best practices (exponential backoff with jitter)
- [ ] Define auth callback signature and token rotation flow
- [ ] Design stdio process manager with bounded retries
- [ ] Determine artifact size threshold (balance context safety vs. overhead)
- [ ] Choose parallel execution model (isolates vs. Future.wait)
- [ ] Define namespace collision prefix scheme and warning events
- [ ] Define approval callback timeout and configuration

---

## Phase 1: Design & Contracts

### Data Model (→ `data-model.md`)

Entities to define via Zorphy:

1. **AgentTool** — name, description, inputSchema (JSON), riskTier (enum: safe/confirm/admin), executionMode (enum: sequential/parallel), source (enum: dda/generated/mcp), transportBinding (for MCP tools)

2. **McpTransport** (sealed) — InProc, Sse(config), Stdio(config)

3. **SseTransportConfig** — endpoint, bearerToken, authCallback (function ref), reconnectPolicy

4. **StdioTransportConfig** — command, args, env, restartPolicy

5. **InProcTransportConfig** — toolRegistry reference

6. **ToolResult** — content (String), structuredPayload (Map?), artifactRef (ArtifactRef?)

7. **ArtifactRef** — id (ULID), mimeType, sizeBytes, createdAt

8. **Artifact** — ref (ArtifactRef), data (Uint8List or Stream<List<int>>)

9. **ApprovalRequest** — toolName, arguments, requestedAt, timeoutMs

9. **ToolDispatchResult** — success/result or error, artifactRefs

### Interface Contracts (→ `contracts/`)

1. **tool_registry.json** — Register, unregister, resolve, list tools; namespace collision handling

2. **mcp_transport.json** — Connect, disconnect, listTools, callTool, onToolsChanged stream

3. **artifact_service.json** — Store (sink), fetch, delete, list; size threshold config

### Quickstart (→ `quickstart.md`)

Runnable validation scenarios:

1. **In-proc registry**: Register 3 tools (DDA, generated, MCP), dispatch all in one turn
2. **Risk tiers**: `confirm` tool awaits approval; `admin` denied on user mission
3. **MCP SSE round-trip**: Connect to zuraffa McpSseServer, list tools, call tool, reconnect on drop
4. **MCP stdio**: Spawn stdio server, call tool, crash/restart handling
5. **ArtifactRef**: Tool returns 2 MB → summary + artifactRef in result; fetch full body by ref
6. **Parallel dispatch**: Batch of 5 tools runs concurrently, results in call order
7. **Namespace collision**: Two sources register `webview.browse` → deterministic prefix + warning

---

## Next Steps

1. **Execute Phase 0**: Dispatch research agents for each unknown; consolidate into `research.md`
2. **Execute Phase 1**: Generate `data-model.md`, `contracts/*.json`, `quickstart.md`
3. **Re-evaluate Constitution Check** post-design
4. **Generate `tasks.md`** via `/skill:speckit-tasks` for implementation phase