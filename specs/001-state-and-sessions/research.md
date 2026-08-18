# Phase 0 Research & Technical Decisions: State & Sessions

**Feature**: `001-state-and-sessions`  
**Date**: 2026-08-18  
**Status**: Completed  
**Spec**: [spec.md](spec.md)

---

## 1. Context & Objectives

The state and session layer is the foundational state substrate for `zuraffa_agent`. It replaces monolithic state blobs (such as `dart_agent_core`'s `AgentState`) with a granular, strongly-typed entity model, a branching tree-of-entries session model, dual Hive/JSONL storage, selective structured compaction, and ported support assets from `pi_agent`.

This document consolidates all architectural and technical decisions resolving the requirements and constraints in `spec.md` and `.specify/memory/constitution.md` (v1.1.0).

---

## 2. Research Decisions & Rationales

### R1: Project Type and Platform Target
- **Decision**: Single pure-Dart package located at the repository root (`package:zuraffa_agent`), targeting Dart SDK `^3.6` (for sealed classes, exhaustive pattern matching, and records).
- **Rationale**: The engine must remain strictly Flutter-free (Constitution VII). A pure Dart package at the repository root allows the CLI and subsequent spec features (specs 002–006) to consume the library directly.
- **Alternatives considered**:
  - Sub-package in `packages/core`: Unnecessary directory nesting for a standalone engine repository.
  - Multi-package monorepo: Premature complexity for the initial core engine package.

### R2: Model Layer & Entity Architecture (Constitution IX)
- **Decision**: Define domain entities, value objects, and message parts with `@Zorphy` annotations and sealed class hierarchies. The build pipeline generates `.zorphy.dart` and `.g.dart` files for typed serialization, immutability, and equality.
- **Rationale**: Constitution Article IX mandates that all entities, enums, and value objects must be generated with Zorphy. This eliminates hand-rolled serialization errors, prevents untyped `Map<String, dynamic>` escapes, and provides deterministic round-trip guarantees.
- **Alternatives considered**:
  - Hand-written plain Dart classes: Violates Constitution IX.
  - Freezed / json_serializable: Replaced by the project's standard Zorphy model layer.

### R3: Granular Entity Architecture vs. Monolithic Blob
- **Decision**: Model state as independent granular entities:
  - `SessionTreeEntry` (base sealed entity for all tree nodes)
  - `MessageEntry` (wraps `AgentMessage` with role and timestamp)
  - `TurnRecord` (encapsulates turn sequence, message IDs, tool invocations, duration, stop reason)
  - `ToolInvocationRecord` (tool name, typed args, result entry link, error flag, artifact refs)
  - `UsageLedgerEntry` (per-call token metrics and model metadata)
  - `CompactionEntry` (structured summary, first kept entry ID, tokens before/after)
- **Rationale**: Allows random access by entity ID, atomic writes, branch-specific context reconstruction, and clean projection into accounting structures (such as `UsageLedger`).

### R4: Unified Storage Interface with Hive and JSONL Backends
- **Decision**: Expose an abstract `SessionStorage` interface backed by three implementations:
  1. `HiveSessionStorage`: Fast binary KV store using `hive_ce` (`^2.19.0`) for on-device persistence.
  2. `JsonlSessionStorage`: Human-readable, append-friendly streaming format for CI, debugging, and inspection.
  3. `InMemorySessionStorage`: Volatile in-memory store for unit test speed and isolation.
- **Rationale**: Satisfies FR-003 and SC-001 (round-trip equivalence across backends). `hive_ce` is a pure-Dart fork of Hive compatible with modern Dart 3.
- **Alternatives considered**:
  - SQLite (`sqflite` or `drift`): Heavy native dependencies; unnecessary for append-only hierarchical trees.
  - Flat JSON file: Rewriting the full session file on every turn is O(N^2) in I/O and risks data loss on crashes.

### R5: Session Tree Topology and Branching Semantics
- **Decision**: Model sessions as an append-only tree of immutable `SessionTreeEntry` items. Each entry carries an immutable `id`, an optional `parentId`, and a `timestamp`.
  - `fork(entryId)`: Points the active leaf pointer to an existing ancestor `entryId`. Subsequent appends branch from that node without modifying existing nodes.
  - `switchTo(leafId)`: Moves the active leaf pointer to any branch head or node.
  - `buildContext()`: Reconstructs the conversation from the active leaf up to the root, filtering and ordering entries chronologically.
  - `deleteBranch(headId)`: Prunes entries up the ancestor chain until reaching a node with other active child references (derived reference counting).
- **Rationale**: Matches the `pi_agent` tree-of-entries model; provides clean divergence without state contamination; enables sub-agent exploration (spec 005) and eval replay (spec 006).

### R6: Monotonic Identifier Generation
- **Decision**: Generate entry IDs using a monotonic scheme: base36 microsecond timestamp combined with a per-process atomic sequence counter (e.g., `m_<timestamp36>_<seq>`).
- **Rationale**: Guarantees chronological sorting, uniqueness, zero collision under single-writer semantics, and zero external UUID dependencies.

### R7: Corrupt JSONL Tail Recovery (Tear Resilience)
- **Decision**: `JsonlSessionStorage.init()` parses lines sequentially until EOF. If a line is malformed or truncated (e.g., unexpected process kill during write):
  1. All valid entries prior to the tear are loaded and retained.
  2. A `JsonlTear` diagnostic record (`lineNumber`, `reason`, `salvagedCount`) is returned.
  3. The storage allows appending subsequent entries safely or creating a fresh branch from the last valid entry.
- **Rationale**: Fulfills the edge case requirement in `spec.md` and ensures resilience in CLI and embedded environments.

### R8: Selective Structured Compaction & Heuristic Summarizer
- **Decision**: Implement compaction as a turn-boundary operation triggered when estimated context tokens exceed `(contextWindow - reserveTokens) * triggerThresholdRatio`.
  - Compaction retains: explicit decisions, tool names called, key results/outputs, and current plan state.
  - Verbose tool output and message history prior to the cut point are replaced with a `CompactionSummary` and `ArtifactRef` references.
  - A `CompactionEntry` is appended to the active branch tree containing the summary and `firstKeptEntryId`.
  - Default summarizer is `HeuristicSummarizer` with pluggable `CompactionSummarizer` interface for LLM-based summarization.
- **Rationale**: Extends trajectories from ~10 to 50+ turns without exceeding LLM context windows (SC-002), while maintaining deterministic outcome parity.

### R9: Engine Purity and Adapter Quarantine (Constitution VII)
- **Decision**: Core logic in `lib/src/types.dart`, `lib/src/session.dart`, `lib/src/compaction.dart`, and `lib/src/usage_ledger.dart` MUST NOT import `dart:io`.
  - `dart:io` usage is strictly quarantined to interface-backed storage adapters: `lib/src/session_storage_impl.dart`, `lib/src/hive_session_store.dart`, `lib/src/skills.dart`, `lib/src/prompt_templates.dart`, and `lib/src/execution_env.dart`.
- **Rationale**: Adheres to Constitution VII and the CI purity gate allowlist.

### R10: Ported Seed Assets from `pi_agent` with MIT Attribution (Constitution VIII)
- **Decision**: Merge ported assets from `pi_agent` (branch `001-dart-agent-package`):
  1. Multimodal message and content block models (`types.dart`)
  2. Parameter validation schema engine (`tools.dart`)
  3. Skill markdown discovery and parsing (`skills.dart`)
  4. Prompt template argument substitution (`prompt_templates.dart`)
  5. Local execution environment abstraction (`execution_env.dart`)
  6. Server-Sent Events stream parser (`sse_parser.dart`)
- Every ported file carries an explicit MIT attribution header and is documented in `NOTICE` and `LICENSE`. No unwired stub code or dummy loops ship in `lib/`.

---

## 3. Summary of Decisions Matrix

| Topic | Selected Decision | Key Benefit |
|---|---|---|
| Package Type | Pure Dart `zuraffa_agent` (`^3.6`) | Flutter-free engine purity |
| Model Generation | Zorphy `@Zorphy` + sealed classes | Typed safety, no untyped maps |
| Storage Backends | Hive (`hive_ce`), JSONL, InMemory | Device persistence + debug inspectability |
| Session Model | Immutable append-only tree | Fork/switch/resume with ancestry sharing |
| Compaction | Selective structured (turn-boundary) | 50+ iterations within token budget |
| Ported Assets | Attributed `pi_agent` seed (zero stubs) | High fidelity to proven primitives |
