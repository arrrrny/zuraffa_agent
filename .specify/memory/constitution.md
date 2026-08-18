<!--
Sync Impact Report
- Version change: (unratified template) → 1.0.0
- Added principles: I. CLI-Built Only, II. Stop on First Misfire,
  III. Escalate Upstream and Wait, IV. Postmortem Every Misfire,
  V. Gates Are Non-Negotiable, VI. Probes Must Retain Evidence,
  VII. Engine Purity, VIII. Attributed Ports
- Added sections: Scope, Misfire Register, Governance
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

**Version**: 1.0.0 | **Ratified**: 2026-08-18 | **Last Amended**: 2026-08-18
