## Walkthrough

PR #70 completes the full SDD+TDD cycle for four `zuraffa_agent` value-object specs — **036 SubAgentSpec**, **037 PassAtK**, **038 UiTreePayload**, and **041 AgentMessage / AgentMessageHistory** — adding construction-time validation, hand-curated value equality, precomputed tree metrics, and a path-keyed structural diff. Each spec ships `spec.md`/`plan.md`/`tasks.md` plus a full `tdd/` trail, and every behavior is red–green test-first. The surface is plain-Dart, `build_runner`-free, runtime `dart:io`-free, with tight scope and a disclosed false-green incident (misfire #3) closed by a committed pipefail gate.

### Changes

**Value objects (new behavior)**
|Layer / File(s)|Summary|
|---|---|
|**AgentMessage value equality** <br> `lib/src/domain/entities/agent_message/agent_message.dart`|id/role validation + element-wise deep `parts` equality (`_partsEq`/`_deepEq`) with content hashing — fixes a shipped `List`-identity `==` bug. |
|**PassAtK estimator** <br> `lib/src/domain/entities/pass_at_k/pass_at_k.dart`|`fromResults` (eval-run sampling) + `meetsThreshold` (inclusive, range/NaN-checked) over the unbiased estimator. |
|**SubAgentSpec validation** <br> `lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart`|Non-empty identity fields, non-blank allowlist ids, positive-when-set budgets (`Duration.zero`/`null` sentinels), `extendsSpec == name` 1-cycle rejection. |
|**UiTreePayload + UiTreeDiff** <br> `lib/src/domain/entities/ui_tree_payload/ui_tree_payload.dart`|`ui/tree+json` payload (exact 4-key `toJson`/`fromJson`, mimeType-checked, lossless) + `diff`/`UiTreeDiff` path-keyed structural delta with minimal-anchor semantics. |
|**AgentMessageHistory.truncate** <br> `lib/src/llm/agent_message_history.dart`|`truncate(keep)` — keep-last-N eviction, memories untouched, negative throws, pure. |

**Tests**
|Layer / File(s)|Summary|
|---|---|
|**Spec test suites** <br> `test/domain/entities/.../{agent_message,pass_at_k,sub_agent_spec,ui_tree_payload}/*_test.dart` `test/llm/agent_message_history_041_test.dart`|Five new suites pinning every FR/U with red→green cycles and equality/hash invariants (45 new tests). |

**Spec & skill docs**
|Layer / File(s)|Summary|
|---|---|
|**Spec artifacts + TDD skill docs** <br> `specs/036-041-*` `.agents/skills/speckit-tdd-*/SKILL.md`|Refined spec/plan/tasks + `tdd/` trails; refreshed TDD skill documents. |

**Estimated code review effort:** 3 (Moderate) | ~30 minutes

🐰
> Four little specs in a tidy red–green row,
> each value object tested before it could grow.
> A rabbit reviewed, found the diff sorted right,
> and nibbled one nit in the soft morning light.
