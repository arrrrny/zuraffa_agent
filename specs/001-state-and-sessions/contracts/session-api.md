# Contract: Session Tree API (`zuraffa_agent`)

**Feature**: `002-state-and-sessions`

Public Dart API for the branching session tree. All names are exported from
`package:zuraffa_agent/zuraffa_agent.dart`. Ported surface keeps pi_agent
signatures; `Session` is renamed `AgentSession`; new members are marked NEW.

## AgentSession

```dart
class AgentSession {
  AgentSession(SessionStorage storage);

  // Appends — extend the active branch (ported signatures)
  Future<String> appendMessage(AgentMessage message);
  Future<String> appendThinkingLevelChange(ThinkingLevel level);
  Future<String> appendModelChange(String provider, String modelId);
  Future<String> appendLabel(String targetId, {String? label});
  Future<String> appendCustomEntry(String customType, {Map<String, dynamic>? data});
  Future<String?> moveTo(String? entryId, {String? summary}); // fork/switch/resume

  // NEW granular-entity appends (US1)
  Future<String> appendTurn(TurnRecord turn);
  Future<String> appendToolInvocation(ToolInvocationRecord invocation);
  Future<String> appendUsage(UsageLedgerEntry usage);
  Future<String> appendCompaction(CompactionEntry entry); // typed summary overload

  // Reads
  Future<SessionContext> buildContext();                 // leaf→root walk
  Future<List<SessionTreeEntry>> getBranch({String? fromId});
  Future<List<SessionTreeEntry>> getEntries();
  Future<SessionTreeEntry?> getEntry(String id);
  Future<SessionInfo> getMetadata();

  // NEW branch management (US2)
  Future<String> fork(String atEntryId, {String? summary}); // returns new leaf id
  Future<void> switchTo(String entryId);
  Future<List<String>> listBranchHeads();                   // leaves with >1 child or named
  Future<int> deleteBranch(String leafId);                  // prunes leaf-only ancestry, returns pruned count
}
```

**Behavioral guarantees** (tested against every `SessionStorage` impl):

1. `fork(at)` then appends diverge from `at`'s first child position; ancestry
   up to and including `at` is shared and immutable.
2. `buildContext()` returns exactly the active branch's conversation — no
   sibling entries (invariant I3).
3. Reopen after process restart: context identical to pre-restart (I4).
4. `deleteBranch` never removes an entry that still has children (ancestry
   retention edge case).
5. Compaction appends one `CompactionEntry` on the active branch only.

## Session storage interface

```dart
abstract class SessionStorage {
  Future<StoreOpenResult> init();          // NEW: returns tear report (was `void`)
  Future<void> appendEntry(SessionTreeEntry entry);
  Future<List<SessionTreeEntry>> loadEntries();
  Future<SessionTreeEntry?> findEntry(String id);
  Future<void> setLeafId(String? leafId);
  Future<String?> getLeafId();
  Future<void> setMetadata(SessionInfo info);
  Future<SessionInfo> getMetadata();
  Future<void> close();
}

class StoreOpenResult {          // NEW
  final List<JsonlTear> tears;   // empty when clean
}

class JsonlTear {                // NEW — corrupt-tail edge case
  final int lineNumber;
  final String reason;
  final int salvagedEntryCount;
}
```

Implementations: `InMemorySessionStorage`, `JsonlSessionStorage(String path)`,
`HiveSessionStorage(String boxName, {String? hivePath})`.

JSONL on-disk format (one object per line; first line `_header` metadata —
ported, extended for new entry types):

```json
{"_header": true, "id": "...", "name": "...", "createdAt": "...", "leafId": "..."}
{"id":"...","parentId":"","timestamp":"...","type":"message","role":"assistant","message":{...}}
{"id":"...","parentId":"...","timestamp":"...","type":"turn","turnNumber":3,"messageEntryIds":["..."],"stopReason":"toolUse","durationMs":812}
{"id":"...","parentId":"...","timestamp":"...","type":"toolInvocation","toolCallId":"...","toolName":"bash","arguments":{...},"isError":false,"durationMs":240,"artifactRefs":[...]}
{"id":"...","parentId":"...","timestamp":"...","type":"usage","callId":"...","turnNumber":3,"model":{...},"inputTokens":801,"outputTokens":311}
{"id":"...","parentId":"...","timestamp":"...","type":"compaction","summary":{...},"firstKeptEntryId":"...","tokensBefore":48000}
```

Load semantics: parse lines in order; on the first undecodable line stop and
report a `JsonlTear` with the salvaged prefix (research R7).
