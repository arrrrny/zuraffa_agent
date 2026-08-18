<!--
Sync Impact Report
- Version change: 1.1.0 → 1.2.0 (MINOR: materially expanded guidance — scoped
  exemption clause added to an existing principle)
- Modified principles: IX. Zorphy Is the Model Layer — added exemption for the
  attributed pi_agent seed entity layer (specs/002-state-and-sessions); the
  normative rule text above the clause is retained byte-identical. I–VIII
  untouched.
- Added principles: none
- Added sections: none
- Removed sections: none
- Deferred items: none
-->

# zuraffa_agent Constitution

The agent ENGINE of the Zuraffa ecosystem. Built by automation, halted by
gates, fixed by postmortem.

## Core Principles

### I. CLI-Built Only
This repo is built exclusively through the `zfa` CLI and its spec-driven
pipeline automation (`specify init`, speckit skills, `scripts/pipeline.sh`).
No manual scaffolding. No structural edits outside generated extension
points. Ecosystem apps built on zuraffa are likewise zfa-CLI-built only.

### II. Stop on First Misfire
The automation halts at the first failed gate. Never bypass a gate. Never
continue degraded. A halted pipeline is the system working as designed.

### III. Escalate Upstream and Wait
When the misfire is in the framework/tooling itself (`zfa` CLI, pipeline,
zuraffa), file it on `arrrrny/zuraffa`, halt all downstream work, and WAIT
for the framework fix. No local workarounds around framework defects.

### IV. Postmortem Every Misfire
Every halt gets a postmortem — expected / happened / root cause / fix /
prevention — committed to git. Precedent format: misfire #1 (`a1130ad`),
misfire #2 (`231de04`).

### V. Gates Are Non-Negotiable
Stage gates advance only on pass. PRs are never auto-merged: CI and human
review, always. The spec is the contract.

### VI. Probes Must Retain Evidence
Anything that gates a pipeline retries on transient failure and never
discards its own evidence. Every attempt's output is persisted; nothing
gates the pipeline blind.

### VII. Engine Purity
The engine stays Flutter-free: no Flutter dependencies in `pubspec.yaml`.
Runtime paths are `dart:io`-free.

### VIII. Attributed Ports
Ported code carries attribution headers. Current ports: `dart_agent_core`,
`pi_agent` (both MIT).

### IX. Zorphy Is the Model Layer (non-negotiable)
ALL entities, enums, and value objects in this codebase MUST be created
with Zorphy (@Zorphy annotations, generated .zorphy.dart/.g.dart outputs
via the build pipeline). No hand-written model classes, no hand-rolled
JSON serialization, no plain-class domain data. Zorphy is the single
model system for the engine.

**Exemption — attributed port seeds (v1.2.0)**: Article IX governs
zuraffa-native model code. Attributed ports under Principle VIII are
exempt where Zorphy conversion would break the port: the seed entity
layer ported from `pi_agent` (specs/002-state-and-sessions — `types.dart`,
`tools.dart`, and the session/compaction entity surface) keeps its
hand-written sealed classes with attribution headers, because (a) Principle
VIII requires ports to retain upstream shape with provenance, and (b) that
layer's serialization contracts (JSONL on-disk format, hand-written Hive
adapters) are fixed by the feature's ratified contracts. The exemption is
scoped to the seeded files and their in-place evolution; every NEW
zuraffa-native entity, enum, or value object created outside those ported
files MUST use Zorphy.

## Scope
This constitution governs the `zuraffa_agent` repo and the spec-driven
pipeline that builds it. Downstream ecosystem apps inherit Principles I–VI
through the `zfa` CLI itself.

## Misfire Register
Postmortems live in git history, not in this file. The register is the
commit log; each misfire postmortem references the halt it explains.
Seed entries: misfire #1 (`a1130ad`), misfire #2 (`231de04`).

## Governance
This constitution supersedes ad-hoc practice; conflicts resolve in its
favor. Amendments go through the speckit-constitution skill only: PATCH for
clarifications, MINOR for new principles, MAJOR for removals or
redefinitions — each amendment updates the version line and dates below.
Compliance is verified at every gate and in every PR; a violation is a
misfire (Principle II) and gets a postmortem (Principle IV).

**Version**: 1.2.0 | **Ratified**: 2026-08-18 | **Last Amended**: 2026-08-18
