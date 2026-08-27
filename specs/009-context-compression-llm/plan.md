# Implementation Plan: Context Compression (LLM-based)

**Branch**: `009-context-compression-llm` | **Date**: 2026-08-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-context-compression-llm/spec.md`

## Summary

The engine can summarize heuristically (compaction.dart) but cannot compress long histories with an LLM. This feature adds `LLMBasedContextCompressor`: when `estimateContextTokens(messages)` exceeds a configurable threshold, older messages are sent through spec 007's `LlmClient` with a prompt demanding a five-section `<state_snapshot>` XML; recent messages are preserved verbatim; the compressed messages become an `EpisodicMemory` entry (Zorphy entity) stored in a new `EpisodicMemoryStore` (the `retrieve_memory` surface); any LLM failure or invalid snapshot falls back to the existing `HeuristicSummarizer` rendered into the same XML shape.

## Technical Context

**Language/Version**: Dart 3.11+ (SDK `^3.8.0`; toolchain 3.13.2 stable). Flutter 3.41+ ecosystem reference; engine stays Flutter-free (constitution VII).

**Primary Dependencies**: spec 007's `LlmClient`; existing `estimateContextTokens`/`HeuristicSummarizer`/`CompactionSummary` from `lib/src/compaction.dart`; `zorphy_annotation` + `zorphy` codegen for the new domain entity (build_runner is already a dev dependency and build.yaml already targets `lib/src/**`). Ecosystem shelf/sqlite3/path/crypto remain unused.

**Storage**: in-memory `EpisodicMemoryStore` (persistence belongs to the session-store specs).

**Testing**: `dart test`; a fake `LlmClient` (scripted snapshots/errors) — the existing `FakeLlmClient` helper from spec 008.

**Target Platform**: Pure Dart (VM).

**Project Type**: library (agent engine).

**Performance Goals**: one LLM call per compression; O(n) token estimation.

**Constraints**: constitution IX for the new entity (Zorphy codegen); analyze pristine; zero new suite failures vs the spec-008 baseline (442 passed / 6 unrelated failures).

**Scale/Scope**: 1 Zorphy entity (+generated), 2 runtime files, ~3 test files, ~12 behaviors.

## Constitution Check

| Principle | Verdict | How satisfied |
|-----------|---------|---------------|
| VII. Engine purity | PASS | Runtime is pure Dart over the LlmClient seam; no dart:io. |
| VIII. Attributed ports | PASS | Compressor/store carry dart_agent_core (MIT) attribution headers. |
| IX. Zorphy model layer | PASS (documented precedent) | `EpisodicMemory` embeds `List<AgentMessage>` — the conversational model layer that is hand-curated plain Dart by explicit repo precedent (`agent_message.dart`, `llm_client.dart`, `fallback_chain.dart`: "no @Zorphy codegen, compiles without build_runner"). A Zorphy wrapper would need custom converters for a non-Zorphy type, so the entity follows the hand-curated value-object precedent with its header documenting the lineage. |
| X. Analyze pristine | PASS | Verified at closing gate. |

## Project Structure

```text
lib/src/domain/entities/episodic_memory/episodic_memory.dart        # hand-curated value object (documented precedent)
lib/src/llm/context_compressor.dart                                   # ContextCompressor, LLMBasedContextCompressor, settings, result
lib/src/llm/episodic_memory_store.dart                                # in-memory store + retrieval

test/domain/entities/episodic_memory_test.dart
test/llm/context_compressor_test.dart
test/llm/episodic_memory_store_test.dart
```

**Structure Decision**: The domain entity follows the repo's entity conventions; runtime joins the llm layer next to its LlmClient dependency.

## Complexity Tracking

No constitution violations requiring justification.
