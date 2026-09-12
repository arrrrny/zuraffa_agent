**Template Version**: `zuraffa-1.0`

# Feature Specification: Runnable example — minimal agent in `example/`

**Branch**: `116-runnable-example` | **Date**: 2026-09-11

**Status**: Draft

**Input**: GitHub issue #111 — "Add runnable `example/` directory with a
minimal agent". Severity: high (area:packaging, area:documentation).

## Summary

The package ships no runnable example: a new consumer cannot see the
engine work without reading tests. This spec adds `example/` with a
minimal end-to-end agent — a scripted echo LLM client (no network, no
API key), the mission runner, and an event bus wired to console output —
runnable with `dart run example/minimal_agent.dart` and verified by a
test that executes the script as a subprocess.

**Out of scope**: tool-calling flows (covered by specs 003/048), MCP
examples, streaming output, and interactive REPLs.

## Files

- `example/minimal_agent.dart` — NEW: the runnable minimal agent.
- `example/README.md` — NEW: how to run it and what to expect.
- `test/example_minimal_agent_test.dart` — NEW: subprocess execution
  test (exit 0, expected transcript lines).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — A consumer runs the example and sees the engine work (Priority: P1)

A developer clones the repo, runs one command, and watches a mission
complete: mission start, turn output, completion, and the final result —
no API key, no network.

**Why this priority**: the example IS the deliverable.

**Independent Test**: execute the script as a subprocess; assert exit
code 0 and the presence of the lifecycle lines.

**Acceptance Scenarios**:

1. **Given** the repo checked out, **When** `dart run
   **Type**: acceptance
   example/minimal_agent.dart` executes, **Then** it exits 0 and prints
   a mission-start line, a completion line, and the final mission status
   `completed`.
2. **Given** the example source, **When** it is read, **Then** it
   **Type**: acceptance
   contains no API-key literals and no network endpoints (the scripted
   client never dials out).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The example MUST run a full mission through `MissionRunner`
  with a scripted in-process LLM client — no network and no API key
  required.
  traces: MinimalAgent.run
- **FR-002**: The example MUST print the mission lifecycle (start,
  completion, final status) to stdout so a human sees the engine work.
 
  traces: MinimalAgent.transcript
- **FR-003**: A test MUST execute the example as a subprocess and assert
  exit code 0 plus the lifecycle lines.
  traces: MinimalAgent.subprocess

### Non-Functional Requirements

- NFR-001: `example/` is outside `lib/` — console printing is allowed
  there and MUST NOT trip the purity gate.

## Layer Contracts

**Domain**:

- `MinimalAgent`: `run() -> Future<MissionResult>`, `transcript(events) -> List<String>`, `subprocess() -> ProcessResult`

### Key Entities

| Entity | Fields | Purpose |
|--------|--------|---------|
| `EchoLlmClient` | scripted completion | The no-network LLM stand-in |

### External Dependencies & Contracts

| Dependency | Kind | Contract | Priority |
|--------|--------|--------|--------|
| dart:io | SDK (test/example only) | `Process.run` for the subprocess check | P1 |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: US1 fixtures pass — subprocess exit 0 with lifecycle
  lines; no key literals in source (FR-001..FR-003).
- **SC-002**: `dart analyze` zero; full `dart test` green.
