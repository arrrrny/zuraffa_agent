# Research: Tools & MCP Client

**Feature**: 003-tools-and-mcp
**Date**: 2026-08-19

## Resolved Unknowns

### 1. MCP Protocol Version & Method Names
**Decision**: MCP protocol version `2024-11-05` (per zuraffa's `McpSseServer` in `zuraffa_mcp_server.dart:231`)

**Method names** (from zuraffa's server implementation):
- `initialize` — protocol handshake, returns capabilities
- `tools/list` — returns array of tool definitions with `name`, `description`, `inputSchema`
- `tools/call` — params: `{name: string, arguments?: object}`, returns `{content: [{type: 'text', text: string}], isError?: boolean}`
- `resources/list` — resource listing
- `resources/read` — resource reading
- `shutdown` — graceful shutdown
- `ping` — health check

**Rationale**: Direct inspection of zuraffa's `McpSseServer` (arrrrny/zuraffa#384) shows this exact protocol. The server is the acceptance counterpart per spec assumptions.

**Alternatives considered**: None — this is the mandated compatibility target.

---

### 2. SSE Reconnect/Backoff Strategy
**Decision**: Exponential backoff with jitter:
- Base delay: 500ms
- Max delay: 30s
- Multiplier: 2x per attempt
- Jitter: ±25% (random)
- Max retries: 10 (then permanent failure)
- Reset on successful connection

**Connection State Machine**:
```
DISCONNECTED → CONNECTING → CONNECTED
                    ↓
              RECONNECTING (on drop)
                    ↓
              CONNECTED / DISCONNECTED (max retries)
```

**Rationale**: Standard practice for SSE clients; matches spec requirement "backoff" and "resumes tool listing/calls". Jitter prevents thundering herd.

**Alternatives considered**: Linear backoff (too slow recovery), fixed interval (herd risk), infinite retries (resource leak).

---

### 3. Auth Callback Contract
**Decision**: 
```dart
typedef AuthCallback = Future<String> Function();
```

- Called when: 401 response, or proactively before token expiry (if server provides `expires_in`)
- Returns: New Bearer token string
- Throws: Any exception → treated as auth failure, transport enters error state
- Timeout: 10s default (configurable)

**Token Rotation Flow**:
1. SSE transport detects 401 on request
2. Calls `authCallback()` to get fresh token
3. Retries request with new token (once)
4. If retry fails → transport error

**Rationale**: Spec requires "auth callback rotates it, calls continue without manager rebuild". Simple async function matches Dart patterns.

**Alternatives considered**: Stream-based token updates (overkill), sync callback (blocks), pre-emptive refresh (needs server cooperation).

---

### 4. Stdio Process Management
**Decision**: 
- **Restart Policy**: Bounded retries (max 3) with exponential backoff (1s, 2s, 4s)
- **Health Check**: Periodic `ping` request every 30s; failure triggers restart
- **Process Isolation**: Each stdio server runs in separate `Process`; stdout/stderr piped
- **Crash Detection**: Non-zero exit code or stdout/stderr closure
- **Request Queue**: Pending requests held during restart; replayed on reconnect (idempotent calls only)

**Rationale**: Spec requires "process restart policy (bounded retries) then transport-level failure". Matches zuraffa's stdio server pattern.

**Alternatives considered**: Unlimited retries (hangs), no restart (fragile), isolate-based (not process-isolated).

---

### 5. Artifact Size Threshold
**Decision**: **256 KB** (262,144 bytes)

**Rationale**: 
- Spec mentions "2 MB scrape must not poison context" as example
- 256 KB is small enough to protect context windows (typical 8K-128K token limits ≈ 32K-512K chars)
- Large enough to avoid fragmentation for normal tool results
- Configurable via `ArtifactServiceConfig.thresholdBytes`

**Alternatives considered**: 64 KB (too aggressive), 1 MB (risks context), 2 MB (spec example but too large for safety).

---

### 6. Parallel Execution Model
**Decision**: **`Future.wait` with concurrency limit** (default: 10 concurrent)

- Tools marked `executionMode: parallel` dispatched via `Future.wait` with semaphore
- Sequential tools: await each in order
- Mixed batch: sequential group → parallel group → sequential group (preserves call order in results)
- No isolates (avoids serialization overhead for in-proc; isolates for CPU-bound work is future)

**Rationale**: Spec says "tools run concurrently with results collected in call order". `Future.wait` preserves order; semaphore prevents resource exhaustion. Isolates add serialization cost that defeats "pass-by-reference with defensive copy" for in-proc.

**Alternatives considered**: Dart isolates (heavy for in-proc), `Compute` (Flutter-only), unbounded parallelism (OOM risk).

---

### 7. Namespace Collision Prefixing
**Decision**: Source-based deterministic prefixes:
- DDA tools: `dda:` (no prefix — native namespace)
- Generated tools: `gen:` 
- MCP tools: `mcp:<server_id>:`
- Server ID: First 8 chars of server URL hash (SSE) or command hash (stdio)

**Warning Event**:
```dart
class NamespaceCollisionEvent {
  final String toolName;
  final List<String> sources; // ['dda', 'mcp:abc12345']
  final String resolution; // 'prefix applied to non-native'
}
```

Emitted via `ToolRegistry.onCollision` stream.

**Rationale**: Spec requires "deterministic prefixing, warning event". DDA gets native namespace as primary; others prefixed. Short server ID keeps names readable.

**Alternatives considered**: Suffix-based (harder to read), random UUIDs (non-deterministic), reject duplicates (breaks multi-source).

---

### 8. Approval Callback Timeout
**Decision**: **30 seconds default**, configurable per-tool via `AgentTool.confirmTimeoutMs`

**Callback Signature**:
```dart
typedef ApprovalCallback = Future<bool> Function(ApprovalRequest request);
```

**ApprovalRequest**:
```dart
class ApprovalRequest {
  final String toolName;
  final Map<String, dynamic> arguments;
  final DateTime requestedAt;
  final int timeoutMs;
}
```

**Behavior**:
- `confirm` tool → dispatch pauses, calls `approvalCallback(request)`
- Returns `true` → proceed with execution
- Returns `false` or timeout → tool result = denied error, mission continues
- `admin` tool on non-internal mission → immediate deny (no callback)

**Rationale**: Spec requires "timeout denies; mission continues". 30s balances user response time vs. mission stall.

**Alternatives considered**: 60s (too long), 10s (too short for human), no timeout (hang risk).

---

## Dependency Best Practices

### Zorphy Entity Patterns
- All entities in `lib/src/domain/entities/<name>/<name>.dart` with `@Zorphy()` annotation
- Part files: `.zorphy.dart`, `.g.dart` (generated)
- Use `ZorphyId` for ULID primary keys
- Enums for closed sets (risk tier, execution mode, transport type)

### MCP Transport Abstraction
- Sealed class `McpTransport` with `InProc`, `Sse`, `Stdio` subclasses
- Common interface: `connect()`, `disconnect()`, `listTools()`, `callTool()`, `onToolsChanged` stream
- Transport-specific config via sealed config classes

### Artifact Service
- Interface: `ArtifactService` with `store(bytes, mimeType)`, `fetch(ref)`, `delete(ref)`, `list()`
- In-memory impl for tests; Hive CE for persistence
- `ArtifactRef` is Zorphy entity with `id`, `mimeType`, `sizeBytes`, `createdAt`

---

## Integration Patterns

### With zuraffa McpSseServer
- Client connects to SSE endpoint
- Sends `initialize` → gets `protocolVersion: 2024-11-05`
- `tools/list` returns zfa tools (prefixed `zuraffa_*`)
- `tools/call` executes zfa CLI commands
- Reconnect on drop with backoff

### With Engine Loop (spec 002)
- `ToolDispatcher` implementation uses `AgentToolRegistry`
- Registry resolves tool → validates schema → checks risk tier → executes
- Results wrapped in `ToolResult` with optional `ArtifactRef`
- Loop continues on tool errors (validation, denied, transport)

### With AgentPlugin (zuraffa#385)
- Generated usecase tools registered via registry API
- Source = `generated`, prefixed `gen:`
- Risk tier from plugin metadata (default `safe`)