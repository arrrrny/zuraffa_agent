**Template Version**: `zuraffa-1.0`

# Feature Specification: Memory tools — the agent-facing surface

**Branch**: `feat/spec-074-memory-tools` (stacked on `feat/spec-073-agent-memory`, PR #84) | **Date**: 2026-08-29

## Summary

Spec 073 built the three-layer memory system as a Dart API. An agent
cannot call a Dart API — it calls TOOLS. This spec gives the memory
system its agent-facing surface:

- **`MemoryTools.declarations`** — three `AgentTool` declarations
  (`memory_remember`, `memory_recall`, `memory_link`) following the
  house tool model (R3.1/R3.2): typed params schemas, `RiskTier.safe`
  (memory writes are not destructive — the layers are append-oriented
  value stores), `ExecutionMode.sequential`.
- **`MemoryToolDispatcher`** — implements the `ToolDispatcher` contract
  (the same interface the sub-agent dispatch runtime consumes): bridges
  tool calls to the `AgentMemorySystem`. Model-shaped failures (empty
  content, unknown link type, unknown endpoints, unknown tool) come
  back as `ToolDispatchResult(success: false, error: ...)` — the LLM
  sees the reason and can correct itself — instead of exceptions, which
  are for programmer errors.
- **`MemoryPromptProjection`** — renders the system-prompt digest of
  what the agent remembers: top long-term memories by salience
  (optionally plus the current session's notes), as prompt-ready lines.

The dispatcher can serve as the inner dispatcher of an allowlist
dispatcher (spec 070's composition) — memory tools compose with the
sub-agent and swarm stacks.

## Files

- `lib/src/engine/memory_tools.dart` — NEW: `MemoryTools`,
  `MemoryToolDispatcher`, `MemoryPromptProjection`.
- `test/engine/memory_tools_test.dart` — NEW.
- `specs/074-memory-tools/{spec,plan,tasks}.md` +
  `tdd/{test-list,verification}.md`.

## FRs

- **FR-001**: The system MUST satisfy this requirement: Declarations: `memory_remember` (params: `content`
  required string, `tags` optional string array, `salience` optional
  number, `session_id` optional string), `memory_recall` (`query`
  required string, `limit` optional number), `memory_link` (`from_id`,
  `to_id`, `type` required; `note` optional). Each is an `AgentTool`
  with `RiskTier.safe`, `ExecutionMode.sequential`, a `paramsSchema`
  declaring `required` arrays, and a description that tells the model
  WHEN to use it. `MemoryTools.declarations` returns all three
  (unmodifiable).
  traces: MemoryTools.fr1

- **FR-002**: The system MUST satisfy this requirement: `memory_remember` dispatch: builds a `MemoryRecord`
  (auto id `mem-<n>` from a per-dispatcher counter when `id` is not
  supplied — explicit `id` also accepted), `MemorySource(sessionId:
  session_id or agentName: 'memory-tool')`, salience clamped to
  0.0..1.0, default 0.5, and writes through `AgentMemorySystem.remember`
  (long-term when no `session_id`, session memory otherwise). Success
  result carries the stored id.
  traces: MemoryTools.fr2

- **FR-003**: The system MUST satisfy this requirement: Model-shaped failures return `ToolDispatchResult(success:
  false, result: '', error: <reason>, artifactRefs: [])`: missing or
  non-string `content`, whitespace-only content, out-of-range salience,
  unknown tool name. NO exception escapes `dispatch` for argument-shaped
  problems — the agent gets the error text and can retry.
  traces: MemoryTools.fr3

- **FR-004**: The system MUST satisfy this requirement: `memory_recall` dispatch: returns success with one line
  per hit, `"<layer> | <id> | salience <s> | <content>"`, in the
  system's ranking order, capped by `limit`. Empty/missing query is a
  failure result (not a match-all).
  traces: MemoryTools.fr4

- **FR-005**: The system MUST satisfy this requirement: `memory_link` dispatch: validates `type` against
  `MemoryLinkType` names (unknown → failure result), then delegates to
  `AgentMemorySystem.link`. Endpoint validation comes from the system
  (unknown ids → failure result carrying the ArgumentError message);
  self-links likewise. Happy path returns success naming the link.
  traces: MemoryTools.fr5

- **FR-006**: The system MUST satisfy this requirement: `dispatchBatch` dispatches every call sequentially and
  returns one result per call, in order.
  traces: MemoryTools.fr6

- **FR-007**: The system MUST satisfy this requirement: `validateSchema` checks the required keys per tool
  (`content` for remember, `query` for recall, `from_id`/`to_id`/`type`
  for link) and returns the violation strings (empty list = valid);
  `checkRiskTier` is always true (all memory tools are safe-tier).
  traces: MemoryTools.fr7

- **FR-008**: The system MUST satisfy this requirement: `MemoryPromptProjection.render({int limit = 10})`: the
  top [limit] long-term memories by salience (desc, createdAt desc) as
  prompt lines `"- [id] content"`, highest salience first.
  `renderWithSession(sessionId, {int limit = 10})` prepends the
  session's notes (insertion order, capped by limit) marked
  `"[session] "`. Empty memory renders an empty list — the caller
  omits the section entirely.
  traces: MemoryTools.fr8

- **FR-009**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test`
  green (baseline 925/2 at `4dd76e2` + new tests).
  traces: MemoryTools.fr9

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Wiring the tools into a live tool registry / LLM turn (the
  MissionRunner stack, PRs #80-#83, owns that when it merges).
- Memory-formation policy (when the agent SHOULD remember — a distiller
  concern).
- Embedding-based recall (keyword + salience only, per 073).
- Any new `EngineEvent` subtype (the union grows only from its own
  spec).

## Acceptance Scenarios

> Derived verbatim from the feature's pinned regression suite.
> Behaviors are inherited-green: the cited tests pass unmodified in
> the repo suite (dart test, 1201 passing).
1. **Given** the feature implementation under its clean-architecture seams **When** declarations are safe-tier typed tools **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
2. **Given** the feature implementation under its clean-architecture seams **When** remember generates ids and flows arguments **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
3. **Given** the feature implementation under its clean-architecture seams **When** remember routes by session_id argument **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
4. **Given** the feature implementation under its clean-architecture seams **When** recall renders ranked layer-attributed lines **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
5. **Given** the feature implementation under its clean-architecture seams **When** link validates and delegates to the system **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
6. **Given** the feature implementation under its clean-architecture seams **When** model-shaped failures come back as failure results **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
7. **Given** the feature implementation under its clean-architecture seams **When** dispatchBatch maps every call in order **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
8. **Given** the feature implementation under its clean-architecture seams **When** schema validation and risk tier **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
9. **Given** the feature implementation under its clean-architecture seams **When** projection ranks by salience and marks session notes **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
10. **Given** the feature implementation under its clean-architecture seams **When** agent story: remember, link, recall, project **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
11. **Given** the feature implementation under its clean-architecture seams **When** an auto id never overwrites a memory stored under that id **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
12. **Given** the feature implementation under its clean-architecture seams **When** a NaN salience is rejected as out of range **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
13. **Given** the feature implementation under its clean-architecture seams **When** validateSchema rejects an explicit null for a required argument **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance
14. **Given** the feature implementation under its clean-architecture seams **When** renderWithSession applies limit per layer **Then** the pinned regression test passes (`test/engine/memory_tools_test.dart`).
   **Type**: acceptance

## Layer Contracts

**Domain**:

- `MemoryTools`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`, `fr7(...) -> Result`, `fr8(...) -> Result`, `fr9(...) -> Result`

