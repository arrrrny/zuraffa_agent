# Implementation Plan: Memory tools — the agent-facing surface

**Branch**: `feat/spec-074-memory-tools` | **Date**: 2026-08-29

## Summary

One new library bridging AgentMemorySystem (073) to the house tool model
(AgentTool declarations + the ToolDispatcher contract) plus a prompt
projection. No existing files change.

## Phase 1 — Design

### `lib/src/engine/memory_tools.dart` (new)

```dart
class MemoryTools {
  static const rememberTool = AgentTool(id: 'memory_remember', ...);
  static const recallTool   = AgentTool(id: 'memory_recall', ...);
  static const linkTool     = AgentTool(id: 'memory_link', ...);
  static List<AgentTool> get declarations; // unmodifiable
}

class MemoryToolDispatcher implements ToolDispatcher {
  AgentMemorySystem memory;
  int _counter = 0; // auto ids: mem-1, mem-2, ...

  Future<ToolDispatchResult> dispatch({toolName, arguments, isInternalMission});
  Future<List<ToolDispatchResult>> dispatchBatch({calls, isInternalMission});
  List<String> validateSchema({schema, arguments});
  bool checkRiskTier({riskTier, isInternalMission}) => true; // all safe-tier
}

class MemoryPromptProjection {
  AgentMemorySystem memory;
  List<String> render({int limit = 10});               // top long-term by salience
  List<String> renderWithSession(String s, {int limit = 10}); // + [session] notes
}
```

Decisions:

- **Failure results, not exceptions**: model-generated arguments are
  untrusted input; `dispatch` catches ArgumentError from the memory
  system (e.g. link endpoint validation) and converts to
  `success: false` results with the message. Programmer errors (null
  toolName) can still throw.
- **Argument coercion**: JSON-shaped args arrive as `Map<String,
  dynamic>` — strings checked with `is String`, salience accepted as
  `num` (int or double), tags as `List` of strings.
- **Auto-id**: dispatcher-local counter (`mem-1`, `mem-2`, …);
  explicit `id` argument wins. Counter is per-dispatcher state, not
  global — two dispatchers over one memory system produce distinct ids
  only by caller discipline (documented; explicit ids are the contract
  for cross-referencing).
- **Recall formatting**: `"<layer> | <id> | salience <s> | <content>"`
  — machine-greppable, human-readable in the transcript.
- **Projection ordering**: sort long-term by (salience desc, createdAt
  desc) — the same ranking recall uses; session notes keep insertion
  order (recency of note-taking, not salience).

### Test file `test/engine/memory_tools_test.dart` (new)

Groups: declarations / remember dispatch / recall dispatch / link
dispatch / failures + batch + schema / prompt projection / end-to-end
story.

## Phase 2 — TDD

1. RED: test file first — missing-library compile failure.
2. GREEN: implement until green.
3. Deliberate mutants (cp-restored): M1 remember dispatch skips the
   write (success result but no store entry) — killed by store-count
   assertion; M2 recall limit ignored — killed by limit test; M3 link
   type hardcoded relatesTo — killed by type assertion; M4 projection
   in insertion order — killed by salience-order test; M5 session_id
   argument ignored (always long-term) — killed by session-store
   assertion.
4. Gates + `tdd/verification.md`; commit; push; PR (base
   `feat/spec-073-agent-memory` — stacked on #84).
