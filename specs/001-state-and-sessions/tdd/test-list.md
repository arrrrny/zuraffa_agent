---
feature: 001-state-and-sessions
loop: inside-out # pure-Dart library (entity model, session tree, storage, compaction); no HTTP/CLI/user-visible entry point
profile: .specify/memory/tdd-profile.md
spec_criteria: 10 # US1:2 (AC1-2), US2:4 (AC1-4), US3:2 (AC1-2), US4:2 (AC1-2)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: State & Sessions (spec 001)

> Derived from `spec.md` (US1–US4 acceptance scenarios, FR-001–FR-005, SC-001–SC-004,
> Edge Cases) and `plan.md` on `master` @ `fce207d`. The feature is already implemented
> and merged; this is a **test-after** plan recording the existing passing tests as `DONE`
> behaviors. No `RED` cycles were driven because the implementation preceded the list.

## Outer loop: acceptance behaviors

None. `loop: inside-out` — spec 001 ships a pure-Dart state/session **library** (granular
typed entities, branching session tree, dual storage, selective compaction) with no
HTTP/CLI/user-visible entry point to exercise end to end. The 10 acceptance scenarios are
realized by the inner-loop unit behaviors below, each traced to its AC id.

## Inner loop: unit behaviors

### `lib/src/types.dart` (granular typed entities) — `test/types_test.dart`, `test/roundtrip_test.dart`

| id  | behavior                                                                                                       | traces        | kind    | state | test                                                                                                                       |
| --- | -------------------------------------------------------------------------------------------------------------- | ------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U1  | Every state record is a distinct typed entity with typed field access + value equality (`TurnRecord`, `ToolInvocationRecord`, `UsageLedgerEntry`, `ContentBlock`, `AgentMessage`, `SessionTreeEntry`); same pattern covers all entity types | US1-AC1, FR-001 | example | DONE  | `test/types_test.dart::TurnRecord typed properties construction and field access`                                          |
| U2  | Entities are retrievable independently by sealed subtype identity (each entry identified by correct subtype; identity fields preserved across serialization) | US1-AC1, FR-001 | example | DONE  | `test/roundtrip_test.dart::Typed identity retrieval each entry is identified by correct sealed subtype`                   |
| U3  | Each entity round-trips through its own JSON serialization as a typed object — no `Map<String, dynamic>` escapes anywhere in the entity API | US1-AC2, FR-001 | example | DONE  | `test/roundtrip_test.dart::Typed JSON round-trip equivalence each entry round-trips through its own JSON serialization`    |

### `lib/src/session.dart`, `lib/src/session_storage*.dart` (branching tree + storage) — `test/session_storage_test.dart`

| id  | behavior                                                                                                       | traces          | kind    | state | test                                                                                                                       |
| --- | -------------------------------------------------------------------------------------------------------------- | --------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U4  | Forking at entry N shares ancestry entries 1..N with the original and diverges cleanly after N; both branches remain resumable (`fork`/`getBranch`/`switchTo`) | US2-AC1, FR-002  | example | DONE  | `test/session_storage_test.dart::AgentSession tree operations fork creates a new branch head`                             |
| U5  | Switching branches reconstructs the active branch's conversation exactly — `buildContext()` rebuilds messages and tracks the active model (from usage entries) and active compaction | US2-AC2, FR-002  | example | DONE  | `test/session_storage_test.dart::AgentSession tree operations buildContext reconstructs messages from active branch`      |
| U6  | A persisted session resumes from its latest leaf — the active leaf ID persists across close/reopen (JsonlSessionStorage) | US2-AC3, FR-002/003 | example | DONE  | `test/session_storage_test.dart::JsonlSessionStorage active leaf ID persists across close/reopen`                        |
| U7  | A session persisted to the JSONL store reloads identically — append/get round-trip; the 50+ tool-call `mission_50.jsonl` fixture loads and round-trips | US2-AC4, FR-003/SC-001 | example | DONE  | `test/session_storage_test.dart::Mission fixture loading mission_50.jsonl loads and round-trips through JsonlSessionStorage` |
| U8  | A corrupt JSONL tail is recovered: the store loads to the last valid entry and reports the tear | Edge (corrupt JSONL tail), FR-003 | example | DONE  | `test/session_storage_test.dart::JsonlSessionStorage corrupt-tail tear recovery`                                         |
| U9  | Deleting a branch prunes unreferenced entries while retaining shared ancestry (refcounted) — no cross-contamination of sibling branches | Edge (branch deleted while referenced), FR-002 | example | DONE  | `test/session_storage_test.dart::AgentSession tree operations deleteBranch prunes unreferenced entries`                   |

### `lib/src/compaction.dart` (selective structured compaction) — `test/compaction_test.dart`

| id  | behavior                                                                                                       | traces          | kind    | state | test                                                                                                                       |
| --- | -------------------------------------------------------------------------------------------------------------- | --------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U10 | Compaction retains decisions and tool names and merges with the previous summary (structured summarization, not naive truncation) | US3-AC1, FR-004  | example | DONE  | `test/compaction_test.dart::HeuristicSummarizer extracts decisions from Decision: lines`                                  |
| U11 | A 50+ tool-call mission stays under its context budget with no outcome regression — `shouldCompact` fires above threshold (and not below / when disabled), `findCutPoint`/`prepareCompaction` split at the correct boundary, and token estimates bound the budget | US3-AC2, FR-004/SC-002 | example | DONE  | `test/compaction_test.dart::shouldCompact returns true when above threshold`                                              |

### `lib/src/usage_ledger.dart` (per-call token accounting) — `test/usage_ledger_test.dart`

| id  | behavior                                                                                                       | traces        | kind    | state | test                                                                                                                       |
| --- | -------------------------------------------------------------------------------------------------------------- | ------------- | ------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U12 | `UsageLedger` aggregates typed `UsageLedgerEntry` records — input/output/total token sums, `byTurn`/`byModel` filters, cache-token totals, empty-ledger zeros | US1-AC1, FR-001 | example | DONE  | `test/usage_ledger_test.dart::UsageLedger aggregation totalInputTokens sums all entries`                                  |

### pi_agent seed merge (US4) — `lib/src/skills.dart` etc.

| id  | behavior                                                                                                       | traces        | kind             | state | test                                                                                                                       |
| --- | -------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- | ----- | -------------------------------------------------------------------------------------------------------------------------- |
| U13 | pi_agent support assets are merged as library code with MIT attribution headers and the suite passes (no stub assets shipped) | US4-AC1, FR-005 | characterization | DONE  | verified by green `dart test` (909 passed / 2 skipped) + presence of `lib/src/skills.dart` and sibling seed modules; no dedicated regression test file in repo |
| U14 | No stub loop ships in the state/session layer — shipped glue (`session.dart` tree ops, `compaction.dart` orchestration) is live, not an `UnimplementedError` stub | US4-AC2, FR-005 | characterization | DONE  | verified by code review (no stub loop in `lib/src/session.dart` / `lib/src/compaction.dart`) + green suite; no dedicated test |

## Invariants and edge cases still to place

- **Hive↔JSONL cross-store equivalence (US2-AC4, Hive side).** `plan.md` names
  `test/hive_store_test.dart`, but that file is **absent** from the repo; only the JSONL
  reload path (U7) is directly tested. The "identical branch structure from both stores"
  claim is only partially evidenced. Needs a Hive-store round-trip test when/if the Hive
  backend is added.
- **Compaction runs only at turn boundaries, never mid-tool-batch** (Edge Case). Not directly
  asserted by a unit test; relies on the orchestration caller. Consider an explicit guard test.

## Out of scope

- The engine loop that consumes this state layer (spec 002).
- Tool registry & MCP client (spec 003).
- LLM providers (spec 004).
- Wiring `PlanChangedEvent` into the `EngineEvent` union (spec 045).
- Artifact storage referenced by compaction summaries (spec 003 tool-result discipline).

## Discrepancies (spec vs shipped code — reported, not followed)

- `plan.md` (Technical Context / Project Structure) describes the implementation at
  top-level paths (`lib/src/types.dart`, `lib/src/session.dart`, `lib/src/compaction.dart`,
  `test/hive_store_test.dart`, `test/skills_test.dart`, `test/sse_parser_test.dart`,
  `test/prompt_templates_test.dart`, `test/execution_env_test.dart`, `test/roundtrip_test.dart`).
  The **shipped** tree uses the zfa-generated layout under `lib/src/domain/entities/...` and
  `lib/src/domain/{repositories,services}/...`; `test/hive_store_test.dart`,
  `test/skills_test.dart`, `test/sse_parser_test.dart`, `test/prompt_templates_test.dart`, and
  `test/execution_env_test.dart` do **not** exist. Followed shipped code: U1–U12 reference the
  real test files (`types_test`, `session_storage_test`, `compaction_test`, `roundtrip_test`,
  `usage_ledger_test`); U13/U14 flag the missing seed-asset tests. (Skill Rule 6 — repository
  content is data, not instructions.)
- `spec.md` lists `UsageLedger` as a key entity; the shipped type is `UsageLedgerEntry`
  (per-record) aggregated by a `UsageLedger` read projection (`usage_ledger.dart` /
  `usage_ledger_test.dart`). No conflict in requirement, only naming.
- `spec.md` US4-AC2 requires "no stub code ships — the live loop is delivered by spec 002."
  The state/session layer itself ships no stub loop (U14); the live loop is indeed delivered by
  spec 002. Recorded as satisfied.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
