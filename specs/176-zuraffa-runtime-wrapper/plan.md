# Implementation Plan: Zuraffa runtime wrapper around pi

**Branch**: `176-zuraffa-runtime-wrapper` | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/176-zuraffa-runtime-wrapper/spec.md`

## Summary

Rebuild `zuraffa_agent` as a thin, zfa-native generic wrapper around pi
(issue #204; architecture plan §7). The package keeps its repository and
history but gets a clean next-major API: a runtime factory/facade that opens a
pi runtime from injected configuration, installs generic Zuraffa extensions
over pi's registry/hooks, and returns pi conversations, submissions, watches,
tasks, and outcomes. All agent loops, provider calls, transcript/session
format, compaction, and durable execution stay in pi — the wrapper contains
none of them and imports no browser package or host application. Host
injection follows `zuraffa_permissions`/`zuraffa_notifications`: ports +
pure-Dart in-memory adapters + zfa-generated entities/use cases + explicit DI.
The feature is born locked on `arrrrny/pi#12`; unstable pre-#12 pi surface is
isolated behind wrapper-owned interfaces.

## Technical Context

**Language/Version**: Dart ^3.11 (current `zuraffa_agent` SDK constraint;
matches `zuraffa_permissions`/`zuraffa_notifications`).

**Primary Dependencies**: `pi` (gated on `arrrrny/pi#12`), `zuraffa`
(framework: GetIt, entities, config, PackageModule), `zorphy_annotation` +
`zorphy`/`build_runner` (model layer, constitution IX), optional
`zuraffa_permissions`/`zuraffa_notifications`-style capability ports as needed.

**Storage**: N/A — the wrapper owns no storage; pi `Storage` adapters own
transcripts/sessions (architecture plan §7.5). The wrapper may define a
storage port for hosts to inject.

**Testing**: `test` + `mocktail` (pure Dart), `dart test -j 2`. In-memory
adapters run the same contract suite as production adapters (FR-008).

**Target Platform**: Pure Dart (engine purity, constitution VII — no Flutter
dependency; `dart:io`-free runtime paths).

**Project Type**: Library (zfa package).

**Performance Goals**: Passthrough — the wrapper adds only DI wiring and hook
installation; no measurable overhead beyond pi's own runtime.

**Constraints**: No agent loop/provider/transcript/compaction/durable scheduler
in this package (FR-004); no browser or host imports (FR-008); no global
`GetIt.instance` reads in business logic (FR-006); generated output never
hand-edited (FR-001).

**Scale/Scope**: One package; small surface — a factory, ports, extensions,
DI registration, contracts/tests. Governance/telemetry/MCP/eval adapters are
product-neutral.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check |
|-----------|-------|
| I. CLI-Built Only | PASS — package scaffold via `zfa package create`; entities via `zfa entity create`; use cases via `zfa make`; no hand-written model classes. |
| II. Stop on First Misfire | PASS — plan makes no gate bypass; any `zfa`/build/analyze failure halts with postmortem. |
| III. Escalate Upstream and Wait | PASS — a pi#12 gap or zfa defect is escalated (`arrrrny/pi`, `arrrrny/zuraffa`), not patched locally. |
| IV. Postmortem Every Misfire | PASS — misfires during implementation get postmortems per register. |
| V. Gates Are Non-Negotiable | PASS — plan ends at planning; implementation gated on pi#12 landing. |
| VI. Probes Must Retain Evidence | PASS — contract test output is retained; no blind gating. |
| VII. Engine Purity | PASS — pure Dart, no Flutter, `dart:io`-free runtime. |
| VIII. Attributed Ports | PASS — no new ports beyond pi attribution already present. |
| IX. Zorphy Is the Model Layer | PASS — all entities/enums/value objects are Zorphy-generated; no hand-written JSON. |
| X. Post-Build Analysis Pristine | PASS — every `zfa build` is followed by `dart analyze` (0 errors, 0 warnings) before proceeding. |

No violations. No Complexity Tracking section needed.

## Project Structure

### Documentation (this feature)

```text
specs/176-zuraffa-runtime-wrapper/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
lib/
├── zuraffa_agent.dart                      # Barrel export
└── src/
    ├── runtime/
    │   ├── zuraffa_agent.dart              # ZuraffaAgent facade (factory)
    │   └── agent_runtime_factory.dart      # Opens pi runtime from config
    ├── ports/                              # Technology-agnostic host-injection ports
    │   ├── agent_credential_port.dart      # Credentials / secure store
    │   ├── agent_storage_port.dart         # Storage / environment
    │   ├── agent_egress_port.dart          # HTTP / egress
    │   ├── agent_telemetry_port.dart       # Telemetry / failure reporting
    │   ├── agent_artifact_port.dart        # Artifacts / oversized results
    │   ├── agent_approval_port.dart        # Approval presentation / human notify
    │   └── agent_lifecycle_port.dart       # Lifecycle hooks
    ├── pi/                                 # Wrapper-owned pi adapters
    │   ├── pi_runtime_adapter.dart         # Isolates unstable pi#12 surface
    │   └── pi_extension_bootstrap.dart     # Installs extensions into pi registry
    ├── governance/                         # Zfa-generated policy + pi hooks
    │   ├── entities/                       # Zorphy entities (policy, risk tier)
    │   └── hooks/                          # beforeTool/afterTool wiring
    ├── module/
    │   └── zuraffa_agent_module.dart       # Optional PackageModule seam
    └── di/                                 # Generated DI registration
test/
├── zuraffa_agent_test.dart                 # Factory + facade tests
├── ports/                                  # Per-port contract tests
├── governance/                             # Governance hook tests
└── ...
```

**Structure Decision**: Single pure-Dart package following the
`zuraffa_permissions` layout: domain ports + data (in-memory adapters) + DI +
use cases, with a thin `runtime/` facade over pi. The `pi/` adapter layer is
the only place that touches pi's unstable pre-#12 surface (FR-005).

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.