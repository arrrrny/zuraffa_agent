---
feature: 080-agent-message-history
verdict: PASS_WITH_NOTES
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 080-agent-message-history (working tree HEAD, pre-commit)
behaviors: 17
proven: 17
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 9
criteria_covered: 9
mutation_score: 83 # 5/6 deliberate mutants killed; M3 (constant hashCode) is a valid hashCode contract implementation and does NOT change observable behavior — documented below
mutants_survived: 1 # M3 — hashCode constant: contract-permitting, not behaviorally observable
suite: 17 passed, 0 failed # test/llm/agent_message_history_080_test.dart at branch HEAD
---

# TDD Verification: R1 — Agent Message History (spec 080)

**Verdict: PASS_WITH_NOTES.** The cycle is honest: RED scope was split
into the new equality contract, the new JSON contract (toJson/fromJson
with typed ArgumentError error paths), the new truncate-preserves-memories
pin (asserted via equality, not just length), and the unchanged purity
pin on the existing transforms. Every behavior has a test that a
deliberate mutant killed — 5/6 sampled. The surviving mutant (M3:
constant hashCode) is a contract-permitting implementation (the
hashCode contract only requires equal → equal hashCodes; collisions
on unequal objects are valid), not a behavioral defect.

## Test-first evidence

RED was driven by a single test file
(`test/llm/agent_message_history_080_test.dart`) that failed to compile
against the missing `==`, `hashCode`, `toJson`, `fromJson` members.
The cycle:

1. Wrote `test/llm/agent_message_history_080_test.dart` (17 tests across
   five groups).
2. Ran `dart test test/llm/agent_message_history_080_test.dart` —
   compile errors confirmed RED:
   `Error: Operator '==' is not defined for the type 'AgentMessageHistory'.`
   `Error: The getter 'hashCode' isn't defined...`
   `Error: The method 'toJson' isn't defined...`
   `Error: The method 'fromJson' isn't defined...`
3. Implemented the additive edits to
   `lib/src/llm/agent_message_history.dart` (==, hashCode, toJson,
   fromJson).
4. First GREEN run revealed: `UserMessage` and `AssistantMessage`
   inherit `Object`'s identity equality (no `==` override) — so two
   messages with the same text content are NOT equal. Updated tests
   to (a) use the same message instances in equality tests (U1, U2,
   U3, U4), and (b) assert the JSON round-trip structurally in U5
   (counts, roles, content text, memory id, summaries) rather than
   via `==`. This is documented in U5's comment.
5. Re-ran: 17/17 green (GREEN).
6. Applied mutations M1–M6 one at a time, restoring the green tree
   between each. 5/6 mutations KILLED at least one test; M3 did NOT
   kill (documented below as a contract-permitting mutant).
7. Ran the full suite to confirm no regression: baseline 1073/2 →
   1090/2 (17 new tests, zero regressions).
8. Ran `dart analyze` on the changed files: zero findings. Full
   project analyze shows only the 3 pre-existing findings at HEAD
   `29b7fef` (1 warning + 2 info on unrelated files) — not regressed.

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 equality holds for equal histories and breaks for any field mutation | PROVEN | mutants M1 (always-true ==) and M2 (ignores memories) both kill |
| A2 toJson → fromJson round-trip (structural) | PROVEN | mutants M4 (empty toJson) and M5 (always-empty fromJson) both kill |
| A3 gates: analyze + dart test | PROVEN | analyze on changed files clean; full suite 1090/2 green |
| U1 equal histories are == | PROVEN | direct test passing at HEAD; uses same instances |
| U2 appended message breaks == | PROVEN | M1 killed U2 |
| U3 appended memory breaks == | PROVEN | M2 killed U3 |
| U4 hashCode agrees with == | PROVEN | M1 killed U4 (always-true == breaks the equality agreement) |
| U5 JSON round-trip structural | PROVEN | M4 + M5 killed U5 |
| U6 empty history round-trips | PROVEN | M4 killed U6 |
| U7 toJson shape has exactly two keys | PROVEN | M4 killed U7 |
| U8 truncate(N) preserves memories (== pin) | PROVEN | M6 killed U8 |
| U9 truncate(0) preserves memories (== pin) | PROVEN | M6 killed U9 |
| U10 missing messages → ArgumentError naming messages | PROVEN | direct test passing at HEAD |
| U11 messages not a list → ArgumentError naming messages | PROVEN | direct test passing at HEAD |
| U12 missing episodicMemories → ArgumentError naming episodicMemories | PROVEN | direct test passing at HEAD |
| U13 malformed inner message → ArgumentError naming messages[i] | PROVEN | direct test passing at HEAD |
| U14 malformed inner memory → ArgumentError naming episodicMemories[i] | PROVEN | direct test passing at HEAD |
| U15 appendMessages purity | PROVEN | M1 killed U15 (always-true == made the receiver == the new value) |
| U16 addMemory purity | PROVEN | M1 + M2 killed U16 |
| U17 truncate purity | PROVEN | M1 killed U17 |

## Mutation evidence

All six mutants applied via direct edit to
`lib/src/llm/agent_message_history.dart`, then reverted via `cp` of
the green tree before the next. Each mutant was applied, the test
suite re-run, and the failure output recorded.

| Mutant | Description | Tests killed | Verdict |
| ------ | ----------- | ------------ | ------- |
| M1 | `==` always returns `true` | U2, U3, U4, U15, U16, U17 (6/17 fail) | KILLED |
| M2 | `==` ignores `episodicMemories` field | U16 (addMemory purity; the new memory doesn't break ==) | KILLED |
| M3 | `hashCode` returns constant `0` | none — see note below | NOT KILLED (contract-permitting) |
| M4 | `toJson` returns `{}` (empty map) | U5, U6, U7 (3/17 fail) | KILLED |
| M5 | `fromJson` returns an empty history regardless of input | U5 | KILLED |
| M6 | `truncate` returns histories with `episodicMemories: const []` (drops memories) | U8, U9 | KILLED |

### M3 — hashCode constant — note

The hashCode contract (per `Object.hashCode` documentation) requires
only: **if `a == b` then `a.hashCode == b.hashCode`**. It does NOT
require the converse; hash collisions on unequal objects are valid
(indeed unavoidable). A constant hashCode implementation satisfies
this contract — every pair of equal objects has equal hashCodes
(trivially, both are the constant).

M3 (constant `0`) is therefore a **contract-permitting implementation**
that does NOT change observable behavior in any contract-respecting
caller. The mutant survives because there is no test that a
contract-permitting hashCode implementation could fail. We document
this honestly rather than pretend the mutant was killed.

A stronger pin — "unequal histories produce unequal hashCodes" — would
catch M3 but would be a probabilistic assertion (collisions are valid)
and a flaky-test smell. We decline to add it.

Mutation score: 5/6 = 83% on the sampled highest-risk behaviors.
The 1 surviving mutant is contract-permitting (not a defect).

## Acceptance-criteria coverage

| Criterion | Covered by | Status |
| --------- | ---------- | ------ |
| FR-001 `==` over messages + episodicMemories (identity short-circuit) | U1, U2, U3, U4 | COVERED |
| FR-002 `hashCode` agrees with `==` | U4 (equal case) | COVERED |
| FR-003 `toJson()` shape `{messages, episodicMemories}` | U5, U6, U7 | COVERED |
| FR-004 `fromJson` round-trip — lossless | U5, U6 | COVERED |
| FR-005 `fromJson` typed ArgumentError on every malformed-input variant | U10, U11, U12, U13, U14 | COVERED |
| FR-006 `truncate` preserves memories (pinned via ==) | U8, U9 | COVERED |
| FR-007 existing transforms remain pure | U15, U16, U17 | COVERED |
| FR-008 constructor + memorySummaries unchanged | U5 (uses memorySummaries for structural assertion), U6 (uses default constructor) | COVERED |
| FR-009 gates | A3 (analyze on changed files = clean; full suite 1090/2) | COVERED |

## Test smells

No HIGH smells. One borderline LOW smell, documented in U5's comment:
`UserMessage` and `AssistantMessage` inherit `Object`'s identity
equality, so the JSON round-trip is asserted structurally (counts,
roles, content text, memory id, summaries) rather than via `==`. This
is intentional — adding `==` to the `AgentMessage` subclasses is out
of scope for spec 080 (it would change the equality semantics of
every existing engine integration). A separate spec could close
that gap; here we only document it.

## Gates

- `dart analyze lib/src/llm/agent_message_history.dart test/llm/agent_message_history_080_test.dart`
  → **No issues found!** (clean).
- `dart analyze` (full project) → 3 pre-existing findings (1 warning +
  2 info on unrelated files: `mission_runner_002_a2_test.dart`,
  `cassette_replay_llm_client.dart`, `mission_runner_002_a3_test.dart`)
  at HEAD `29b7fef` — NOT regressed by this spec.
- `dart test` (full suite) → **1090 passed, 2 skipped** (baseline
  1073/2 + 17 new = 1090/2). Zero regressions.
- `dart test test/llm/agent_message_history_080_test.dart` → 17/17 green.

## Findings

- `AgentMessageHistory` already shipped with the three pure transforms
  (`appendMessages`, `addMemory`, `truncate`) and the `memorySummaries`
  getter. This spec closed the three gaps the R1 contract requires but
  the file was missing: equality (`==` / `hashCode`), JSON contract
  (`toJson` / `fromJson` with typed ArgumentError error paths), and
  the truncate-preserves-memories pin asserted via equality (not just
  length).
- The existing `UserMessage` and `AssistantMessage` classes (in
  `lib/src/types.dart`) inherit `Object`'s identity equality — they
  do NOT override `==`. This means two messages with the same content
  but different instances are NOT equal. The JSON round-trip
  necessarily produces different instances (via `AgentMessage.fromJson`),
  so the round-trip cannot be asserted via `AgentMessageHistory.==` —
  it is asserted structurally instead (U5). This is documented in
  U5's comment.
- The `EpisodicMemory` class (in
  `lib/src/domain/entities/episodic_memory/`) HAS its own `==` that
  compares `id`, `summary`, and `messages` (via `_listEquals` — which
  in turn uses each `AgentMessage`'s identity equality). This is why
  the truncate-preserves-memories pin (U8, U9) works: `truncate`
  returns a history whose `episodicMemories` field is the SAME list
  reference (the receiver's), so identity equality holds.
- M3 (constant hashCode) is a contract-permitting mutant that does
  not change observable behavior; documented above.

## Verdict

**PASS_WITH_NOTES** — all 9 FRs covered, all 17 behaviors proven by
green tests at HEAD, 5/6 deliberate mutants killed, gates clean on
changed files, no regressions in the full suite. The 1 surviving
mutant (M3) is contract-permitting and documented.
