**Template Version**: `zuraffa-1.0`

# Feature Specification: MCP resilience — per-server circuit breaker, call timeout, transient retry

**Branch**: `108-mcp-resilience` | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #120 — "MCP resilience: per-server circuit breaker +
call timeout + retry on transient errors". Severity: high. Depends on #107
(production transports — merged via #141).

## Summary

A misbehaving MCP server can stall a mission indefinitely (`callTool` has
no timeout), error forever without being short-circuited (no per-server
circuit breaker — the LLM fallback chain has one, MCP does not), and there
is no call-level retry for tools that are safe to repeat. This spec adds
three coordinated resilience behaviors to the MCP client stack:

1. **Call timeout** — every tool call is time-bounded (default 30s,
   configurable per call). A timed-out call surfaces as a typed call error
   (`timeout`) and is never retried automatically — the model decides what
   to do next.
2. **Per-server circuit breaker** — after N consecutive call failures
   (tool-level `McpCallError`s or transport drops), the client short-
   circuits: further calls fail fast with a `circuit-open` error until the
   cooldown elapses, then one probe decides recovery (closed on success,
   re-opened on failure).
3. **Transient retry for read-only tools** — opt-in per call: tools marked
   read-only may be retried on transient failures (transport errors,
   unavailability) up to a bounded attempt count with backoff. Never
   retried: application-level errors, timeouts, and non-read-only tools.

The `McpClient` contract documentation states all three behaviors.

**Out of scope**: half-open probe fan-out beyond one, breaker metrics
export, per-tool breakers (one per client/server), changes to the existing
transport-level reconnect policy (spec 082) — the breaker observes its
outcomes.

## Files

- `lib/src/mcp/mcp_call_guard.dart` — NEW: `McpCallGuard` (mutable holder
  over the immutable `CircuitBreaker`, injectable clock), plus
  `McpBreakerConfig`, `McpRetryConfig`, `McpCallOptions` value objects.
- `lib/src/mcp/mcp_client.dart` — EDIT: `callTool` gains the optional
  options parameter; the contract documentation states timeout, breaker,
  and retry behavior.
- `lib/src/mcp/mcp_tool_descriptor.dart` — EDIT: additive `readOnly` flag
  (default false).
- `lib/src/mcp/sse_mcp_client.dart`, `stdio_mcp_client.dart`,
  `in_proc_mcp_client.dart` — EDIT: accept optional `McpBreakerConfig` +
  `McpRetryConfig`; implement timeout; wire the guard.
- `test/mcp/mcp_call_guard_test.dart`,
  `test/mcp/mcp_120_resilience_test.dart` — NEW.
- `specs/108-mcp-resilience/` — this artifact set.

## User scenarios

### US1 — A hung server cannot stall the mission (P1)

As the engine, a tool call against a server that never answers returns a
typed timeout error within the configured bound; the mission keeps
running and the model can decide to try something else.

**Acceptance**: a call against a never-responding server returns the typed
timeout error after roughly the configured duration (not 30s when 50ms is
configured); without a timeout override the 30s default applies; a fast
server is unaffected.

**Acceptance Scenarios**:

1. **Given** a never-responding MCP server with a configured call timeout, **When** a call is made, **Then** the typed timeout error returns after roughly the configured duration (not 30s when 50ms is configured), the 30s default applies without an override, and a fast server is unaffected.
### US2 — A permanently failing server is short-circuited (P1)

As the engine, after repeated consecutive failures the client stops
hammering the server: further calls fail immediately with a typed
circuit-open error; after the cooldown one probe call decides recovery —
success closes the breaker, failure re-opens it.

**Acceptance**: with the failure threshold at N, the Nth consecutive
failure opens the breaker and call N+1 returns `circuit-open` without
touching the wire; after the cooldown the next call probes; a successful
probe closes the breaker (calls flow again) and a failing probe re-opens
it; a success in closed state resets the consecutive-failure count.

**Acceptance Scenarios**:

2. **Given** a failure threshold of N, **When** consecutive failures accumulate, **Then** the Nth failure opens the breaker, call N+1 returns `circuit-open` without touching the wire, after the cooldown the next call probes, a successful probe closes the breaker, a failing probe re-opens it, and a success in closed state resets the consecutive-failure count.
### US3 — Only safe tools are retried, only on transient trouble (P2)

As a tool author, marking a tool read-only opts it into bounded automatic
retry on transient failures; application errors, timeouts, and mutating
tools are never auto-retried.

**Acceptance**: a read-only tool whose first attempt fails transiently and
second succeeds is called exactly twice; a non-read-only tool in the same
situation is called exactly once; a timeout is never retried regardless of
the read-only mark.

**Acceptance Scenarios**:

3. **Given** a read-only tool whose first attempt fails transiently and second succeeds (and a non-read-only tool in the same situation), **When** each is called, **Then** the read-only tool is called exactly twice and the non-read-only tool exactly once, and a timeout is never retried regardless of the read-only mark.
## Edge cases

- A thrown transport exception during a guarded call counts as a breaker
  failure AND propagates (the reconnect policy from spec 082 still sees
  drops).
- An open breaker's fail-fast error must not itself feed the breaker.
- The default 30s timeout applies when no per-call override is given.
- `readOnly` defaults to false on every descriptor — existing descriptors
  are unaffected.

## Requirements

### Functional requirements

- **FR-001**: `callTool` accepts a per-call timeout; on expiry it
  returns the typed `timeout` call error; the default is 30 seconds.
  traces: McpCallGu.fr1
- **FR-002**: a timed-out call is never retried, whatever the
  read-only mark.
  traces: McpCallGu.fr2
- **FR-003**: with a breaker configured, N consecutive call failures
  (call errors or transport throws) open the breaker; subsequent calls
  fail fast typed without invoking the wire; after the cooldown a single
  probe decides recovery; a success in closed state resets the count.
  traces: McpCallGu.fr3
- **FR-004**: with a retry config supplied for a read-only call,
  transient failures are retried up to the configured attempt count with
  backoff; application errors and timeouts are not retried; non-read-only
  calls are never retried.
  traces: McpCallGu.fr4
- **FR-005**: the `McpClient` contract documentation states the timeout,
  breaker, and retry behaviors.
  traces: McpCallGu.fr5
- **FR-006**: `readOnly` is an additive, default-false descriptor flag.
  traces: McpCallGu.fr6

## Success criteria

- **SC-001** (US1 / FR-001–002): hung-wire test returns the timeout error
  within a bounded wait; never retried.
- **SC-002** (US2 / FR-003): threshold/cooldown/probe sequence proven
  through the client against a fake wire (no wire touch after open; probe
  recovery both ways); breaker count resets on success.
- **SC-003** (US3 / FR-004): retry counts prove read-only-only,
  transient-only, bounded-attempts behavior.
- **SC-004** (FR-005): the McpClient contract names timeout, breaker, retry.
- **SC-005**: `dart analyze` pristine; suite green; purity gate unchanged.

## Assumptions

- One breaker per client instance (== per server), not per tool.
- Timeout errors count toward the breaker (the issue counts "McpCallErrors
  or transport drops"; a timeout surfaces as an McpCallError) but are
  excluded from retry.
- Transient = transport-level failures (throws from the wire, codes
  `transport-error`/`unavailable`/`server-error`); application errors
  (the tool itself reporting failure) are final answers, not transient.

## Dependencies

- Builds on: master (post-#143) — the real transports (spec 105),
  reconnect policy (spec 082), the immutable `CircuitBreaker` (spec 035).
- Related but out of scope: half-open probe concurrency, metrics export,
  per-tool breakers, spec 082 reconnect-policy changes.

## Layer Contracts

**Domain**:

- `McpCallGu`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`

