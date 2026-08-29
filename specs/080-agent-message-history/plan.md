# Implementation Plan: R1 — Agent Message History (spec 080)

## Approach

Four additive members on `AgentMessageHistory` (`==`, `hashCode`,
`toJson`, `fromJson`) driven by a failing test file, then a small set
of mutations to prove the pins hold. The file already compiles and
is exercised by spec-010 and spec-041's test files; this plan grows
the value object's surface without changing its existing transforms.

## Components

### 1. `AgentMessageHistory.==` (FR-001)

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is AgentMessageHistory &&
      runtimeType == other.runtimeType &&
      _listEquals(messages, other.messages) &&
      _listEquals(episodicMemories, other.episodicMemories);
}

// Local helper (the engine has no shared list-equals utility in
// types.dart; EpisodicMemory.dart already has its own _listEquals —
// we duplicate the small helper here rather than import a private
// symbol from another module).
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

Element-wise equality delegates to each `AgentMessage` subclass's
existing `==` (sealed class, every concrete subclass has its own
`operator ==` and `hashCode`) and `EpisodicMemory.==`. Identity
short-circuits.

### 2. `AgentMessageHistory.hashCode` (FR-002)

```dart
@override
int get hashCode => Object.hash(
  Object.hashAll(messages),
  Object.hashAll(episodicMemories),
);
```

`Object.hashAll` is order-sensitive (matches the list's structural
equality — element-wise from index 0). `Object.hash` combines the
two list hashes into one int.

### 3. `AgentMessageHistory.toJson()` (FR-003)

```dart
Map<String, dynamic> toJson() => <String, dynamic>{
  'messages': [for (final m in messages) m.toJson()],
  'episodicMemories': [for (final em in episodicMemories) em.toJson()],
};
```

Same shape as `EpisodicMemory.toJson` (which already produces
`{id, summary, messages: [...]}`). The two top-level keys are
`messages` and `episodicMemories`; no other keys. An empty history
produces `{messages: [], episodicMemories: []}`.

### 4. `AgentMessageHistory.fromJson(...)` factory (FR-004 / FR-005)

```dart
factory AgentMessageHistory.fromJson(Map<String, dynamic> json) {
  List<dynamic> requireList(String key) {
    final value = json[key];
    if (value is! List) {
      throw ArgumentError.value(value, key,
          'AgentMessageHistory.$key must be a list');
    }
    return value;
  }

  final rawMessages = requireList('messages');
  final rawMemories = requireList('episodicMemories');

  final messages = <AgentMessage>[];
  for (var i = 0; i < rawMessages.length; i++) {
    final raw = rawMessages[i];
    if (raw is! Map<String, dynamic>) {
      throw ArgumentError.value(raw, 'messages[$i]',
        'must be a Map<String, dynamic>');
    }
    try {
      messages.add(AgentMessage.fromJson(raw));
    } catch (e) {
      throw ArgumentError.value(raw, 'messages[$i]',
        'AgentMessage.fromJson failed: $e');
    }
  }

  final memories = <EpisodicMemory>[];
  for (var i = 0; i < rawMemories.length; i++) {
    final raw = rawMemories[i];
    if (raw is! Map<String, dynamic>) {
      throw ArgumentError.value(raw, 'episodicMemories[$i]',
        'must be a Map<String, dynamic>');
    }
    try {
      memories.add(EpisodicMemory.fromJson(raw));
    } catch (e) {
      throw ArgumentError.value(raw, 'episodicMemories[$i]',
        'EpisodicMemory.fromJson failed: $e');
    }
  }

  return AgentMessageHistory(messages: messages, episodicMemories: memories);
}
```

Parity with `EpisodicMemory.fromJson` and `SteeringMessage.fromJson`:
typed `ArgumentError.value` with the offending value, name, and
message. Inner-delegate errors (e.g. `AgentMessage.fromJson` throwing
`FormatException` on an unknown role) are wrapped in `ArgumentError`
at this layer, naming the index of the offending element.

### 5. Tests (`test/llm/agent_message_history_080_test.dart`)

Lives in its own file so spec-010's and spec-041's test files stay
byte-identical (their cycles' records depend on it).

Four groups, mirroring the four user stories:

**Group A — equality (US1 / FR-001 / FR-002)**:
- T1: two histories built from equal-but-distinct message + memory lists compare equal via `==`.
- T2: mutating one list (appending a message) breaks equality.
- T3: mutating one list (appending a memory) breaks equality.
- T4: `hashCode` agrees with `==` for both equal and unequal cases.

**Group B — JSON round-trip (US2 / FR-003 / FR-004)**:
- T5: a history with two messages + one memory round-trips through `toJson` → `fromJson` to an equal history.
- T6: an empty history round-trips (both lists empty; no throw).
- T7: `toJson` shape — exactly the two keys `messages` and `episodicMemories`; no extras.

**Group C — truncate preserves memories (US3 / FR-006)**:
- T8: `truncate(N).episodicMemories == receiver.episodicMemories` (the pin — equality, not just length).
- T9: `truncate(0).episodicMemories == receiver.episodicMemories` (memories untouched when active window is fully evicted).

**Group D — error paths (US4 / FR-005)**:
- T10: missing `messages` → `ArgumentError` naming `messages`.
- T11: `messages` not a list → `ArgumentError` naming `messages`.
- T12: missing `episodicMemories` → `ArgumentError` naming `episodicMemories`.
- T13: malformed inner message (not a Map) → `ArgumentError` naming `messages[0]`.
- T14: malformed inner memory (EpisodicMemory.fromJson fails) → `ArgumentError` naming `episodicMemories[0]`.

**Group E — purity pin (FR-007)**:
- T15: `appendMessages` returns a new value; the receiver's `messages.length` is unchanged.
- T16: `addMemory` returns a new value; the receiver's `episodicMemories.length` is unchanged.
- T17: `truncate` returns a new value; the receiver's `messages.length` is unchanged.

### 6. Mutations (M1–M6, one at a time, cp-restored)

- **M1**: `==` always returns `true` (guards T1–T4).
- **M2**: `==` ignores `episodicMemories` (guards T3 — a memory-only mutation would not break equality).
- **M3**: `hashCode` returns a constant (guards T4 — `hashCode` would not agree with `==`).
- **M4**: `toJson` returns `{}` (guards T5 — round-trip would yield an empty history; equality fails).
- **M5**: `fromJson` returns an empty history regardless of input (guards T5 — round-trip yields empty).
- **M6**: `truncate` drops `episodicMemories` (returns `AgentMessageHistory(messages: ..., episodicMemories: const [])`) (guards T8 — equality fails).

## Sequencing

1. RED — write `test/llm/agent_message_history_080_test.dart` (17 tests
   across five groups) against the missing `==`, `hashCode`, `toJson`,
   `fromJson` members. Compile failure: `Operator '==' is not defined`,
   `Getter 'hashCode' is not defined`, `Method 'toJson' is not defined`,
   `Method 'fromJson' is not defined`.
2. GREEN — land the four new members on `AgentMessageHistory`;
   tests 17/17 green.
3. MUTATIONS — M1–M6, one at a time, `cp`-restored between runs.
   Each must KILL (i.e. at least one test fails when the mutant is
   applied; the test passes again when the mutant is retracted).
4. GATES — `dart analyze --fatal-infos` exit 0 on the changed files;
   full `dart test` green (baseline 1089/2 + 17 new = 1106/2).
5. ARTIFACTS — `tdd/verification.md` records the cycle integrity,
   mutation evidence verbatim, the FR table, and the verdict.
6. COMMIT (spec.md + plan.md + tasks.md + tdd/test-list.md +
   tdd/verification.md + agent_message_history.dart + the new test
   file) and open PR with base `master` titled `feat(080): agent
   message history — context assembly & pure transforms` closing #91.
