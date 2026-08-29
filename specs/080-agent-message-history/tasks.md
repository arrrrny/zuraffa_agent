# Tasks: R1 — Agent Message History (spec 080)

- [x] 1. RED — wrote `test/llm/agent_message_history_080_test.dart`
       (17 tests across five groups: equality, JSON round-trip,
       truncate-preserves-memories pin, fromJson error paths, purity
       pin). Initial run failed to compile against the missing `==`,
       `hashCode`, `toJson`, `fromJson` members — RED evidence
       captured in `tdd/verification.md`.
- [x] 2. GREEN — additive edits to `lib/src/llm/agent_message_history.dart`:
       (a) added `AgentMessageHistory.==` (full-field equality over
       `messages` and `episodicMemories`; identity short-circuit);
       (b) added `AgentMessageHistory.hashCode` (`Object.hash` of
       `Object.hashAll` over each list — agrees with `==` for the
       contractually-required equal case);
       (c) added `AgentMessageHistory.toJson()` (`{messages: [...],
       episodicMemories: [...]}` shape);
       (d) added `AgentMessageHistory.fromJson(...)` factory with typed
       `ArgumentError.value` for every malformed-input variant
       (missing/wrong-type top-level keys, malformed inner
       message/memory wrapped in `ArgumentError` naming the index);
       (e) added a private `_listEquals<T>` helper (same shape as
       `EpisodicMemory`'s local helper — duplicated rather than
       importing a private symbol from another module).
       Existing transforms (`appendMessages`, `addMemory`,
       `truncate`, `memorySummaries`) unchanged.
- [x] 3. MUTATIONS — M1 `==` always-true (killed 6/17); M2 `==`
       ignores memories (killed U16); M3 hashCode constant
       (NOT KILLED — contract-permitting mutant, documented in
       `tdd/verification.md`); M4 `toJson` returns `{}` (killed
       U5, U6, U7); M5 `fromJson` always-empty (killed U5); M6
       `truncate` drops memories (killed U8, U9). One at a time,
       `cp`-restored. 5/6 killed; 1 surviving mutant is contract-
       permitting.
- [x] 4. GATES — `dart analyze --fatal-infos` exit 0 on
       `lib/src/llm/agent_message_history.dart` and
       `test/llm/agent_message_history_080_test.dart` ("No issues
       found!"). Full `dart test` green: baseline 1073/2 + 17 new =
       1090/2. Pre-existing analyzer findings on unrelated files
       (1 warning + 2 info at HEAD `29b7fef`) explicitly NOT
       regressed.
- [x] 5. `tdd/verification.md` — verdict PASS_WITH_NOTES, full FR
       coverage table, mutation evidence verbatim (including the
       surviving M3 mutant with explanation), test-first evidence,
       gates, findings, the UserMessage/AssistantMessage identity-
       equality note (U5's structural assertion), and the verdict.
- [x] 6. COMMIT (artifacts + code together) and open PR with base
       `master` titled `feat(080): agent message history — context
       assembly & pure transforms` closing #91.
