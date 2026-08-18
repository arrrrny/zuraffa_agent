# Feature Specification: Eval Harness — Golden Missions, Record/Replay, pass@k

**Feature Branch**: `006-eval-harness-golden`

**Created**: 2026-08-18

**Status**: Draft

**Input**: Epic arrrrny/zuraffa_agent#1 §R6 — converted from issue #7. Concepts ported from dart_agent_core's eval subsystem (its genuinely great part); runtime path must be dart:io-free for CI everywhere.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record and replay golden missions (Priority: P1)

As an engine developer, I record a mission once — LLM responses + tool traffic (webview side via the VCR cassettes of arrrrny/zikzak_inappwebview#238) — and replay it deterministically in CI forever.

**Why this priority**: Deterministic replay is the only way agent behavior is regression-testable; it gates every cohort rollout.

**Independent Test**: Record a 3-tool mission; replay 10×; outcomes and event streams identical.

**Acceptance Scenarios**:

1. **Given** a recorded cassette (LLM responses keyed by request, tool results), **When** replayed, **Then** the engine consumes recordings instead of live calls with identical event order.
2. **Given** a replay whose inputs drift from the recording (prompt change), **Then** the harness reports a mismatch loudly — never silently passes.

### User Story 2 - pass@k / pass^k metrics (Priority: P1)

As a release engineer, I compute pass@k (unbiased estimator) and pass^k (empirical) over a suite, and the CI gate enforces a threshold before rollout.

**Why this priority**: Cohort rollouts (raptorr registry, arrrrny/raptorr#127) require a quantitative gate.

**Independent Test**: A seeded suite with known outcomes produces the mathematically correct pass@k.

**Acceptance Scenarios**:

1. **Given** a suite with k samples per task and known pass counts, **When** scored, **Then** pass@k matches the analytic value.
2. **Given** a release gate of pass@k ≥ threshold, **When** a suite scores below, **Then** CI fails with per-task breakdown.

### User Story 3 - Grader matrix (Priority: P1)

As a suite author, I grade missions with exact matchers, schema validators, or model-as-judge graders — selected per task.

**Why this priority**: Missions have heterogeneous outputs; one grader type never fits.

**Independent Test**: One suite exercises all three grader types with correct verdicts on crafted fixtures (including a judge fixture with a recorded judge response).

**Acceptance Scenarios**:

1. **Given** a task with an exact grader, **Then** byte-equality decides.
2. **Given** a schema grader, **Then** JSON-Schema validity decides.
3. **Given** a model-judge grader (recorded judge), **Then** the parsed verdict decides, and the judge call is replayed deterministically.

### User Story 4 - Integration surfaces (Priority: P2)

As the ecosystem, the harness feeds `zfa agent replay` (CLI lives in the plugin, arrrrny/zuraffa#385) and the dws_playground scenario pack (arrrrny/dws_playground#7 GM-1..GM-5).

**Why this priority**: The harness must be consumable where missions actually live.

**Independent Test**: dws_playground golden missions run through this harness in CI green.

**Acceptance Scenarios**:

1. **Given** GM-1..GM-5 defined as harness suites, **When** CI runs, **Then** all report and gate correctly.

### User Story 5 - Portable runtime (Priority: P2)

As CI, the eval runtime executes everywhere — no dart:io imports on the runtime path.

**Why this priority**: dart_agent_core's eval leaked dart:io; ours must run on any CI runner including web-adjacent contexts.

**Independent Test**: Static analysis gate asserting zero dart:io imports in the eval runtime module.

**Acceptance Scenarios**:

1. **Given** the eval runtime package, **When** scanned, **Then** no dart:io imports exist (CLI/loader layers exempt).

### Edge Cases

- Cassette missing a required response → hard failure with the unmatched request printed.
- Flaky tool timing under replay → replay is time-independent by construction (no wall-clock in assertions).
- Model-judge unavailable offline → judge responses must be recorded; unrecorded judge = configuration error.
- Suite with zero tasks → validation error, not silent success.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The harness MUST record LLM + tool traffic and replay deterministically, detecting input drift.
- **FR-002**: Scoring MUST implement pass@k (unbiased estimator) and pass^k (empirical) with per-task breakdowns.
- **FR-003**: Graders MUST include exact, schema, and model-judge (recorded) types.
- **FR-004**: The harness MUST be consumable by `zfa agent replay` (plugin CLI) and dws_playground suites.
- **FR-005**: The eval runtime MUST be dart:io-free (enforced by static gate).

### Key Entities

- **GoldenMission**: recorded cassette + task definition + grader bindings.
- **Suite**: task set + k + gate threshold.
- **Recorder/Replayer**: pluggable at LlmClient and tool-registry boundaries (no engine internals touched).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Record → replay determinism: 10× identical run, identical outcome (issue #7 AC).
- **SC-002**: pass@k computed correctly on a seeded suite; grader matrix tested (AC).
- **SC-003**: dws_playground GM-1..GM-5 run through this harness in CI (AC).
- **SC-004**: Eval runtime has no dart:io imports (AC).

## Assumptions

- Webview-side cassettes come from arrrrny/zikzak_inappwebview#238; this harness consumes the format, not the recorder.
- Dart_agent_core eval concepts are ported with attribution where code is structurally reused.

## Dependencies

- Issue: arrrrny/zuraffa_agent#7 · Epic: #1 · After: spec 001 (loop events recorded) · Integrates: VCR cassettes (arrrrny/zikzak_inappwebview#238), dws_playground#7, registry gates (arrrrny/raptorr#127)
