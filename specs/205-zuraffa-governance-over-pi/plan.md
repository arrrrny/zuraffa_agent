# Implementation Plan: Zuraffa governance extensions over pi

**Branch**: `205-zuraffa-governance-over-pi` | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/205-zuraffa-governance-over-pi/spec.md`
(GitHub issue #205). Depends on: `arrrrny/zuraffa_agent#204` (the wrapper
runtime + DI + host ports + `PiRuntimeAdapter` this spec extends).

## Summary

Add the governance, observability, artifacts, MCP/eval, and host-integration
slices on top of the wrapper introduced by spec 204. The wrapper opens the pi
runtime and contributes Zuraffa's ecosystem value as thin adapters over pi
primitives: `beforeTool` / `afterTool` / provider-request hooks for
allowlists, argument guards, risk tiers, minimization, PII scrubbing, artifact
refs, and redaction (fail closed); pi signals + memoized deadlines + host
`AgentApprovalPort` for durable approvals; `AgentTelemetryPort` adapters for
secret-safe audit/metrics/health/crash/usage over pi commits, phases,
submissions, tool calls, and provider events; pi-mcp when present for MCP;
pi-evals + Zuraffa reporting for eval/cassettes; pi tool-result hooks +
`AgentArtifactPort` for oversized results. zfa-generated entities cover only
Zuraffa-owned configuration, governance, audit/eval, and artifact data. No
second policy engine, approval dispatcher, MCP client, transcript, cassette,
or eval engine is added; no browser or host imports; no Flutter. The durable
surface stays behind wrapper-owned interfaces until pi#12 lands.

## Technical Context

**Language/Version**: Dart ^3.11 (current `zuraffa_agent` SDK constraint;
matches `zuraffa_permissions` / `zuraffa_notifications` and spec 204).

**Primary Dependencies**: `pi` (gated on `arrrrny/pi#12` for durable
surface; pi's `beforeTool` / `afterTool` / provider-request hooks, `AgentTool`,
`Conversation`, `AgentEvent`, `Model` / `Usage` / `AgentMessage` exist today
— 204 research D3), `pi_mcp` (optional; MCP adaptation), `pi_evals`
(optional; eval/cassette replay), `zuraffa` (framework: GetIt, entities,
config, PackageModule), `zorphy_annotation` + `zorphy` / `build_runner`
(model layer, constitution IX). The wrapper from 204 (`ZuraffaAgent` facade,
`AgentRuntimeFactory`, `AgentPortRegistry`, `PiRuntimeAdapter`,
`PiExtensionBootstrap`, `ZuraffaAgentModule`) is the substrate.

**Storage**: N/A in this slice — transcripts/sessions are pi `Storage`
adapters (architecture plan §7.5); artifacts ride the 204 `AgentArtifactPort`;
eval/cassette replay is pi-evals. The wrapper defines no new storage.

**Testing**: `test` + `mocktail` (pure Dart), `dart test -j 2` (fleet
test-concurrency guard). Pure-Dart in-memory adapters run the same contract
suite as production adapters (FR-009 / SC-009). Governance tests assert
deny-before-execution, redact-before-model, fail-closed sanitizer, default-deny,
missing-approval-port, and pi-mcp-absent paths.

**Target Platform**: Pure Dart (engine purity, constitution VII — no Flutter
dependency; `dart:io`--free runtime paths).

**Project Type**: Library (zfa package — the `zuraffa_agent` package itself,
extended per this spec).

**Performance Goals**: Passthrough — the slice adds only hook bodies,
telemetry taps, and artifact routing; no measurable overhead beyond pi's own
runtime.

**Constraints**: No second policy engine / approval dispatcher / MCP client /
transcript / cassette / eval engine (FR-001, FR-004, FR-006, FR-007;
SC-010); no browser or host imports (FR-012); no global `GetIt.instance`
reads in business logic (FR-004); generated output never hand-edited
(FR-008, constitution I/IX); durable behavior claimed only once pi#12 lands
(FR-011, SC-011).

**Scale/Scope**: One package slice on top of 204 — governance hook bodies,
telemetry/audit adapters, artifact routing, MCP/eval delegation, host-port
wiring, zfa-generated entities, contracts/tests. Product-neutral;
browser-specific policy stays in `zuraffa_browser_agent`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check |
|-----------|-------|
| I. CLI-Built Only | PASS — Zuraffa-owned entities/enums/value objects via `zfa entity create`; use cases via `zfa make`; build via `zfa build`; no hand-written model classes. |
| II. Stop on First Misfire | PASS — plan makes no gate bypass; any `zfa` / build / analyze failure halts with postmortem. |
| III. Escalate Upstream and Wait | PASS — a pi#12 or pi-mcp / pi-evals gap, or a zfa defect, is escalated (`arrrrny/pi`, `arrrrny/zuraffa`), not patched locally. |
| IV. Postmortem Every Misfire | PASS — misfires during implementation get postmortems per register. |
| V. Gates Are Non-Negotiable | PASS — plan ends at planning; implementation gated on 204 landing and pi#12 for durable behavior. |
| VI. Probes Must Retain Evidence | PASS — contract test output is retained; no blind gating. |
| VII. Engine Purity | PASS — pure Dart, no Flutter, `dart:io`-free runtime. |
| VIII. Attributed Ports | PASS — no new ports beyond pi attribution already present; pi-mcp / pi-evals carry their own licenses. |
| IX. Zorphy Is the Model Layer | PASS — `GovernancePolicy`, `RiskTier`, `RedactionRule`, `AgentAuditRecord`, `AgentArtifactDescriptor`, `AgentEvaluationReport` are Zorphy-generated; no hand-written JSON. |
| X. Post-Build Analysis Pristine | PASS — every `zfa build` is followed by `dart analyze` (0 errors, 0 warnings) before proceeding. |

No violations. No Complexity Tracking section needed.

## Project Structure

### Documentation (this feature)

```text
specs/205-zuraffa-governance-over-pi/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root — extensions to the 204 tree)

```text
lib/
├── zuraffa_agent.dart                      # Barrel export (204)
└── src/
    ├── runtime/                            # 204: ZuraffaAgent facade + factory
    ├── ports/                              # 204: host-injection ports
    ├── pi/                                 # 204: PiRuntimeAdapter + bootstrap
    │   ├── pi_runtime_adapter.dart         # 204: isolates pi surface
    │   └── pi_extension_bootstrap.dart     # 204: installs extensions
    ├── governance/                         # NEW in 205
    │   ├── entities/                       # Zorphy entities (zfa-generated)
    │   │   ├── governance_policy.zorphy.dart
    │   │   ├── risk_tier.zorphy.dart
    │   │   ├── redaction_rule.zorphy.dart
    │   │   ├── agent_audit_record.zorphy.dart
    │   │   ├── agent_artifact_descriptor.zorphy.dart
    │   │   └── agent_evaluation_report.zorphy.dart
    │   ├── hooks/                          # beforeTool / afterTool / provider
    │   │   ├── tool_governance_hooks.dart  # allow/deny/arg guard/risk/approval
    │   │   ├── result_minimization_hooks.dart  # scrub / artifact / redact
    │   │   └── provider_request_hooks.dart # egress sanitization
    │   └── policy_resolver.dart            # deterministic policy merge
    ├── approvals/                          # NEW in 205 (pi#12-gated)
    │   ├── approval_gate.dart              # pi signal + memoized deadline
    │   └── approval_port_adapter.dart      # host AgentApprovalPort wiring
    ├── observability/                      # NEW in 205
    │   ├── telemetry_adapter.dart          # AgentTelemetryPort → pi events
    │   ├── audit_recorder.dart             # AgentAuditRecord writer
    │   ├── metrics_reporter.dart           # usage / health / crash
    │   └── secret_scrubber.dart            # default secret patterns
    ├── artifacts/                          # NEW in 205
    │   └── artifact_router.dart            # oversized → AgentArtifactPort
    ├── mcp/                                # NEW in 205 (pi-mcp delegation)
    │   └── mcp_adapter.dart                # thin governance/telemetry taps
    ├── eval/                               # NEW in 205 (pi-evals delegation)
    │   └── eval_adapter.dart               # pi-evals + Zuraffa reporting
    ├── module/                             # 204: ZuraffaAgentModule seam
    └── di/                                 # 204 + 205 generated DI
test/
├── governance/                             # NEW: hook + policy tests
├── approvals/                              # NEW: gate + port tests
├── observability/                          # NEW: telemetry + scrubber tests
├── artifacts/                              # NEW: router tests
├── mcp/                                    # NEW: pi-mcp delegation tests
├── eval/                                   # NEW: pi-evals + report tests
└── ports/                                  # 204: per-port contract tests
```

**Structure Decision**: Extend the 204 tree additively. The `runtime/`,
`ports/`, `pi/`, `module/`, and `di/` directories are owned by 204 and
consumed here; this spec adds `governance/`, `approvals/`, `observability/`,
`artifacts/`, `mcp/`, `eval/` as sibling slices. Each new slice follows
`zuraffa_permissions` (Zorphy entities + pure-Dart in-memory adapters +
explicit DI) and `zuraffa_notifications` (composed capability service)
structurally, importing neither browser nor product code (FR-012, SC-010).
`mcp/` and `eval/` are thin delegation layers — pi-mcp / pi-evals own the
transport / replay; the wrapper contributes only governance/telemetry
metadata.

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.