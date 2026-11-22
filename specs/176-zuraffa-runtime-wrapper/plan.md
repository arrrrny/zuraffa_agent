# Implementation Plan: Zuraffa runtime wrapper around pi

**Branch**: `176-zuraffa-runtime-wrapper` | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/176-zuraffa-runtime-wrapper/spec.md`

## Summary

Rebuild `zuraffa_agent` as a thin, zfa-native generic wrapper around pi
(issue #204; architecture plan §7). The package keeps its repository and
history but gets a clean next-major API: a runtime factory/facade that opens a
pi runtime from injected configuration, installs extensions through one seam
composed into pi's real `AgentOptions` hooks, and returns pi conversations,
submissions, watches, tasks, and outcomes. All agent loops, provider calls,
transcript/session format, compaction, and durable execution stay in pi — the
wrapper contains none of them and imports no browser package or host
application. Host injection follows `zuraffa_permissions`/`zuraffa_notifications`:
ports + pure-Dart in-memory adapters + zfa-generated entities/use cases +
explicit DI. The feature is born locked on `arrrrny/pi#12` and implementation
starts after it lands. Governance policy is issue #205 and installs through
this feature's extension seam.

## Technical Context

**Language/Version**: Dart ^3.8.0 (the current `zuraffa_agent` constraint;
raise together with `zuraffa_permissions`/`zuraffa_notifications` when their
reference packages move, not before).

**Primary Dependencies**: `pi` (gated on `arrrrny/pi#12`), `zuraffa`
(framework: GetIt, entities, config, PackageModule), `zorphy_annotation` +
`zorphy`/`build_runner` (model layer, constitution IX), optional
`zuraffa_permissions`/`zuraffa_notifications`-style capability ports as needed.

**Storage**: N/A — the wrapper owns no storage; pi `SessionStorage` adapters
own transcripts/sessions (architecture plan §7.5). The wrapper may define a
storage port for hosts to inject.

**Testing**: `test` + `mocktail` (pure Dart), `dart test -j 2` (fleet
test-concurrency guard — deliberately overrides this repo's committed
`dart_test.yaml` `concurrency: 4` on shared hosts that also run the pool).
In-memory adapters run the same contract suite as production adapters
(FR-008).

**Target Platform**: Pure Dart (engine purity, constitution VII — no Flutter
dependency; `dart:io`-free runtime paths).

**Project Type**: Library (zfa package).

**Performance Goals**: Pass-through only — the wrapper adds DI wiring and hook
installation and nothing else. No performance claim is made beyond that
design constraint; it is measured before any such claim is stated.

**Constraints**: No agent loop/provider/transcript/compaction/durable scheduler
in this package (FR-004); no browser or host imports (FR-008); no global
`GetIt.instance` reads in business logic (FR-006); generated output never
hand-edited (FR-001); no pi seam invented that pi does not have (FR-005).

**Scale/Scope**: One package; small surface — a factory, ports, one extension
seam, DI registration, contracts/tests. Governance/telemetry/MCP/eval adapters
are separate capability packages that install through the seam.

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
├── zuraffa_agent.dart                      # Barrel export (re-exports pi types it hands back)
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
    ├── extensions/                         # The one extension-installation seam
    │   ├── zuraffa_extension.dart          # Hook bodies composed into AgentOptions
    │   └── extension_bootstrap.dart        # Composes extensions into pi options
    ├── pi/                                 # Wrapper-owned pi runtime construction
    │   └── pi_runtime_adapter.dart         # The only place pi's runtime is built
    ├── domain/entities/                    # Zfa-generated (Zorphy)
    ├── module/
    │   └── zuraffa_agent_module.dart       # Scaffolded PackageModule seam
    └── di/                                 # Generated DI registration
        └── zuraffa_agent_package_registrar.dart  # Emitted by `zfa package create`
test/
├── zuraffa_agent_test.dart                 # Factory + facade tests
├── ports/                                  # Per-port contract tests
├── extensions/                             # Extension-seam tests
└── ...
```

**Structure Decision**: Single pure-Dart package following the
`zuraffa_permissions` layout: domain ports + in-memory adapters + DI + use
cases, with a thin `runtime/` facade over pi. Generated output (entities and
the package registrar) lands wherever `zfa` writes it — this tree names the
CLI's paths, not hand-drawn alternatives. `pi/` is the only place pi's runtime
is *constructed*; pi types are referenced and re-exported directly everywhere
else (FR-005).

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.
