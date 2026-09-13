**Template Version**: `zuraffa-1.0`

# Feature Specification: Structured logging — `package:logging` with named subsystem loggers

**Branch**: `112-structured-logging` | **Date**: 2026-09-11

**Status**: Draft

**Input**: GitHub issue #119 — "Adopt structured logging framework
(`package:logging`) with named loggers per subsystem". Severity: high
(area:observability). Enables OpenTelemetry (issue #133), metrics, and
EngineEventBus diagnostics (issue #134).

## Summary

The engine has no structured logging: no `package:logging` dependency, no
named loggers, no level policy, no routing — the only sink-shaped code in
`lib/` is a doc-comment example. A production agent engine is opaque
without it. This spec adopts `package:logging` behind a tiny facade
(`AgentLog`) that pins the logger hierarchy (`zuraffa.agent.<subsystem>`
for `llm`, `mcp`, `engine`, `eval`, `session`, `eventBus`), the level
policy (FINE transport bytes, INFO lifecycle, WARNING retry/breaker,
SEVERE terminal failure), and a consumer-injected sink (`install`) —
`lib/` keeps its `print`-free, dart:io-free discipline. First adoption
sites: the LLM retry/backoff path (WARNING on each scheduled retry) and
the mission lifecycle (INFO on mission start/complete). ARCHITECTURE.md
documents the hierarchy and the recommended consumer sink configuration.

**Out of scope**: wiring `EngineEventBus` subscriber errors to the logger
(spec 113, issue #134), OpenTelemetry export (issue #133), log-file
rotation or buffering, replacing the `zuraffa` dep's `Loggable`/`FailureHandler`
mixins, and any log emission on hot per-token paths (thinking deltas stay
event-bus-only).

## Files

- `lib/src/logging/agent_log.dart` — NEW: the `AgentLog` facade — named
  subsystem loggers, level policy helpers, `install({level, onRecord})`.
- `lib/src/logging/memory_log_sink.dart` — NEW: pure-Dart record collector
  for tests and consumers (no dart:io).
- `lib/src/llm/retry.dart` — MODIFIED: log a WARNING record on each
  scheduled retry (attempt, delay, error) via the `llm` logger.
- `lib/src/engine/mission_runner.dart` — MODIFIED: INFO records on mission
  start/complete via the `engine` logger (values only; no payload dumps).
- `pubspec.yaml` — MODIFIED: add `logging` dependency.
- `ARCHITECTURE.md` — MODIFIED: logger hierarchy + recommended sink config.
- `test/logging/agent_log_test.dart` — NEW: facade, hierarchy, level
  policy, install/no-install, adoption-site fixtures.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — A consumer installs a sink and receives structured records (Priority: P1)

A host application installs a sink (memory sink in tests, stderr/telemetry
in production) and receives every engine record with its subsystem logger
name and level, without the engine printing anything on its own.

**Why this priority**: without delivery, logging is theater; every later
story consumes installed records.

**Independent Test**: install a memory sink, emit through two different
subsystem loggers, assert both records arrive with the expected names and
levels.

**Acceptance Scenarios**:

1. **Given** `ZuraffaLogging.install(level: Level.INFO, onRecord: sink.add)`
   **Type**: acceptance
   with a memory sink, **When** the `llm` subsystem logger emits an INFO
   record and the `engine` subsystem logger emits a WARNING record, **Then**
   both records arrive at the sink carrying logger names `zuraffa.agent.llm`
   and `zuraffa.agent.engine` and their respective levels.
2. **Given** no `install` call has been made, **When** subsystem code emits
   **Type**: acceptance
   records at any level, **Then** nothing is printed, nothing throws, and
   emission costs no more than an isLoggable check.
3. **Given** `install` at `Level.WARNING`, **When** FINE and INFO records
   **Type**: acceptance
   are emitted, **Then** they are filtered out by the hierarchy and only
   WARNING-or-above records arrive at the sink.

### User Story 2 — The level policy is pinned by the facade (Priority: P1)

An engineer emitting a record picks the level from a documented,
test-enforced policy: FINE = transport bytes, INFO = turn/mission
lifecycle, WARNING = retry/breaker-open, SEVERE = terminal failure.

**Why this priority**: consistent levels are what make logs structured
rather than strings.

**Independent Test**: assert the facade's level constants against the
policy table and exercise each level through one adoption site.

**Acceptance Scenarios**:

4. **Given** the `AgentLog` level policy constants, **When** they are read,
   **Type**: acceptance
   **Then** transport is FINE, lifecycle is INFO, resilience (retry,
   breaker-open) is WARNING, and terminal failure is SEVERE.
5. **Given** an LLM client whose transport fails once and succeeds on
   **Type**: acceptance
   retry (scripted seam), **When** the retry is scheduled, **Then** a
   WARNING record is emitted on the `llm` logger carrying the attempt
   number, the backoff delay, and the error.
6. **Given** a mission run driven through `MissionRunner` with a scripted
   **Type**: acceptance
   client, **When** the mission starts and completes, **Then** an INFO
   record is emitted on the `engine` logger at start and at completion
   (mission id + outcome only, never full payloads).

### User Story 3 — The hierarchy and sink guidance are documented (Priority: P2)

A consumer reading ARCHITECTURE.md can name every subsystem logger and
configure a recommended sink (levels per logger, record formatting) in
under a minute.

**Why this priority**: adoption by hosts depends on discoverable
documentation, not source diving.

**Independent Test**: read ARCHITECTURE.md and assert it names all six
subsystem loggers, the level policy, and a sink configuration recipe.

**Acceptance Scenarios**:

7. **Given** ARCHITECTURE.md on master, **When** it is inspected, **Then**
   **Type**: acceptance
   it documents the `zuraffa.agent.` logger hierarchy (all six subsystem
   names), the level policy table, and a recommended consumer sink
   configuration (install + formatting).
8. **Given** the `lib/` tree, **When** it is searched for `print(`,
   **Type**: acceptance
   `stdout`, and `stderr`, **Then** there are zero matches (the engine
   never writes to a console on its own; delivery is always
   consumer-injected).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `AgentLog` MUST expose the named subsystem loggers `llm`,
  `mcp`, `engine`, `eval`, `session`, and `eventBus`, each backed by a
  `package:logging` `Logger` named `zuraffa.agent.<subsystem>` under the
  shared `zuraffa.agent` parent; the names are a pinned public contract.
  traces: AgentLog.logger
- **FR-002**: The level policy MUST be pinned as facade constants —
  transport FINE, lifecycle INFO, resilience WARNING, terminal SEVERE —
  and every adoption site MUST use the policy level for its class of
  event.
  traces: AgentLog.levelPolicy
- **FR-003**: `ZuraffaLogging.install({level, onRecord})` MUST be the only
  delivery wiring point: it sets the hierarchy level and attaches the
  consumer-injected record handler; without it the engine MUST NOT print,
  write, or otherwise emit anywhere (zero `print`/`stdout`/`stderr` in
  `lib/`).
  traces: AgentLog.install
- **FR-004**: Emission MUST be safe and cheap before install: no listener
  means no output, emission never throws, and skipped records cost an
  `isLoggable` check.
  traces: AgentLog.logger
- **FR-005**: The first adoption sites MUST ship with this spec: the LLM
  retry path logs a WARNING per scheduled retry (attempt, delay, error)
  on `zuraffa.agent.llm`, and `MissionRunner` logs INFO on mission
  start/complete (id + outcome) on `zuraffa.agent.engine`.
  traces: AgentLog.retryWarning
- **FR-006**: ARCHITECTURE.md MUST document the logger hierarchy, the
  level policy table, and a recommended consumer sink configuration.
  traces: AgentLog.document

### Non-Functional Requirements

- NFR-001: `package:logging` is pure Dart — the spec 064 dart:io purity
  gate MUST stay green with no new allowlist entries.

## Layer Contracts

**Domain**:

- `AgentLog`: `logger(subsystem) -> Logger`, `install(level, onRecord) -> void`, `levelPolicy() -> LevelTable`, `retryWarning(attempt, delay, error) -> void`, `missionInfo(missionId, outcome) -> void`, `document(hierarchy, policy, sinkRecipe) -> void`

### Key Entities

| Entity | Fields | Purpose |
|--------|--------|---------|
| `AgentLog` | static subsystem loggers | The named-logger facade over `package:logging` |
| `MemoryLogSink` | `records: List<LogRecord>`, `add(LogRecord)` | Consumer/test sink collecting records in memory |

### External Dependencies & Contracts

| Dependency | Kind | Contract | Priority |
|--------|--------|--------|--------|
| package:logging | pub dependency | `Logger`, `Level`, `LogRecord`, `Logger.root.onRecord` | P1 |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: US1 fixtures pass — installed sink receives records with
  pinned names/levels; pre-install emission is silent and safe (FR-001,
  FR-003, FR-004).
- **SC-002**: US2 fixtures pass — level constants match the policy;
  retry WARNING and mission INFO records carry the contract fields
  (FR-002, FR-005).
- **SC-003**: US3 passes — ARCHITECTURE.md names all six loggers + policy
  + sink recipe; `lib/` grep for `print(`/`stdout`/`stderr` is zero
  (FR-006, FR-003).
- **SC-004**: `dart analyze` zero issues; full `dart test` suite green;
  purity gate unchanged.
