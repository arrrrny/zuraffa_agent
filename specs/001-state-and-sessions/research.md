# Research: State & Sessions

**Feature**: `002-state-and-sessions` | **Date**: 2026-08-18

Research resolved the Technical Context unknowns for the pi_agent seed merge.
Primary sources: pi_agent sources (`~/Developer/pi/pi_agent`, branch
`001-dart-agent-package` — 14 lib files, 6,816 LOC total), epic
arrrrny/zuraffa_agent#1, Dart SDK 3.12.2 (local), pub.dev.

## R1: Hive flavor for a pure-Dart package

- **Decision**: `hive_ce` ^2.19.0 (community edition; 2.19.3 already in the
  local pub cache).
- **Rationale**: The original `hive` package is discontinued (stuck at 2.2.3);
  hive_ce is its actively maintained "spiritual continuation" — pure Dart, no
  native dependencies, no Flutter requirement (pub.dev/packages/hive_ce). This
  satisfies FR-003 (Hive for device storage) and the pure-Dart/no-Flutter
  constraint.
- **Alternatives considered**: original `hive` 2.2.3 (unmaintained, max 223
  type IDs); `isar` (native binaries, not pure Dart); `drift`/sqlite (SQL
  machinery contradicts a typed-entity append-only session tree); a custom
  binary file format (rebuilds what Hive already provides).

## R2: Package identity and layout

- **Decision**: One pure Dart package `zuraffa_agent` at the repo root
  (`pubspec.yaml`, `lib/`, `test/` created by this feature). Ported modules
  live under `lib/src/` with a public barrel `lib/zuraffa_agent.dart`
  (replacing pi_agent's `lib/pi.dart`).
- **Rationale**: The epic defines zuraffa_agent as the engine package; the repo
  currently contains only specs/scaffolding, and this spec lands first (spec
  001's loop consumes these types). A root-level single package is the minimal
  structure — no workspace/monorepo machinery needed yet.
- **Alternatives considered**: `packages/zuraffa_agent/` nested layout
  (deferred until a second package actually exists); multiple packages per
  module (YAGNI).

## R3: Runtime dependencies

- **Decision**: single runtime dependency `hive_ce`. No `yaml`, no `http`.
- **Rationale**: `yaml` is declared in pi_agent's pubspec but never imported —
  skills and prompt templates parse frontmatter with a built-in simple parser;
  keep that behavior. `http` is imported only by `llm_client.dart`, which this
  spec does NOT port (providers are spec 004). Dev deps: `test`, `lints`.
- **Alternatives considered**: adding `yaml` for full frontmatter support
  (unnecessary — existing parser covers the SKILL.md/template format; can be
  revisited if frontmatter needs nesting).

## R4: Hive adapter strategy

- **Decision**: hand-written `TypeAdapter`s for the sealed entry/message
  hierarchies, isolated in `hive_adapters.dart`; the `hive_ce` import exists
  only in `hive_session_store.dart` + `hive_adapters.dart`.
- **Rationale**: ~18 small types; hand-written adapters avoid build_runner +
  hive_ce_generator dev-dependency chain and keep the engine package
  dependency-lean. Explicit type IDs give deterministic cross-store
  equivalence tests (Hive binary vs JSONL JSON must round-trip the same
  typed entities).
- **Alternatives considered**: `hive_ce_generator` codegen (adds build_runner,
  source_gen, analyzer to every build; fine in apps, heavy for a library this
  size); storing JSON strings inside Hive (loses the typed-entity discipline).

## R5: Modeling the new granular entities

- **Decision**: `TurnRecord`, `ToolInvocationRecord`, and `UsageLedgerEntry`
  are typed session-tree entries (new sealed subclasses alongside
  MessageEntry et al.), not separate tables. `UsageLedger` is a query
  projection over `UsageLedgerEntry` records on the active branch.
- **Rationale**: One storage interface (FR-003), branch-scoped by
  construction, fork/resume-safe with zero extra machinery, and each record is
  retrievable by its own entry ID — exactly US1's "distinct typed entity by
  its own identity". Turn/tool entries reference message entry IDs instead of
  duplicating message content.
- **Alternatives considered**: separate Hive boxes keyed by turn number
  (breaks branch isolation: a fork would need box surgery); deriving turns
  on-the-fly from message scans (no stable identity, no place to hang
  usage/duration).

## R6: Entry ID scheme

- **Decision**: monotonic timestamp-based IDs (microsecond timestamp in
  base36 + per-process sequence suffix), replacing pi_agent's bare
  `microsecondsSinceEpoch.toRadixString(36)`.
- **Rationale**: pi_agent's scheme collides when two entries append in the
  same microsecond (parallel tool batches make this realistic). The sequence
  suffix keeps IDs short, lexicographically sortable (JSONL tail-load relies
  on ordering), and collision-free within a session's single-writer model.
- **Alternatives considered**: UUID v4 (no ordering, longer); ULID package
  (extra dependency for ~10 lines of logic).

## R7: Corrupt JSONL tail handling

- **Decision**: `SessionStorage.init()` loads up to the first undecodable
  line, and returns a typed tear report (`lineNumber`, `reason`,
  `salvagedEntryCount`) alongside loaded state.
- **Rationale**: Spec edge case requires "loads to the last valid entry and
  reports the tear". pi_agent's silent `catch (_) { continue; }` hides
  corruption. Append-only JSONL semantics mean anything after a torn line
  cannot be trusted to belong to a coherent sequence.
- **Alternatives considered**: skipping bad lines and continuing (pi_agent
  behavior — can resurrect orphaned entries with dangling parentIds); failing
  the whole load (destroys the salvage requirement).

## R8: Branch deletion with shared ancestry

- **Decision**: deletion walks up from the deleted branch leaf and prunes
  entries whose remaining child count is zero, using child counts derived
  on demand from the full entry list. No persistent refcounts.
- **Rationale**: The session tree is append-only; child counts are always
  derivable in one pass. This implements "ancestry entries are retained
  (refcounted), leaf-only entries pruned" with the simplest correct
  mechanism — no refcount bookkeeping to corrupt.
- **Alternatives considered**: persistent refcount fields on entries
  (mutation on append-only records, extra state to maintain); copy-on-write
  branch isolation (multiplies storage; ancestry sharing is the point).

## R9: Compaction summarizer

- **Decision**: injectable `CompactionSummarizer` interface. Default
  implementation is a structured heuristic (extracts decisions, tool names,
  key results, plan state from typed entries) producing a typed
  `CompactionSummary` with retained-category fields plus resolvable
  `ArtifactRef`s. pi_agent's `_generatePlaceholderSummary` is NOT ported.
  Compaction is checked only at turn boundaries (edge case) and its
  `CompactionEntry` lands on the active branch only.
- **Rationale**: FR-004 requires selective + structured compaction; the
  placeholder text summary is exactly the "stub code" US4 forbids. Keeping
  the summarizer injectable lets spec 004 wire an LLM-backed summarizer
  without touching this layer. `ArtifactRef` resolution is declared here as
  the `ArtifactResolver` interface; spec 003's tool-result discipline
  implements it (per the spec's assumptions).
- **Alternatives considered**: porting the placeholder and fixing later
  (ships a stub — violates SC-004); LLM-only summarization (couples this
  layer to providers that don't exist yet — spec 004).

## R10: Scope of the port — stubs excluded

- **Decision**: Port `types.dart` (entity subset), `tools.dart`,
  `session.dart`, `session_storage.dart`, `compaction.dart` (reworked per
  R9), `skills.dart`, `prompt_templates.dart`, `execution_env.dart`,
  `sse_parser.dart`, and tests. Do NOT port `agent_loop.dart`, `agent.dart`,
  `llm_client.dart`, `conversion.dart` (spec 001/004 territory). Fix pi_agent's
  `typedef AgentTool<T, D> = dynamic` hack by importing the real class from
  `tools.dart`. Rename `Session` → `AgentSession` (spec's entity name); other
  public names stay as ported.
- **Rationale**: US4's port list is explicit; the loop stub is completed by
  spec 001, not shipped here — so zero stub code exists by construction.
  The dynamic typedef would leak `dynamic` into the type system (against the
  typed-entity contract); the import-ordering problem it worked around
  disappears once loop-runtime types (AgentState, AgentContext,
  AgentLoopConfig, hook contexts, AgentEvent) move to spec 001's files.
- **Alternatives considered**: porting everything then deleting (churn);
  keeping loop types in types.dart (blocks the typedef fix, muddies entity
  vs runtime-state boundary that US1 is about).

## R11: Attribution and license

- **Decision**: Every ported file opens with a header comment attributing
  pi_agent (`~/Developer/pi`, branch `001-dart-agent-package`, MIT). Repo
  LICENSE is MIT with a NOTICE-style attribution section for ported sources.
- **Rationale**: US4/FR-005 mandate attribution; both sides are MIT so
  relicensing is a non-issue, but provenance must be explicit.

## R12: Token estimation

- **Decision**: keep pi_agent's chars/4 heuristic as the default estimator
  behind a `TokenEstimator` function type; actual `UsageLedgerEntry` counts
  take precedence when present (estimate only the delta since the last
  recorded usage).
- **Rationale**: SC-002's budget check needs a token estimate before any LLM
  call; providers report real usage only after. Ledger-first estimation is
  strictly more accurate than pure heuristics without coupling to providers.

## R13: Constitution IX (Zorphy) vs hand-written ported entities — T005 addendum

- **Decision**: amend the constitution (PATCH/MINOR via
  `/skill:speckit-constitution`) to exempt the ported seed entity layer from
  Article IX, rather than applying Zorphy annotations to the ported classes.
  Constitution v1.2.0 carries the exemption clause scoped to the seeded
  files (`types.dart`, `tools.dart`, session/compaction entity surface) and
  their in-place evolution; new zuraffa-native entities still MUST use Zorphy.
- **Rationale**: Principle VIII requires ports to retain upstream shape with
  attribution; regenerating pi_agent's MIT-ported sealed classes through
  Zorphy would rewrite the ported code under a different authorship model
  and break provenance fidelity. The layer's serialization contracts are
  fixed by ratified feature contracts (JSONL on-disk format in
  contracts/session-api.md; hand-written Hive adapters per R4), which Zorphy
  codegen does not produce. It would also violate R3's single-runtime-dep
  constraint (zorphy_annotation runtime dep + build_runner/zorphy dev chain).
- **Alternatives considered**: applying @Zorphy to the ported entities
  (breaks VIII fidelity, fixed serialization contracts, and the single-dep
  constraint); leaving the conflict unresolved (constitution gates would
  fail every PR touching the entity layer).

## Summary of resolved NEEDS CLARIFICATION items

| Item | Resolution |
|------|------------|
| Hive flavor (pure Dart) | `hive_ce` ^2.19.0 (R1) |
| Package layout | single package at repo root (R2) |
| Runtime deps | `hive_ce` only (R3) |
| Hive adapters | hand-written, isolated files (R4) |
| Turn/tool/usage modeling | typed session-tree entries + ledger projection (R5) |
| ID collisions | timestamp + sequence suffix (R6) |
| Corrupt JSONL tail | typed tear report, stop at first bad line (R7) |
| Branch deletion | derived child counts, upward prune (R8) |
| Compaction summarizer | injectable interface + structured default (R9) |
| Stub elimination | exclude loop/agent/llm/conversion; fix dynamic typedef (R10) |
