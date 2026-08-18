# Quickstart & Validation Guide: State & Sessions

**Feature**: `001-state-and-sessions`  
**Date**: 2026-08-18  
**Spec**: [spec.md](spec.md)

---

## 1. Overview & Setup

This guide describes end-to-end validation scenarios for the state and session architecture. All scenarios execute as pure Dart tests and verification scripts with zero Flutter dependencies.

### Prerequisites
- Dart SDK `^3.6` (Dart 3.12+ recommended)
- Dependencies installed: `dart pub get`

---

## 2. Validation Scenarios

### Scenario 1: Granular Typed State Round-Trip (US1 Acceptance)
Validates that complex multi-turn missions with multimodal messages, tool invocations, turn records, and usage ledger entries round-trip through both Hive and JSONL backends without untyped `Map<String, dynamic>` escapes.

```bash
# Run the round-trip acceptance suite
dart test test/roundtrip_test.dart test/types_test.dart
```

**Expected Outcome**:
- All entities deserialize as their concrete typed subclasses (`MessageEntry`, `TurnRecord`, `ToolInvocationRecord`, `UsageLedgerEntry`).
- Identity retrieval (`storage.getEntry(id)`) returns the exact object.
- Equivalence check between `HiveSessionStorage` and `JsonlSessionStorage` succeeds.

---

### Scenario 2: Branching Session Tree (Fork, Switch, Resume, Prune) (US2 Acceptance)
Validates tree-of-entries branching, ancestry sharing, clean branch divergence without sibling leakage, and session resumption after simulated engine restart.

```bash
# Run session branching and storage behavioral tests
dart test test/session_test.dart test/session_storage_test.dart
```

**Expected Outcome**:
- Forking at entry $N$ shares entries $1..N$ and diverges cleanly for subsequent appends.
- `buildContext()` on branch A matches pre-fork history; branch B contains only its own divergent entries.
- Re-opening storage resumes from the persisted active leaf.
- `deleteBranch` prunes only unreferenced leaf entries while preserving shared ancestry nodes.

---

### Scenario 3: Selective Structured Compaction on 50+ Tool Calls (US3 Acceptance)
Validates that long-running trajectories crossing context budget thresholds undergo selective structured compaction, retaining decisions, tool names, key results, and plan state while resolving preserved `ArtifactRef` references.

```bash
# Run the compaction fixture test suite
dart test test/compaction_test.dart
```

**Expected Outcome**:
- Mission with 50+ tool calls stays within the configured token budget.
- Compaction executes strictly at turn boundaries.
- Final mission outcome matches the uncompacted baseline (decision and plan state parity).
- All `ArtifactRef` identifiers resolve successfully through the `ArtifactResolver`.

---

### Scenario 4: Attributed Seed Port & Zero-Stub Quality Gate (US4 Acceptance)
Validates that ported `pi_agent` modules compile cleanly, carry proper MIT attribution headers, and contain zero stub code or unhandled placeholders.

```bash
# Run all unit tests for ported seed modules
dart test test/skills_test.dart test/prompt_templates_test.dart test/execution_env_test.dart test/sse_parser_test.dart test/tools_test.dart

# Validate analyzer cleanliness and fatal info compliance
dart analyze --fatal-infos

# Verify zero unwired stubs or placeholder typedefs in library code
! grep -rn "placeholder\|TODO\|typedef AgentTool.*dynamic" lib/
```

**Expected Outcome**:
- All ported support asset tests pass 100%.
- Zero analyzer warnings or lints.
- Purity gate check confirms `dart:io` imports are confined strictly to allowlisted storage adapters.

---

## 3. Manual Interactive Smoke Test

Run the included example script to verify live branching and tree traversal in the terminal:

```bash
dart run example/session_demo.dart
```
