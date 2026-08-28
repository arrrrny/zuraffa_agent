<details>
<summary>📝 Walkthrough</summary>

## Walkthrough

PR #70 completes the full SDD+TDD cycle for four `zuraffa_agent` value-object specs — **036 SubAgentSpec**, **037 PassAtK**, **038 UiTreePayload**, and **041 AgentMessage / AgentMessageHistory** — adding construction-time validation, hand-curated value equality, precomputed tree metrics, and a path-keyed structural diff. Each spec ships its `spec.md`/`plan.md`/`tasks.md` plus a full `tdd/` trail (test-list, cycle-log, verification with mutation evidence), and every behavior is red–green test-first. The production surface is plain-Dart, `build_runner`-free, runtime `dart:io`-free, and the change is remarkable for its discipline: tight scope, characterization pins, and a disclosed false-green incident (misfire #3) with a committed pipefail gate.

### Changes

**Value objects (new behavior)**
|Layer / File(s)|Summary|
|---|---|
|**AgentMessage value equality** <br> `lib/src/domain/entities/agent_message/agent_message.dart`|Adds id/role construction validation and element-wise deep `parts` equality (`_partsEq`/`_deepEq`) with a content-hashing `_deepHash` so field-identical messages with distinct part instances compare and hash equally — fixing a shipped `List`-identity `==` bug. |
|**PassAtK estimator** <br> `lib/src/domain/entities/pass_at_k/pass_at_k.dart`|Adds `fromResults` (eval-run sampling entry point) and `meetsThreshold` (inclusive, range/NaN-checked) over the private unbiased estimator; `binomial` helper retained for the pre-existing provider tests. |
|**SubAgentSpec validation** <br> `lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart`|Adds construction-time validation: non-empty identity fields, non-blank allowlist ids, positive-when-set budgets (with `Duration.zero`/`null` sentinels), and the `extendsSpec == name` 1-cycle rejection. |
|**UiTreePayload + UiTreeDiff** <br> `lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart`|Adds the `ui/tree+json` payload (exact 4-key `toJson`/`fromJson` contract, mimeType-checked, lossless round-trip) plus `diff`/`UiTreeDiff` — a path-keyed, positionally-compared structural delta with minimal-anchor semantics and precomputed depth/nodeCount. |
|**AgentMessageHistory.truncate** <br> `lib/src/llm/agent_message_history.dart`|Adds `truncate(keep)` — keep-last-N active-message eviction (memories untouched, negative throws, pure). |

**Tests**
|Layer / File(s)|Summary|
|---|---|
|**Spec test suites** <br> `test/domain/entities/agent_message/agent_message_test.dart` `test/domain/entities/pass_at_k/pass_at_k_test.dart` `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` `test/domain/entities/ui_tree_payload/ui_tree_payload_test.dart` `test/llm/agent_message_history_041_test.dart`|Five new suites pinning every FR/U with red→green cycles, boundary conditions, and equality/hash invariants (45 new tests). |

**Spec & skill documentation**
|Layer / File(s)|Summary|
|---|---|
|**Spec artifacts** <br> `specs/036-*` `specs/037-*` `specs/038-*` `specs/041-*`|Refined spec/plan/tasks and full `tdd/` trails (test-list, cycle-log, verification) per spec. |
|**TDD skill docs** <br> `.agents/skills/speckit-tdd-*/SKILL.md`|Refreshed the four TDD sub-skill documents. |

**Estimated code review effort:** 3 (Moderate) | ~30 minutes

</details>

<details>
<summary>🚥 Pre-merge checks | ✅ 5 / ❌ 0</summary>

| Check name | Status | Explanation |
| :--------: | :----- | :---------- |
| Description Check | ✅ Passed | Body is detailed and verbatim on scope, verification numbers, and disclosed incidents. |
| Title check | ✅ Passed | Title succinctly names the four specs and their themes. |
| Docstring Coverage | ✅ Passed | Every new public type/member carries doc comments and FR references. |
| Linked Issues check | ✅ Passed | Each spec names its upstream issue (`#3`, `#6`, `#7`, `#8`). |
| Out of Scope Changes check | ✅ Passed | Changes are confined to the four specs, their tests, and the TDD skill docs. |

</details>

🐰
> Four little specs in a tidy red–green row,
> each value object tested before it could grow.
> A rabbit reviewed, found the diff sorted right,
> and nibbled one nit in the soft morning light.

---

**Actionable comments posted: 1**

<details>
<summary>🧹 Nitpick comments (2)</summary>
<blockquote>

<details>
<summary>lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart (1)</summary>
<blockquote>

`304-306`: _📐 Maintainability_ | _🔵 Trivial_ | _⚡_

**`hashCode` omits `tree`, trading hash quality for simplicity.**

Equality still deep-compares `tree` via `_mapEq`, so the `==`/`hashCode` contract holds (unequal trees can share a hash — allowed), but two trees with identical `(vocabularyId, schemaVersion, depth, nodeCount)` yet different shapes collide in hash-based collections. The inline comment documents the tradeoff, so this is deliberate; flag it only so future consumers don't assume `Set`/`Map` membership is shape-sensitive.

</blockquote></details>

<details>
<summary>lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart (1)</summary>
<blockquote>

`108-117`: _📐 Maintainability_ | _🔵 Trivial_ | _⚡_

**Empty `vocabularyId`/`schemaVersion` validation is enforced downstream, not at the `is! String` guard.**

`fromJson` only checks `parsedVocab is! String` (and likewise for schema); an empty *string* slips past the guard and is rejected only by the `UiTreePayload(...)` constructor. Behavior is correct — the thrown `ArgumentError` still names `vocabularyId`/`schemaVersion` — but the "empty pinning fields throw" contract is enforced in two places. Minor; optionally tighten the guard to `parsedVocab is! String || parsedVocab.isEmpty` for locality.

</blockquote></details>

</blockquote></details>

<details>
<summary>🤖 Prompt for all review comments with AI agents</summary>

```
Verify each finding against current code. Fix only still-valid issues, skip the
rest with a brief reason, keep changes minimal, and validate.

Inline comments:
In `@lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart`:
- Around line 134-146 (`diff`): sort `added`, `removed`, and `changed` before
  constructing `UiTreeDiff` so the path lists are lexically ordered — matching
  the documented "sorted lexically for deterministic reporting/replay
  artifacts" contract. Preserve `_diffNodes` traversal semantics.

Nitpick comments:
In `@lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart`:
- Line 304-306: no change needed; the `hashCode`-excludes-tree tradeoff is
  intentional and documented.
- Line 108-117: optional — tighten `fromJson` guards to also reject empty
  strings locally; current behavior is already correct via the constructor.
```

</details>

---

_<📐 Maintainability>_ | _<🟡 Minor>_ | _<⚡ Quick win>_

**Sort the `UiTreeDiff` path lists so `diff()` honors its documented "sorted lexically" contract.**

`UiTreePayload.diff()` builds `added`/`removed`/`changed` via the positional `_diffNodes` traversal and hands them to `UiTreeDiff` as-is, so the lists come back in traversal order — not lexically sorted. Yet `ui_tree_payload_test.dart` (U10) and the `UiTreeDiff` comments state the lists are *"Sorted lexically for deterministic reporting/replay artifacts."* With multi-digit child indices the two orders diverge (e.g. `root/2` before `root/10` in traversal vs. `root/10` before `root/2` lexically), so any consumer building stable replay/diff artifacts from these lists gets non-sorted output. The U10 assertion is also vacuous today: it passes `['root/10','root/2']` (already in lexical order) and compares order-sensitively, so it never actually exercises sorting.

Lines 134-146: `diff()` returns immediately after `_diffNodes(...)` without ordering the three lists.

<details>
<summary>Proposed fix</summary>

```diff
     final added = <String>[];
     final removed = <String>[];
     final changed = <String>[];
     _diffNodes('root', tree, other.tree, added, removed, changed);
+    // Emit lexically-sorted path lists so diffs are deterministic and stable
+    // for replay artifacts (per the UiTreePayload/UiTreeDiff contract),
+    // independent of _diffNodes' positional traversal order.
+    added.sort();
+    removed.sort();
+    changed.sort();
     return UiTreeDiff(
       addedPaths: added,
       removedPaths: removed,
       changedPaths: changed,
       vocabularyChanged: vocabularyId != other.vocabularyId,
       schemaChanged: schemaVersion != other.schemaVersion,
     );
```

</details>

<!-- suggestion_start -->

<details>
<summary>📝 Committable suggestion</summary>

> ‼️ **IMPORTANT**
> Carefully review the code before committing. Ensure it accurately replaces the highlighted code, contains no missing lines, and has no issues with indentation. Thoroughly test & benchmark the code to ensure it meets the requirements.

```suggestion
  UiTreeDiff diff(UiTreePayload other) {
    final added = <String>[];
    final removed = <String>[];
    final changed = <String>[];
    _diffNodes('root', tree, other.tree, added, removed, changed);
    // Emit lexically-sorted path lists so diffs are deterministic and stable
    // for replay artifacts (per the UiTreePayload/UiTreeDiff contract),
    // independent of _diffNodes' positional traversal order.
    added.sort();
    removed.sort();
    changed.sort();
    return UiTreeDiff(
      addedPaths: added,
      removedPaths: removed,
      changedPaths: changed,
      vocabularyChanged: vocabularyId != other.vocabularyId,
      schemaChanged: schemaVersion != other.schemaVersion,
    );
  }
```

</details>

<!-- suggestion_end -->

<details>
<summary>🤖 Prompt for AI Agents</summary>

```
Verify each finding against current code. Fix only still-valid issues, skip the
rest with a brief reason, keep changes minimal, and validate.

In `@lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart` around lines
134 - 146, the `diff` method returns the three path lists in `_diffNodes`
traversal order, but the contract (and `ui_tree_payload_test.dart` U10) expects
them lexically sorted for deterministic replay artifacts. Sort `added`,
`removed`, and `changed` (`List.sort()` on each) right after the `_diffNodes`
call and before constructing `UiTreeDiff`. Preserve the existing `_diffNodes`
walk and the `vocabularyChanged`/`schemaChanged` flags. Re-run
`dart test test/domain/entities/ui_tree_payload/ui_tree_payload_test.dart` to
confirm U3/U4/U10 stay green.
```

</details>
