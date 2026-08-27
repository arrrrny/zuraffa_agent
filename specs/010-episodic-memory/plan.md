# Implementation Plan: Episodic Memory

**Branch**: `010-episodic-memory` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-episodic-memory/spec.md`

## Summary

Spec 009 already landed the `EpisodicMemory` entity and the in-memory `EpisodicMemoryStore` (add/retrieve/search) plus the compressor wiring that creates entries on compression. This feature completes the memory story around that foundation: a pagination surface on the store (`list({limit, offset})`), a model-facing `RetrieveMemoryTool` (snapshot_id lookup + paginated listing), an `AgentMessageHistory` value object (messages + episodicMemories, memory summaries available for context building), and a `PersistentEpisodicMemoryStore` that mirrors entries into the `SessionStorage` backend as `CustomEntry` records and rebuilds them on restore.

## Technical Context

**Language/Version**: Dart 3.13.2 (stable), SDK constraint `^3.11.0` per pubspec.yaml.

**Primary Dependencies**: none new — `AgentMessage` from `lib/src/types.dart`, `EpisodicMemory`/`EpisodicMemoryStore` from spec 009, `SessionStorage`/`CustomTreeEntry`/`CustomEntry` from the existing session layer, `LlmToolSpec` from `lib/src/llm/llm_client.dart` (spec 007).

**Storage**: `SessionStorage` port (in-memory fake in tests; hive/jsonl backends exist in lib and are out of scope).

**Testing**: `dart test` (package:test). Suite baseline at branch point: +453 passed / 6 unrelated pre-existing loading failures; 111 pre-existing analyzer issues.

**Target Platform**: platform-agnostic Dart package (Linux x64 build box).

**Constraints**: constitution VII — no `dart:io` outside the CI-allowlisted adapter files (all new files are pure Dart); VIII — attribution headers on ported lineage (AgentMessageHistory/PersistentEpisodicMemoryStore follow the dart_agent_core-lineage header pattern used by spec 009's files); X — analyze pristine on new files.

**Scale/Scope**: 3 new lib files (~80-140 lines each), 1 extended lib file, 3 new test files + 1 extended test file. No changes to existing public behavior (store extension is additive).

## Constitution Check

- **VII engine purity**: new files import only `types.dart`, `llm_client.dart`, `episodic_memory.dart`, `session_storage.dart`, `dart:convert` — no `dart:io`. ✓
- **VIII attributed ports**: the episodic-memory concept is ported from dart_agent_core (MIT); the files carry the same attribution header style as spec 009's `episodic_memory_store.dart`. ✓
- **IX Zorphy model layer**: hand-curated plain-Dart precedent documented in entity headers (same as `episodic_memory.dart` — embeds non-Zorphy `AgentMessage`, so Zorphy codegen would need custom converters; documented precedent applies). ✓
- **X analyze pristine**: every new file must report zero analyzer issues; full-suite failure delta vs. baseline must be zero. ✓

## Project Structure

### Documentation (this feature)

```text
specs/010-episodic-memory/
├── spec.md                # refined (this cycle)
├── plan.md                # this file
├── tasks.md               # task breakdown
└── tdd/
    ├── test-list.md       # behavior inventory (TDD plan)
    ├── cycle-log.md       # per-cycle red/green evidence
    └── verification.md    # final TDD audit vs. rubric
```

### Files to Create / Modify

```text
lib/src/llm/
├── episodic_memory_store.dart        # MODIFY: add list({limit, offset}) pagination
├── agent_message_history.dart        # NEW: messages + episodicMemories value object
├── retrieve_memory_tool.dart         # NEW: model-facing retrieve_memory tool
└── persistent_episodic_memory_store.dart  # NEW: SessionStorage-backed store

test/llm/
├── episodic_memory_store_test.dart   # MODIFY: pagination tests (U2-U4)
├── agent_message_history_test.dart   # NEW
├── retrieve_memory_tool_test.dart    # NEW
└── persistent_episodic_memory_store_test.dart  # NEW (incl. in-memory SessionStorage fake)
```

## Realistic Boundaries / De-scoping

- Engine-loop context assembly (US1 AC2 "agent builds context") is spec 002's integration point; here `AgentMessageHistory` provides the value object that integration will consume.
- The tool *registry/dispatch* wiring (making retrieve_memory callable end-to-end inside a running mission) belongs to specs 002/003; this spec ships the tool class + its LlmToolSpec surface + execution semantics.
- Real hive/jsonl persistence backends exist already; this spec depends only on the `SessionStorage` port contract.
- Concurrency: single-isolate sequential semantics (same as the rest of the runtime specs); no mutexes.

## Rollout / Compatibility

Additive only: existing `EpisodicMemoryStore` API unchanged; `LLMBasedContextCompressor.store` field type unchanged, so a `PersistentEpisodicMemoryStore` can be injected where the in-memory store was. No migration needed — `CustomEntry` records with `customType: 'episodic_memory'` are self-describing; older sessions without them restore to an empty memory store.

## Verification

- Per-behavior red→green cycles committed individually (cycle-log.md).
- Gates: `dart analyze` (0 issues in new files; no new issues overall) + `dart test` (no new failures vs. +453/-6 baseline; new tests green).
- Mutation checks on the pagination slicing, the snapshot_id branch, and the restore filter (the three most bug-prone spots).
