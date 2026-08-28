# Implementation Plan: Agent memory — three layers

**Branch**: `feat/spec-073-agent-memory` | **Date**: 2026-08-29

## Summary

One new library file with three stores + a facade; one new test file.
No existing files change.

## Phase 1 — Design

### `lib/src/engine/agent_memory.dart` (new)

```dart
// Value objects (house pattern: ==, hashCode, toString; no codegen)
class MemorySource { final String? sessionId, missionId, agentName; /* >= 1 set */ }
class MemoryRecord { final String id, content; final Set<String> tags;
                     final MemorySource source; final DateTime createdAt;
                     final double salience; /* 0..1, default .5 */ }
enum MemoryLinkType { supports, contradicts, supersedes, derivedFrom, relatesTo }
class MemoryLink { final String fromRecordId, toRecordId; final MemoryLinkType type;
                   final DateTime createdAt; final String? note; }
enum MemoryLayer { longTerm, session }
class RecallHit { final MemoryRecord record; final MemoryLayer layer; }

// Layer 1 — durable, cross-session
class LongTermMemoryStore {
  void remember(MemoryRecord r);        // same-id replaces in place
  MemoryRecord? byId(String id);
  List<MemoryRecord> search(String q);  // substring, salience desc, createdAt desc
  List<MemoryRecord> byTag(String tag); // exact match
  List<MemoryRecord> latest(int n);     // createdAt desc
  List<MemoryRecord> get all;           // insertion order, unmodifiable
  bool contains(String id);
}

// Layer 2 — session-scoped, evaporates with the session
class SessionMemoryStore {
  void remember(String sessionId, MemoryRecord r);
  List<MemoryRecord> forSession(String sessionId);  // insertion order
  void forgetSession(String sessionId);
  MemoryRecord? byId(String id);        // searches all sessions
  bool contains(String id);
  bool remove(String id);               // used by promote; true if removed
}

// Layer 3 — the cross-reference graph
class MemoryGraph {
  void link(String fromId, String toId, MemoryLinkType type, {String? note});
      // ArgumentError: self-link, unknown endpoint, (same from/to/type → replace, NOT error)
  List<MemoryLink> neighborsOf(String recordId);  // either endpoint
  List<MemoryLink> get links;                     // unmodifiable
  List<MemoryLink> linksOf(MemoryLinkType type);
  List<MemoryLink> contradictions();
}

// Facade
class AgentMemorySystem {
  AgentMemorySystem({LongTermMemoryStore? longTerm, SessionMemoryStore? sessions,
                     MemoryGraph? graph});
  MemoryRecord remember(MemoryRecord r, {String? sessionId});
  List<RecallHit> recall(String query, {int? limit});
  void link(String fromId, String toId, MemoryLinkType type, {String? note});
  List<(MemoryLink, MemoryRecord?, MemoryLayer?)> linked(String recordId);
  MemoryRecord promote(String recordId);
  LongTermMemoryStore get longTermMemory;
  SessionMemoryStore get sessionMemory;
  MemoryGraph get graph;
}
```

Notes:

- Record-id validation in the graph needs to see both stores — so
  `MemoryGraph.link` takes a `bool Function(String id) exists` callback
  (injected at AgentMemorySystem construction) OR the facade does the
  validation before delegating. Decision: **facade validates** (graph
  stays a pure structure; the graph's own `link` rejects only
  self-links and duplicates — documented; standalone-graph-with-unknown-ids
  is a legitimate intermediate state the facade never creates).
- `recall` ranking: `(salience, createdAt)` both desc — stable
  interleave of both layers. `RecallHit` carries the layer for
  attribution.
- `promote` moves the record (remove from session store, add to
  long-term) with id/content/createdAt preserved. Links reference ids
  only — they survive untouched.
- `linked` resolves neighbors lazily; a neighbor whose record was
  forgotten resolves to null record/layer (dangling link is honest).

### Test file `test/engine/agent_memory_test.dart` (new)

Groups: value objects / long-term store / session store / graph /
facade recall / facade promote / integration story
(remember→link→recall→promote→linked round-trip).

## Phase 2 — TDD

1. RED: test file first — missing-library compile failure.
2. GREEN: implement until green.
3. Deliberate mutants (cp-restored): M1 salience ranking dropped
   (insertion order instead) — killed by recall-order test; M2 recall
   searches long-term only — killed by interleaved-hit test; M3 promote
   copies but forgets to remove from session store — killed by
   forSession-empty assertion; M4 graph neighborsOf outgoing only —
   killed by incoming-link test; M5 duplicate-link idempotence removed
   (throws instead) — killed by re-link test. (Exact set may adapt to
   what the tests genuinely pin; evidence recorded either way.)
4. Gates + `tdd/verification.md`; commit; push; PR (base master).
