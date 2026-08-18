# Implementation Plan: State & Sessions

**Branch**: `001-state-and-sessions` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-state-and-sessions/spec.md`

**Note**: This template is filled in by the `/skill:speckit-plan` command; its definition describes the execution workflow.

## Summary

Port and seed `pi_agent`'s production assets into `zuraffa_agent` — a standalone pure-Dart package at the repository root — establishing the engine's granular typed state layer:
1. Granular typed entity model (`SessionTreeEntry`, `AgentMessage`, `TurnRecord`, `ToolInvocationRecord`, `UsageLedgerEntry`) generated via Zorphy without untyped `Map<String, dynamic>` escapes.
2. Branching session tree with first-class fork, switch, resume, and ancestry sharing over dual storage engines (`HiveSessionStorage` via `hive_ce` and `JsonlSessionStorage`) behind a unified `SessionStorage` interface.
3. Selective structured compaction (turn-boundary execution, heuristic and pluggable summarizers, preserved `ArtifactRef` pointers) extending trajectories to 50+ tool calls within context budgets while maintaining baseline outcome parity.
4. Clean integration of ported `pi_agent` support modules (tool schema validation, skills, prompt templates, execution environment, SSE parser) with explicit MIT attribution headers and zero shipped stub code.

## Technical Context

**Language/Version**: Dart SDK ^3.6 (local SDK 3.12.2) targeting modern sealed class hierarchies, exhaustive switch matching, and records.

**Primary Dependencies**: `hive_ce` ^2.19.0 (runtime binary storage engine); dev dependencies: `test` ^1.25.0, `lints` ^6.1.0.

**Storage**: Dual-backend architecture behind abstract `SessionStorage` interface:
- `HiveSessionStorage` (`hive_ce` binary boxes) for fast device-local storage.
- `JsonlSessionStorage` (human-readable JSON lines with corrupt tail tear recovery) for debug and CI inspection.
- `InMemorySessionStorage` for isolated, high-speed unit testing.

**Testing**: `package:test` running unit suites, cross-store round-trip equivalence suites, branch isolation tests, and 50+ tool-call deterministic fixture missions (`test/fixtures/mission_50.jsonl`).

**Target Platform**: Pure Dart runtime on macOS, Linux, and Windows; 100% Flutter-free.

**Project Type**: library (pure Dart package at repository root `package:zuraffa_agent`).

**Performance Goals**:
- Support 50+ sequential tool calls under compaction without context budget overflow (SC-002).
- O(1) entry append time to session tree.
- O(branch length) conversation context reconstruction (`buildContext()`).
- Store round-trip of a 200-entry session in < 1s.

**Constraints**:
- Absolute engine purity: zero Flutter dependencies (Constitution VII); `dart:io` strictly quarantined to storage and file-loader adapters.
- Granular typed state: no monolithic blobs or untyped `Map<String, dynamic>` escapes in the domain API (Constitution IX).
- Single-writer per session with append-only tree integrity.
- Full MIT attribution on all ported `pi_agent` assets with zero stub code shipped.

**Scale/Scope**: ~9 ported and adapted modules (~2,300 LOC) plus new state entities, dual storage drivers, compaction engine, and comprehensive test suite.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (CLI-Built Only)**: PASS. All repository structure and spec pipelines are executed via automation and standard speckit workflows.
- **Principle II (Stop on First Misfire)**: PASS. Stage gates in `scripts/pipeline.sh` strictly enforce pass/fail criteria before progression.
- **Principle III (Escalate Upstream and Wait)**: PASS. Upstream dependencies on `arrrrny/zuraffa` follow standard escalation.
- **Principle IV (Postmortem Every Misfire)**: PASS. Any pipeline halt will be recorded with root cause and fix in git history.
- **Principle V (Gates Are Non-Negotiable)**: PASS. Preflight, analyze, test, and review gates are fully enforced.
- **Principle VI (Probe Evidence Retained)**: PASS. All preflight, test, and build outputs are captured in `.workflow/state/`.
- **Principle VII (Engine Purity)**: PASS. `pubspec.yaml` contains zero Flutter dependencies. Core entities and logic (`types.dart`, `session.dart`, `compaction.dart`, `usage_ledger.dart`) contain no `dart:io` imports. `dart:io` is restricted strictly to allowlisted adapter modules (`session_storage_impl.dart`, `hive_session_store.dart`, `skills.dart`, `prompt_templates.dart`, `execution_env.dart`).
- **Principle VIII (Attributed Ports)**: PASS. All ported `pi_agent` files carry standard MIT attribution headers, and repository `NOTICE` and `LICENSE` files record provenance.
- **Principle IX (Zorphy Is the Model Layer)**: PASS. Domain entities, value objects, and enums are defined with `@Zorphy` and sealed hierarchies, generating typed serializers and eliminating untyped map escapes.

**Post-Phase-1 Re-Check**:
The generated design artifacts (`research.md`, `data-model.md`, `contracts/`, `quickstart.md`) strictly adhere to Principles I–IX with no unratified exceptions or architectural violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-state-and-sessions/
├── plan.md              # This file (/skill:speckit-plan command output)
├── research.md          # Phase 0 output (/skill:speckit-plan command)
├── data-model.md        # Phase 1 output (/skill:speckit-plan command)
├── quickstart.md        # Phase 1 output (/skill:speckit-plan command)
├── contracts/           # Phase 1 output (/skill:speckit-plan command)
│   ├── session-api.md
│   ├── compaction-api.md
│   └── support-assets.md
└── tasks.md             # Phase 2 output (/skill:speckit-tasks command - NOT created by /skill:speckit-plan)
```

### Source Code (repository root)

```text
pubspec.yaml                 # package zuraffa_agent; deps: hive_ce; dev: test, lints
LICENSE                      # MIT
NOTICE                       # pi_agent port attribution
lib/
├── zuraffa_agent.dart       # public barrel
└── src/
    ├── types.dart           # sealed hierarchies: SessionTreeEntry, AgentMessage, ContentBlock, TurnRecord, ToolInvocationRecord, UsageLedgerEntry
    ├── tools.dart           # AgentTool, validateParameters (JSON-Schema subset)
    ├── session.dart         # AgentSession — tree operations, fork, switch, resume, deleteBranch
    ├── session_storage.dart # SessionStorage abstract interface, StoreOpenResult, JsonlTear
    ├── session_storage_impl.dart # InMemorySessionStorage and JsonlSessionStorage
    ├── hive_session_store.dart   # HiveSessionStorage implementation
    ├── hive_adapters.dart   # Binary TypeAdapters for Hive storage
    ├── usage_ledger.dart    # UsageLedger read projection
    ├── compaction.dart      # Compaction core, HeuristicSummarizer, ArtifactRef, ArtifactResolver
    ├── skills.dart          # SKILL.md discovery and system prompt formatting
    ├── prompt_templates.dart# Template parsing and argument substitution
    ├── execution_env.dart   # ExecutionEnv abstraction and LocalExecutionEnv
    └── sse_parser.dart      # SSE byte-stream parser
test/
├── types_test.dart
├── tools_test.dart
├── session_test.dart            # fork, switch, resume, prune tests
├── session_storage_test.dart    # JSONL tear resilience, store contract suite
├── hive_store_test.dart         # Hive binary adapter tests
├── roundtrip_test.dart          # Cross-store typed equivalence (US1)
├── compaction_test.dart         # Budget, outcome equality, turn boundary (US3)
├── usage_ledger_test.dart       # Usage metrics projection
├── skills_test.dart
├── prompt_templates_test.dart
├── execution_env_test.dart
├── sse_parser_test.dart
└── fixtures/
    └── mission_50.jsonl         # 50+ tool-call deterministic fixture mission
example/
└── session_demo.dart            # Interactive branching smoke demo
```

**Structure Decision**: Single library package at the repository root. Core engine logic stays platform-agnostic and I/O-free, while storage implementations and file loaders encapsulate necessary I/O operations behind abstract interfaces.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — all design aspects comply with Constitution Principles I–IX.
