# Implementation Plan: State & Sessions

**Branch**: `002-state-and-sessions` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-state-and-sessions/spec.md`

**Note**: This template is filled in by the `/skill:speckit-plan` command; its definition describes the execution workflow.

## Summary

Port pi_agent's production assets into `zuraffa_agent` — a new pure-Dart
package at the repo root — as the engine's granular typed state layer:
branching session tree (fork/switch/resume) over Hive (`hive_ce`) and JSONL
stores behind one `SessionStorage` interface, multimodal typed messages, new
`TurnRecord`/`ToolInvocationRecord`/`UsageLedgerEntry` entities for
per-identity retrieval, selective structured compaction with injectable
summarizer + artifact refs, plus skills/prompt-templates/ExecutionEnv/SSE
support assets — all with MIT attribution headers and zero stub code. The
pi_agent loop stub, agent shell, LLM client, and conversion layer are NOT
ported (specs 001/004 own them); pi_agent's placeholder compaction summarizer
is replaced by a structured heuristic default.

## Technical Context

**Language/Version**: Dart ^3.12 (local SDK 3.12.2; SDK constraint `^3.6` for sealed-class exhaustiveness)

**Primary Dependencies**: `hive_ce` ^2.19.0 (only runtime dependency; no `yaml` — frontmatter parser is built-in; no `http` — LLM client not ported). Dev: `test` ^1.25, `lints` ^6.

**Storage**: Hive (hive_ce boxes, device) + JSONL files (debug/CI) + in-memory, behind `SessionStorage` (FR-003)

**Testing**: `package:test`; shared behavioral contract suite run against all three store implementations; deterministic fixture missions (50+ tool calls)

**Target Platform**: Pure Dart — macOS/Linux/Windows VM (primary), no Flutter dependency at any layer

**Project Type**: library (pure Dart package)

**Performance Goals**: 50+ tool-call missions within context budget under compaction (SC-002); session append O(1); `buildContext()` O(branch length); store round-trip of a 200-entry session < 1s

**Constraints**: No `Map<String, dynamic>` escapes in the entity API (custom extensibility points excepted); append-only session tree (no entry mutation); single-writer per session; MIT license with ported-source attribution; zero stub code shipped

**Scale/Scope**: 200+ sequential tool calls per mission (spec 001 upstream); ~9 ported modules (~2,300 LOC source) + ~3 new modules + tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status: constitution is an unfilled template** — `.specify/memory/constitution.md`
contains only placeholders (`[PRINCIPLE_1_NAME]`, `[GOVERNANCE_RULES]`, …), so
no ratified gates exist to evaluate. No violations are possible against an
empty constitution; this plan proceeds under the template's implicit defaults
(library-first, test-first, simplicity) which the design satisfies:

- **Library-first**: single self-contained package, independently testable,
  documented via dartdoc comments on every public member (ported style).
- **Test-first**: every acceptance scenario maps to a test file
  (quickstart.md); contract suite runs against all store implementations.
- **Simplicity**: one runtime dependency; hand-written Hive adapters instead
  of a codegen chain; derived child-counts instead of refcount state.

**Follow-up (out of scope here)**: ratify the constitution via
`/skill:speckit-constitution`; re-audit this feature against it.

**Post-Phase-1 re-check**: design artifacts (research/data-model/contracts)
add no projects, no codegen, no speculative abstraction — defaults still
satisfied. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/002-state-and-sessions/
├── plan.md              # This file (/skill:speckit-plan command output)
├── research.md          # Phase 0 output (/skill:speckit-plan)
├── data-model.md        # Phase 1 output (/skill:speckit-plan)
├── quickstart.md        # Phase 1 output (/skill:speckit-plan)
├── contracts/           # Phase 1 output (/skill:speckit-plan)
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
├── zuraffa_agent.dart       # public barrel (replaces pi.dart)
└── src/
    ├── types.dart           # sealed hierarchies: messages, blocks, entries (+ TurnRecord, ToolInvocationRecord, UsageLedgerEntry), Skill/PromptTemplate/Model/Usage/CompactionSettings
    ├── tools.dart           # AgentTool, validateParameters (real class; dynamic typedef dropped)
    ├── session.dart         # AgentSession — tree ops, fork/switch/resume/deleteBranch
    ├── session_storage.dart # SessionStorage + InMemory + Jsonl (tear reporting); no hive import
    ├── hive_session_store.dart  # HiveSessionStorage (sole hive_ce import #1)
    ├── hive_adapters.dart   # hand-written TypeAdapters (sole hive_ce import #2)
    ├── usage_ledger.dart    # UsageLedger projection
    ├── compaction.dart      # settings/estimator/cut-point + injectable CompactionSummarizer, HeuristicSummarizer, ArtifactRef/Resolver
    ├── skills.dart          # SKILL.md loading + system-prompt formatting
    ├── prompt_templates.dart# template loading + arg substitution
    ├── execution_env.dart   # ExecutionEnv abstraction + LocalExecutionEnv
    └── sse_parser.dart      # byte-stream → SSE event maps
test/
├── types_test.dart
├── tools_test.dart
├── session_test.dart            # fork/switch/resume/restart/delete-branch
├── session_storage_test.dart    # JSONL tear handling, contract suite (shared)
├── hive_store_test.dart
├── roundtrip_test.dart          # cross-store typed equivalence (US1)
├── compaction_test.dart         # budget + outcome equality (US3)
├── usage_ledger_test.dart
├── skills_test.dart
├── prompt_templates_test.dart
├── execution_env_test.dart
├── sse_parser_test.dart
└── fixtures/
    └── mission_50.jsonl         # 50+ tool-call fixture mission
example/
└── session_demo.dart            # manual fork/diverge/resume smoke
```

**Structure Decision**: Single package at the repo root (research R2) — the
repo becomes the Dart package this feature seeds; specs 001–006 land their
modules into the same `lib/src/`. The `hive_ce` import is quarantined to two
files so JSONL/in-memory paths stay pure-stdlib Dart.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — section intentionally empty.
