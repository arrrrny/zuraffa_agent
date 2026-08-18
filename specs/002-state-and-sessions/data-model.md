# Data Model: State & Sessions

**Feature**: `002-state-and-sessions` | **Date**: 2026-08-18

Entity model for granular typed state. All persisted entities are session-tree
entries: append-only nodes carrying `(id, parentId, timestamp)` plus a typed
payload. Identities are string IDs (monotonic timestamp base36 + sequence
suffix — research R6).

Base type (ported from pi_agent `types.dart`):

```dart
sealed class SessionTreeEntry {
  final String id;        // unique, monotonic
  final String parentId;  // '' for root
  final DateTime timestamp;
}
```

## Entities

### AgentMessage (sealed, ported)

Multimodal message union. Content lists hold typed blocks.

| Subtype | Fields | Notes |
|---|---|---|
| `UserMessage` | `content: List<ContentBlock>` | `.text(String)` convenience ctor |
| `AssistantMessage` | `id: String?`, `content: List<Object>` (TextBlock / ToolCallBlock / ThinkingBlock), `stopReason: StopReason?`, `usage: Usage?` | `text` and `toolCalls` getters |
| `ToolResultMessage` | `toolCallId`, `toolName`, `content: List<ContentBlock>`, `isError: bool` | `.text(...)` convenience ctor |
| `CustomMessage` | `type`, `data: Map<String, dynamic>`, `display` | extensibility point — map payload is by design (documented boundary of the no-map-escape rule) |

Content blocks (sealed): `TextBlock(text)`, `ImageBlock(base64Data, mediaType)`,
`ToolCallBlock(id, name, arguments)`, `ThinkingBlock(text)`. Spec 002 adds
`AudioBlock(base64Data, mediaType, transcript?)` and
`DocumentBlock(mediaType, base64Data, title?)` to cover the "audio, document"
modalities in US1 (pi_agent has text + image only).

Support enums: `ThinkingLevel {off, minimal, low, medium, high, xhigh}`,
`StopReason {endTurn, maxTokens, toolUse, stopSequence, refused}`.

### Session tree entries (sealed, ported + new)

| Entry | Fields | Source |
|---|---|---|
| `MessageEntry` | `role: String`, `message: AgentMessage` | ported |
| `ThinkingLevelChangeEntry` | `level: ThinkingLevel` | ported |
| `ModelChangeEntry` | `provider`, `modelId` | ported |
| `CompactionEntry` | `summary: CompactionSummary`, `firstKeptEntryId`, `tokensBefore` | ported, summary now typed (was `String`) |
| `BranchSummaryEntry` | `summary: String` | ported |
| `LabelEntry` | `targetId`, `label: String?` | ported |
| `CustomEntry` | `customType`, `data: Map<String, dynamic>?` | ported (extensibility point) |
| `TurnRecord` | `turnNumber: int`, `messageEntryIds: List<String>`, `stopReason: StopReason?`, `startedAt/endedAt: DateTime`, `durationMs: int` | **new** — wraps the turn's message entry IDs, no content duplication |
| `ToolInvocationRecord` | `toolCallId`, `toolName`, `arguments: Map<String, dynamic>`, `resultEntryId: String?`, `isError: bool`, `durationMs: int`, `artifactRefs: List<ArtifactRef>` | **new** — one per tool execution |
| `UsageLedgerEntry` | `callId: String`, `turnNumber: int`, `model: Model`, `inputTokens`, `outputTokens`, `cacheCreationInputTokens: int?`, `cacheReadInputTokens: int?`, `timestamp` | **new** — per LLM call |

### AgentSession (ported as `Session`, renamed)

Tree-of-entries conversation container over a `SessionStorage`. Owns the
current leaf; all appends extend the active branch.

### SessionInfo / SessionContext (ported)

- `SessionInfo`: `id`, `name`, `createdAt`, `updatedAt`, `metadata`.
- `SessionContext`: `messages`, `thinkingLevel`, `model` — the product of
  `buildContext()` walking leaf → root.

### CompactionSummary (new, typed)

Structured replacement for the placeholder string summary:

```dart
class CompactionSummary {
  final List<String> decisions;      // retained
  final List<String> toolNames;      // retained
  final List<String> keyResults;     // retained
  final String? planState;           // retained
  final List<ArtifactRef> artifacts; // discarded material, resolvable
  final String? prose;               // optional LLM-written narrative
}
```

`ArtifactRef { kind: String, id: String }` — opaque reference resolved through
the `ArtifactResolver` interface (implemented by spec 003's artifact store).
Retained categories map 1:1 to US3 acceptance scenario.

### UsageLedger (new, projection)

Read-side projection over `UsageLedgerEntry` records on a branch:
`totalInputTokens`, `totalOutputTokens`, `byTurn()`, `byModel()` — the shape
MissionBudgetHook (arrrrny/zuraffa#387) consumes.

### Support entities (ported, unchanged shape)

`Skill`, `SkillDiagnostic`, `PromptTemplate`, `ExecutionEnv` /
`LocalExecutionEnv` / `FileInfo` / `ShellResult` / `FileError`, `Model`,
`Usage`, `AgentTool` (real class from tools.dart — not the dynamic typedef),
`AgentToolResult`, `CompactionSettings`, `CompactionPreparation`,
`CompactionResult`.

## Relationships

```text
AgentSession 1 ── * SessionTreeEntry (tree via parentId)
MessageEntry * ── 1 AgentMessage (composition)
TurnRecord   * ── * MessageEntry (by id reference)
ToolInvocationRecord * ── 1 MessageEntry (result, by id reference)
UsageLedgerEntry  * ── 1 TurnRecord (by turnNumber)
CompactionEntry   1 ── * ArtifactRef ── resolved by ArtifactResolver (spec 003)
```

## Validation rules

- `parentId` must reference an existing entry or be `''` (root); appends
  with orphan parents are rejected with `SessionTreeException`.
- Entry `id`s unique per store; ID generator guarantees monotonic ordering.
- `TurnRecord.messageEntryIds` must be non-empty and reference entries on the
  same branch.
- `ToolInvocationRecord.resultEntryId` nullable while a tool is in flight;
  finalized with the result message entry ID.
- `UsageLedgerEntry` token counts non-negative.
- Roles restricted to `user | assistant | toolResult | custom`.
- Store round-trip must preserve entry identity and payload equality
  (cross-store equivalence contract).

## State transitions (session tree)

```text
append(entry)      : leaf' = entry.id           (extends active branch)
fork(atEntryId)    : leaf = atEntryId           (new branch shares ancestry)
switchTo(entryId)  : leaf = entryId             (resume existing branch)
compact()          : + CompactionEntry on active branch; leaf = compaction.id
deleteBranch(leafId): prune upward while childCount == 0 (ancestry retained)
```

Invariants:

- I1: every entry is reachable from exactly one root along `parentId` chains
  (tree, not DAG).
- I2: compaction never mutates existing entries — it appends (append-only
  discipline; sibling branches unaffected by construction).
- I3: `buildContext()` on leaf L returns exactly the ancestry chain of L
  (no sibling leakage).
- I4: resume after restart = reload entries + persisted leaf → identical
  `SessionContext` (leaf persisted with entries, not derived).

## Persistence mapping

One `SessionStorage` interface, three implementations:

| Impl | Format | Target | Notes |
|---|---|---|---|
| `InMemorySessionStorage` | objects | tests / transient | ported |
| `JsonlSessionStorage` | JSON lines | debug / CI | ported + tear reporting (R7) |
| `HiveSessionStorage` | Hive binary (hive_ce) | device | new (R4: hand-written adapters) |

All three pass the same behavioral contract test suite (round-trip
equivalence, fork/resume, tear handling where applicable).
